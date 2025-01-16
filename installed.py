#!/usr/bin/env python3

import os
import paramiko
from multiprocessing.pool import ThreadPool
from collections import defaultdict, deque
from tqdm import tqdm
from json import JSONDecoder
import json
import random
import subprocess
import rustworkx as rx
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

def ssh_exec_out(conn, cmd):
    stdin, stdout, stderr = conn.exec_command(cmd)
    stdout.channel.set_combine_stderr(True)
    stdin.channel.shutdown_write()
    return stdout.read()
def keepalive():
    next = time.monotonic()
    while True:
        for _, c in ssh.items():
            ssh_exec_out(c, "true")
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
                    out = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
                    conn = None
                else:
                    conn = pooled_conn(h)
                    out = ssh_exec_out(conn, ex)
            except Exception as e:
                raise Exception(f"Failed to execute on {h}: {ex}")
            try:
                if type(out) == bytes:
                    out = out.decode("utf-8")
                ret = f(out)
            except Exception as e:
                trunc = out[:100] + " … " + out[-100:] if len(out) > 200 else out
                raise Exception(f"Failed to decode out of {h} executing {ex}: {trunc}")
            pool_conn(h, conn)
            return ret
        except:
            if tries > 3:
                raise
            time.sleep(3)

def single(iterable):
    iter_obj = iter(iterable)
    try:
        first_item = next(iter_obj)
    except StopIteration:
        raise ValueError("Iterator is empty")

    try:
        second_item = next(iter_obj)
    except StopIteration:
        return first_item
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
ondisk = list(tqdm(pool.imap(gather, set([local] + remote)), total=1 + len(remote), unit="host", desc="gc roots, ls /nix/store"))

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
    shown = {k: v for c in tqdm(pool.imap(showdrv, showtasks), total=len(showtasks), unit="exec", desc=" ".join(cmd) + " …") for k, v in c.items()}
    return shown

path_info = exec_where_avail(["nix", "path-info", "--recursive", "--json"], [p for h in ondisk for p in h["roots"]])
no_deriver = {k for k,v in path_info.items() if v.get("deriver", "") == ""}
if no_deriver != set():
    print("No deriver: " + " ".join(no_deriver), file = sys.stderr)
derivers = {v["deriver"] for v in path_info.values() if v.get("deriver", "") != ""}
derivations = exec_where_avail(["nix", "derivation", "show"], derivers)

g = rx.PyDiGraph(check_cycle=True)
drvnodes = {}
def drvnode(k):
    if (n := drvnodes.get(k)) is not None:
        return n
    n = g.add_node(k)
    drvnodes[k] = n
    return n
for k, v in path_info.items():
    kn = drvnode(k)
    for ref in v["references"]:
        if k != ref:
            g.add_edge(kn, drvnode(ref), ())

installed = set()
for x in ondisk:
    host = x["host"]
    root = g.add_node(f"[{host}]")
    for f in x["roots"]:
        g.add_edge(root, drvnode(f), ())
    for _,l in rx.dfs_edges(g, root):
        info = path_info[g[l]]
        drv = derivations.get(info.get("deriver", None), None)
        if drv is None:
            continue
        FW = "linux-firmware-" # special casing for this. there's probably a few others, but this one seems most important
        if (name := drv["env"].get("pname")) is not None and (ver := drv["env"].get("version")) is not None:
            installed |= {(name, ver, host)}
        elif (name := drv["env"].get("name", "")).startswith(FW):
            installed |= {(FW[:-1], name[len(FW):], host)}

installed = [{"name": n, "version": ver, "host": h} for n, ver, h in sorted(installed)]
print("Dumping install information ({} entries)".format(len(installed)), file = sys.stderr)
json.dump(installed, sys.stdout)

def main():
    pass
