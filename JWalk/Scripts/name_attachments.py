#!/usr/bin/env python3
"""Rename attachments exported by `xcresulttool export attachments` from
their UUIDs to the names the tests gave them, and drop the manifest.

    python3 Scripts/name_attachments.py Screenshots/neutral/light
"""
import json, os, sys

folder = sys.argv[1]
manifest = os.path.join(folder, "manifest.json")
for test in json.load(open(manifest, encoding="utf-8")):
    for item in test["attachments"]:
        name = item["suggestedHumanReadableName"].rsplit("_0_", 1)[0] + ".png"
        os.rename(os.path.join(folder, item["exportedFileName"]), os.path.join(folder, name))
os.remove(manifest)
