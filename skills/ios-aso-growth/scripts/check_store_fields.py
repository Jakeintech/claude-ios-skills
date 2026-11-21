#!/usr/bin/env python3
"""Check App Store fields against Apple's limits and the keyword rules.

Usage:
  python3 check_store_fields.py appstore/listing.json [--name NAME] [--subtitle SUBTITLE]
      [--banned word,word,...]

Reads keys name/subtitle/keywords/promotionalText/description/whatsNew from the JSON
(app-info.json's name/subtitle can be passed with --name/--subtitle). Exits 1 on any
failure. Rules:
- lengths: name 30, subtitle 30, keywords 100, promotional text 170, description and
  What's New 4000;
- keywords: comma-separated, no spaces after commas, no duplicates, no word already in the
  name or subtitle (Apple indexes those), none of the banned words (competitor apps and
  trademarks, Guideline 2.3.7).
"""
import argparse
import json
import re
import sys

LIMITS = {"name": 30, "subtitle": 30, "keywords": 100, "promotionalText": 170,
          "description": 4000, "whatsNew": 4000}


def words(text):
    return {w for w in re.split(r"[^a-z0-9]+", (text or "").lower()) if w}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("listing")
    parser.add_argument("--name")
    parser.add_argument("--subtitle")
    parser.add_argument("--banned", default="")
    args = parser.parse_args()

    data = json.load(open(args.listing))
    if args.name:
        data["name"] = args.name
    if args.subtitle:
        data["subtitle"] = args.subtitle

    failures = []
    for key, limit in LIMITS.items():
        value = data.get(key)
        if value is None:
            continue
        status = "OK " if len(value) <= limit else "OVER"
        print(f"{status} {key}: {len(value)}/{limit}")
        if len(value) > limit:
            failures.append(f"{key} is {len(value)} characters (limit {limit})")

    keywords = data.get("keywords") or ""
    if keywords:
        if ", " in keywords:
            failures.append("keywords have spaces after commas (wasted characters)")
        items = [k.strip().lower() for k in keywords.split(",") if k.strip()]
        if len(items) != len(set(items)):
            failures.append("keywords repeat an entry")
        taken = words(data.get("name")) | words(data.get("subtitle"))
        repeated = sorted(w for k in items for w in words(k) if w in taken)
        if repeated:
            failures.append(f"keywords repeat words from the name/subtitle: {', '.join(repeated)}")
        banned = {b.strip().lower() for b in args.banned.split(",") if b.strip()}
        hits = sorted(k for k in items if k in banned or words(k) & banned)
        if hits:
            failures.append(f"keywords use banned (competitor/trademark) terms: {', '.join(hits)}")

    for failure in failures:
        print("FAIL", failure)
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
