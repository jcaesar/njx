#!/usr/bin/env python3

import os
import paramiko
from multiprocessing.pool import ThreadPool
from collections import defaultdict, deque
from tqdm import tqdm
import random
import subprocess
import json
import rustworkx as rx
import sys
import threading
import time
pool = ThreadPool()

remote = sys.argv[1:]
def open_ssh(host):
    config = paramiko.SSHConfig \
        .from_path(os.path.expanduser('~/.ssh/config')) \
        .lookup(host)
    config['compress'] = True
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname = config['hostname'],
        port = config['port'],
        username = config['user'],
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

roots = ["/run/current-system", "/run/booted-system"]
def gather(h):
    if h == "local":
        ft = os
        conn = None
    else:
        conn = pooled_conn(h)
        ft = conn.open_sftp()
    ret = {
        "host": h,
        "roots": [ft.readlink(k) for k in roots],
        "files": ft.listdir("/nix/store"),
    }
    pool_conn(h, conn)
    return ret
ondisk = list(tqdm(pool.imap(gather, ["local"] + remote), total=1 + len(remote), unit="host", desc="ls /nix/store"))

showpossible = defaultdict(lambda: []) # where derivations are available
for g in ondisk:
    host = g["host"]
    for f in g["files"]:
        if f.endswith(".drv"):
            showpossible[f] += [host]
def selhost(hs):
    if "local" in hs:
        return "local"
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
    cmd = ["nix", "derivation", "show"]
    args = [f"/nix/store/{d}^*" for d in c]
    tries = 0
    while True:
        tries += 1
        try:
            try:
                if h == "local":
                    ex = cmd + args
                    out = subprocess.check_output(ex, stderr=subprocess.STDOUT)
                    conn = None
                else:
                    ex = " ".join(cmd) + " '" + "' '".join(args) + "'"
                    conn = pooled_conn(h)
                    out = ssh_exec_out(conn, ex)
            except Exception as e:
                raise Exception(f"Failed to execute on {h}: {ex}")
            try:
                ret = json.loads(out)
            except Exception as e:
                trunc = out[:100] + " … " + out[-100:] if len(out) > 200 else out
                raise Exception(f"Failed to decode out of {h} executing {ex}: {trunc}")
            for d in c:
                if f"/nix/store/{d}" not in ret:
                    raise Exception(f"{d} not in show output of {h}")
            pool_conn(h, conn)
            return ret
        except:
            if tries > 3:
                raise
            time.sleep(3)
random.shuffle(showtasks)
shown = {k: v for c in tqdm(pool.imap(showdrv, showtasks), total=len(showtasks), unit="exec", desc="nix derivation show …") for k, v in c.items()}

g = rx.PyDiGraph(check_cycle=True)
drvnodes = {}
def drvnode(k):
    if (n := drvnodes.get(k)) is not None:
        return n
    n = g.add_node(k)
    drvnodes[k] = n
    return n
hostroots = {x["host"]: g.add_node("[{}]".format(x["host"])) for x in ondisk}
addroots = {l: hostroots[x["host"]] for x in ondisk for l in x["roots"]}
for k, v in tqdm(shown.items(), desc="[graph building]"):
    kn = drvnode(k)
    for inp in v["inputDrvs"].keys():
        g.add_edge(kn, drvnode(inp), ())
    for out in v["outputs"].values():
        if (root := addroots.pop(out["path"], None)) is not None:
            g.add_edge(root, kn, ())
if len(addroots) != 0:
    print("Not all roots were found as derivation outputs. Missing:", list(addroots.keys()), file = sys.stderr)

installed = []
for x in ondisk:
    exists = set("/nix/store/" + f for f in x["files"])
    host = x["host"]
    root = hostroots[host]
    for _,l in rx.dfs_edges(g, root):
        info = shown[g[l]]
        if (ver := info["env"].get("version")) is None:
            continue
        if (name := info["env"].get("pname")) is None:
            continue
        if not any(out["path"] in exists for out in info["outputs"].values()):
            continue
        installed += [{
            "name": name,
            "version": ver,
            "host": host,
        }]
print("Dumping install information ({} entries)".format(len(installed)), file = sys.stderr)
json.dump(installed, sys.stdout) 

def main():
    pass
