import os
import paramiko
from multiprocessing.pool import ThreadPool
from collections import defaultdict
from tqdm import tqdm
import random
import subprocess
import json
import rustworkx as rx
import sys
pool = ThreadPool()

remote = sys.argv[1:]
if len(remote) > 0:
    print("Establishing ssh connection to remote servers ({})".format(" ".join(remote)), file = sys.stderr)
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
ssh = {h: open_ssh(h) for h in remote}

roots = ["/run/current-system", "/run/booted-system"]
gathertasks = \
    [(h, c.open_sftp()) for h, c in ssh.items()] + \
    [("local", os)]
def gather(t):
    (h, ft) = t
    return {
        "host": h,
        "roots": [ft.readlink(k) for k in roots],
        "files": ft.listdir("/nix/store"),
    }
print("Gathering store content (on {} hosts)".format(len(gathertasks)), file = sys.stderr)
ondisk = list(tqdm(pool.imap(gather, gathertasks), total=len(gathertasks)))

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
    if len(showchunk[on][-1]) < 234:
        showchunk[on][-1] += [drv]
    else:
        showchunk[on] += [[drv]]
showtasks = [(h, c) for h,cs in showchunk.items() for c in cs]
def showdrv(t):
    (h, c) = t
    cmd = ["nix", "derivation", "show"] + [f"/nix/store/{d}^*" for d in c]
    if h == "local":
        out = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
    else:
        stdin, stdout, stderr = ssh[h].exec_command(" ".join(cmd))
        stdout.channel.set_combine_stderr(True)
        stdin.channel.shutdown_write()
        out = stdout.read()
    return json.loads(out)
random.shuffle(showtasks)
print("Reading derivations ({} chunks nix derivation show)".format(len(showtasks)), file = sys.stderr)
shown = {k: v for c in tqdm(pool.imap(showdrv, showtasks), total=len(showtasks)) for k, v in c.items()}

print("Mangling dependency graph ({} items)".format(len(shown)), file = sys.stderr)
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
for k, v in tqdm(shown.items()):
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
