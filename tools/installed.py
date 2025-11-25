#!/usr/bin/env python3

import os
import paramiko
from multiprocessing.pool import ThreadPool
from collections import defaultdict, deque
from json import JSONDecoder
import json
import random
import subprocess
import sys
import threading
import time
import getpass
import socket
pool = ThreadPool()
local = socket.gethostname()

remote = sys.argv[1:]
def open_ssh(host):
    config = paramiko.SSHConfig \
        .from_path(os.path.expanduser('~/.ssh/config')) \
        .lookup(host)
    config['compress'] = True
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname = config['hostname'].replace("%%", "%"),
        port = config.get('port', 22),
        username = config.get('user', getpass.getuser()),
    )
    return client

conn_pool = defaultdict(deque)
def pooled_conn(h):
    if len(conn_pool[h]) == 0:
        return open_ssh(h)
    else:
        return conn_pool[h].popleft()
def pool_conn(h, conn):
    if conn is not None:
        conn_pool[h].append(conn)

def ssh_exec_out(conn, cmd, host):
    try:
        stdin, stdout, stderr = conn.exec_command(cmd)
        stdout.channel.set_combine_stderr(True)
        stdin.channel.shutdown_write()
        return stdout.read()
    except Exception:
        raise Exception(f"Error executing on {host}")
def keepalive():
    next = time.monotonic()
    while True:
        for h, c in conn_pool.items():
            ssh_exec_out(c, "true", h)
        next += 29
        time.sleep(max(10, next - time.monotonic()))

threading.Thread(target=keepalive)

def decode_stacked(document):
    pos = 0
    decoder = JSONDecoder()
    while pos < len(document):
        if document[pos].isspace():
            pos += 1
            continue
        obj, pos = decoder.raw_decode(document, pos)
        yield obj

# no command line escaping whatsoever :(
def exec_decode(h, cmd, f):
    tries = 0
    while True:
        tries += 1
        try:
            try:
                ex = " ".join(cmd)
                if h == local:
                    out = subprocess.check_output(cmd)
                    conn = None
                else:
                    conn = pooled_conn(h)
                    out = ssh_exec_out(conn, ex, h)
            except Exception:
                raise Exception(f"Failed to execute on {h}: {ex}")
            try:
                if isinstance(out, bytes):
                    out = out.decode("utf-8")
                ret = f(out)
            except Exception:
                trunc = out[:100] + " … " + out[-100:] if len(out) > 200 else out
                raise Exception(f"Failed to decode out of {h} executing {ex}: {trunc}")
            pool_conn(h, conn)
            return ret
        except Exception:
            if tries > 3:
                raise
            time.sleep(3)

def single(iterable):
    iterator = iter(iterable)
    try:
        one = next(iterator)
    except StopIteration:
        raise ValueError("Iterator is empty")
    try:
        next(iterator)
    except StopIteration:
        return one
    else:
        raise ValueError("Iterator contains more than one item")

def gather(h):
    def decode(out):
        def nope(x):
            if x == "":
                return False
            # # really only want the running one - no idea how to do that with user profiles
            # if x.startswith("/nix/var/nix/profiles/system-"):
            #     return False
            # if "/.local/state/nix/profiles/" in x:
            #     if "/gcroots/current-home" not in x:
            #         return False
            # if x.startswith("/run/booted-system -> /"):
            #     return False
            return True
        return list(filter(nope, (x.split(" ")[-1] for x in out.split("\n"))))
    if h == local:
        ft = os
        conn = None
    else:
        conn = pooled_conn(h)
        ft = conn.open_sftp()
    ret = {
        "host": h,
        "roots": exec_decode(h, ["nix-store", "--gc", "--print-roots"], decode),
        "files": set(f"/nix/store/{p}" for p in ft.listdir("/nix/store")),
    }
    pool_conn(h, conn)
    return ret
ondisk = list(pool.imap(gather, set([local] + remote)))

