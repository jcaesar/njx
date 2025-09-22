#!/usr/bin/env python3

import os
import sys
import re
import subprocess
profile_regex = re.compile("^system-(?P<gen>[0-9]+)-link$")
profiledir = "/nix/var/nix/profiles/"

delete_generations = False
keep_only_bootcurrent = False
update_bootloader = False
run_gc = False

# y i no argparse…
for arg in sys.argv[1:]:
    match arg:
        case "gc":
            run_gc = True
        case "del":
            delete_generations = True
        case "boot":
            update_bootloader = True
        case "max":
            keep_only_bootcurrent = True
        case _:
            print("Unknown arg " + arg)
            sys.exit(2)

roots = [
    {"link": "/run/current-system", "name": "current"},
    {"link": "/run/booted-system", "name": "booted"},
]
for r in roots:
    r["target"] = os.readlink(r["link"])

profiles = []
for p in os.listdir(profiledir):
    m = profile_regex.match(p)
    if m is not None:
        link = profiledir + p
        profiles += [{
            "link": link,
            "profile": int(m.groupdict()["gen"]),
            "target": os.readlink(link),
        }]
profiles = sorted(profiles, key = lambda p: p["profile"])

for r in roots:
    profile = [p for p in profiles if p["target"] == r["target"]]
    if len(profile) != 1:
        print(f"System profile for {r['link']} not found, bailing")
        sys.exit(-1)
    r["profile"] = profile[0]["profile"]
    profile[0]["root"] = [r["name"]] + profile[0].get("root", [])

def kept_name(p):
    if "root" in p:
        return f"{p['profile']} ({', '.join(p['root'])})"
    else:
        return f"{p['profile']}"
if keep_only_bootcurrent:
    to_be_kept = [kept_name(p) for p in roots]
    to_be_deleted = [str(p["profile"]) for p in profiles if p["profile"] not in keep_indexes]
else:
    delete_before = min(r["profile"] for r in roots)
    to_be_deleted = [str(p["profile"]) for p in profiles if p["profile"] < delete_before]
    to_be_kept = [kept_name(p) for p in profiles if p["profile"] >= delete_before]

print("To be deleted:", ", ".join(to_be_deleted))
print("To be kept:", ", ".join(to_be_kept))

if delete_generations:
    subprocess.run(["nix-env", "--delete-generations", "--profile", profiledir + "system"] + to_be_deleted).check_returncode()
if update_bootloader:
    subprocess.run([profiledir + "system/bin/switch-to-configuration", "boot"]).check_returncode()
if run_gc:
    subprocess.run(["nix-store", "--gc"]).check_returncode()

def main():
    pass
