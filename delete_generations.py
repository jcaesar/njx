#!/usr/bin/env python3

import os
import sys
import re
import subprocess
profile_regex = re.compile("^system-(?P<gen>[0-9]+)-link$")
profiledir = "/nix/var/nix/profiles/"

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

delete_before = min(r["profile"] for r in roots)
to_be_deleted = [str(p["profile"]) for p in profiles if p["profile"] < delete_before]

def kept_name(p):
    if "root" in p:
        return f"{p['profile']} ({', '.join(p['root'])})"
    else:
        return f"{p['profile']}"
to_be_kept = [kept_name(p) for p in profiles if p["profile"] >= delete_before]
print("To be deleted:", ", ".join(to_be_deleted))
print("To be kept:", ", ".join(to_be_kept))

if len(sys.argv) == 2 and sys.argv[1] == "fmuf" and len(to_be_deleted) > 0:
    subprocess.run(["nix-env", "--delete-generations", "--profile", profiledir + "system"] + to_be_deleted)

def main():
    pass
