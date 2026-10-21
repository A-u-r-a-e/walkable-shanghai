#!/usr/bin/env python3
"""Add, replace or remove keys in Localizable.xcstrings.

    python3 Scripts/strings.py set KEY "English" "中文" ["comment"]
    python3 Scripts/strings.py plural KEY "one English" "other English" "中文"
    python3 Scripts/strings.py remove PREFIX_OR_KEY [...]
"""
import json, sys
PATH = "Sources/Resources/Localizable.xcstrings"

def unit(value):
    return {"stringUnit": {"state": "translated", "value": value}}

def main():
    with open(PATH, encoding="utf-8") as f:
        catalog = json.load(f)
    strings = catalog["strings"]
    command, args = sys.argv[1], sys.argv[2:]
    if command == "set":
        key, en, zh = args[:3]
        entry = {"extractionState": "manual", "localizations": {"en": unit(en), "zh-Hans": unit(zh)}}
        if len(args) > 3:
            entry["comment"] = args[3]
        strings[key] = entry
    elif command == "plural":
        key, one, other, zh = args
        strings[key] = {"extractionState": "manual", "localizations": {
            "en": {"variations": {"plural": {"one": unit(one), "other": unit(other)}}},
            "zh-Hans": {"variations": {"plural": {"other": unit(zh)}}},
        }}
    elif command == "remove":
        for target in args:
            for key in [k for k in strings if k == target or (target.endswith(".") and k.startswith(target))]:
                del strings[key]
    else:
        sys.exit(f"unknown command {command}")
    with open(PATH, "w", encoding="utf-8") as f:
        json.dump(catalog, f, ensure_ascii=False, indent=2, sort_keys=True)
        f.write("\n")

main()