def exec_where_avail(cmd, targets):
    showpossible = defaultdict(lambda: []) # where derivations are available
    for t in targets:
        for g in ondisk:
            host = g["host"]
            if t in g["files"]:
                showpossible[t] += [host]
    def selhost(hs):
        if local in hs:
            return local
        else:
            return random.choice(hs)
    showon = {f: selhost(hs) for f, hs in showpossible.items()} # where to execute nix derivation show $drv
    showchunk = defaultdict(lambda: [[]]) # chunked multiple derivations so we don't invoke nix derviation show 100k times
    for drv, on in showon.items():
        if len(showchunk[on][-1]) < 89:
            showchunk[on][-1] += [drv]
        else:
            showchunk[on] += [[drv]]
    showtasks = [(h, c) for h, cs in showchunk.items() for c in cs]
    def showdrv(t):
        (h, c) = t
        def decode(out):
            ret = single(decode_stacked(out))
            for d in c:
                if d not in ret:
                    raise Exception(f"{d} not in show output of {h}")
            return ret
        return exec_decode(h, cmd + c, decode)
    random.shuffle(showtasks)
    shown = {k: v for c in pool.imap(showdrv, showtasks) for k, v in c.items()}
    return shown

path_info = exec_where_avail(["nix", "--extra-experimental-features", "nix-command", "path-info", "--recursive", "--json"], [p for h in ondisk for p in h["roots"]])
no_deriver = {k for k,v in path_info.items() if v.get("deriver", "") == ""}
if no_deriver != set():
    print("No deriver: " + " ".join(no_deriver), file = sys.stderr)
derivers = {v["deriver"] for v in path_info.values() if v.get("deriver", "") != ""}
derivations = exec_where_avail(["nix", "--extra-experimental-features", "nix-command", "derivation", "show"], derivers)

g = defaultdict(lambda: set())
for k, v in path_info.items():
    for ref in v["references"]:
        if k != ref:
            g[k] |= {ref}

installed = set()
no_info = set()
no_deriver = set()
no_derivation = set()
no_pv = set()

def drv_starts(s, sta):
    return s.startswith("/nix/store/") and s[len("/nix/store/lw3najqhgyfrv58lc48c9072ayqxipvx-"):].startswith(sta)

for x in ondisk:
    host = x["host"]
    g_todo = set(x["roots"])
    while len(g_todo) > 0:
        ll = g_todo.pop()
        g_todo |= g[ll]
        info = path_info.get(ll, None)
        if info is None:
            no_info |= {ll}
            continue
        drvr = info.get("deriver", None)
        if drvr is None:
            if not ll.endswith(".drv"):
                no_deriver |= {ll}
        drv = derivations.get(drvr, None)
        if drv is None:
            no_derivation |= {drvr}
            continue
        if jsonattrs := drv["env"].get("__json"):
            drv["env"] |= json.loads(jsonattrs)
        name = drv["env"].get("pname")
        ver = drv["env"].get("version")
        pv_ignore_prefixes = [
            "unit-",
            "X-Restart-Triggers-",
            "X-Reload-Triggers-",
            "hm_",
        ]
        pv_ignore_suffixes = [
            ".pam.drv",
            ".conf.drv",
            ".sh.drv",
            ".toml.drv",
            "-path.drv",
            "-nixos-help.drv",
            "-env.drv",
            "-environment.drv",
            "-etc.drv",
        ]
        if name is None or ver is None:
            if any(drv_starts(drvr, pfx) for pfx in pv_ignore_prefixes):
                pass
            elif any(drvr.endswith(sfx) for sfx in pv_ignore_suffixes):
                pass
            else:
                no_pv |= {drvr}
            continue
        installed |= {(name, ver, host)}

installed = [{"name": n, "version": ver, "host": h} for n, ver, h in sorted(installed)]
eee = {
    "No install info (shouldn't happen?)": no_info,
    "No deriver": no_deriver,
    "Derivation file not found": no_derivation,
    "No pname/version": no_pv,
}
for e, ee in eee.items():
    if len(ee) > 0:
        print(f"{e}:\n {"\n ".join(map(str, ee))}", file = sys.stderr)
print(f"Dumping install information ({len(installed)} entries)", file = sys.stderr)
json.dump(installed, sys.stdout)

def main():
    pass
