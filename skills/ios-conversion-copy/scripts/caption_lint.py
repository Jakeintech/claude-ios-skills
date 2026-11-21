#!/usr/bin/env python3
"""Lint App Store screenshot captions (or any short store copy) before a person or a
panel ever sees them. Catches the mechanical failures; the panel loop judges the rest.

Usage:
  python3 caption_lint.py captions.json

captions.json:
{
  "keywords": ["track", "workout", "progress", "pr", "lift"],   # the phrase bank's search words
  "jargon":   ["fitness", "healthkit", "e1rm", "training partner"],  # internal names users don't search for
  "verbs":    ["log", "lift", "add", "beat", "know", "see", "track", "hit", "plan", "switch"],  # the user's action verbs
  "captions": ["Log every set in one tap", "Counts in Fitness, too"]
}

Rules (each failure is printed; exit 1 if any caption fails):
- 2 to 7 words, at most 32 characters per caption (readable at thumbnail size);
- starts with an action verb from `verbs`, or contains a number or "you"/"your" (an
  outcome the reader owns) — noun phrases that only name a feature fail;
- no word from `jargon` (internal feature names, partner brand names);
- at least half of all captions contain a word from `keywords` (the user's search words);
- no two captions start with the same word;
- no hype words ("ultimate", "revolutionary", "best", "amazing", "crush", "smart").
"""
import json
import re
import sys

HYPE = {"ultimate", "revolutionary", "best", "amazing", "crush", "crushed", "smart", "powerful", "seamless", "effortless"}


def words(text):
    return re.findall(r"[a-z0-9']+", text.lower())


def main():
    spec = json.load(open(sys.argv[1]))
    keywords = {k.lower() for k in spec.get("keywords", [])}
    jargon = [j.lower() for j in spec.get("jargon", [])]
    verbs = {v.lower() for v in spec.get("verbs", [])}
    captions = spec["captions"]

    failures = 0
    starts = {}
    keyword_hits = 0
    for caption in captions:
        problems = []
        w = words(caption)
        if not 2 <= len(w) <= 7:
            problems.append(f"{len(w)} words (2–7)")
        if len(caption) > 32:
            problems.append(f"{len(caption)} characters (≤ 32)")
        owns_outcome = any(ch.isdigit() for ch in caption) or bool({"you", "your", "you're"} & set(w))
        if not (w and w[0] in verbs) and not owns_outcome:
            problems.append("no action verb first and no outcome the reader owns (names a feature?)")
        lowered = caption.lower()
        hits = [j for j in jargon if j in lowered]
        if hits:
            problems.append(f"jargon: {', '.join(hits)}")
        hype = HYPE & set(w)
        if hype:
            problems.append(f"hype: {', '.join(sorted(hype))}")
        if keywords & set(w):
            keyword_hits += 1
        if w:
            starts.setdefault(w[0], []).append(caption)
        status = "FAIL" if problems else "ok  "
        failures += bool(problems)
        print(f"{status} {caption}" + (f"  ← {'; '.join(problems)}" if problems else ""))

    for first, group in starts.items():
        if len(group) > 1:
            print(f"FAIL {len(group)} captions start with \"{first}\": {group}")
            failures += 1
    if captions and keyword_hits * 2 < len(captions):
        print(f"FAIL only {keyword_hits} of {len(captions)} captions use a search word from the phrase bank")
        failures += 1
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
