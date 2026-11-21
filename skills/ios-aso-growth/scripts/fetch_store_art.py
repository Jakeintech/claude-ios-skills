#!/usr/bin/env python3
"""Save competitors' App Store screenshots and build a side-by-side contact sheet.

For an internal teardown only: the images belong to their owners, so keep them out of
git and out of anything public.

Usage:
  python3 fetch_store_art.py OUT_DIR "hevy=1458862350" "strong=464254577" "fitbod" ...
      [--country us] [--frames 6] [--ours "Reps=6762486117"] [--ours-dir path/to/our/frames]

Each argument is `slug=appID`, or a search term (the top Health & Fitness match is used).
Needs network access to itunes.apple.com and is1-5-ssl.mzstatic.com.

Writes:
  OUT_DIR/<slug>/1.png … N.png     the first N iPhone screenshots
  OUT_DIR/summary.json             name, seller, rating, count, price, url, description
                                   opening, frame files (captions are filled in by the
                                   reviewer, who reads the images)
  OUT_DIR/contact-sheet.html       one row per app, ours first, frames at thumbnail size
                                   (the size people judge them at in search results)
"""
import argparse
import html
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

UA = {"User-Agent": "store-art-teardown/1.0"}


def get_json(url, attempts=4):
    """Apple's search API rate-limits bursts with 403/429: back off and retry."""
    import time
    for attempt in range(attempts):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=30) as r:
                return json.load(r)
        except urllib.error.HTTPError as error:
            if error.code not in (403, 429) or attempt == attempts - 1:
                raise
            time.sleep(5 * (attempt + 1))


def lookup(arg, country):
    slug, _, app_id = arg.partition("=")
    if app_id:
        results = get_json(f"https://itunes.apple.com/lookup?id={app_id}&country={country}&entity=software")["results"]
    else:
        term = urllib.parse.quote(slug)
        results = get_json(f"https://itunes.apple.com/search?term={term}&entity=software&country={country}&limit=10")["results"]
        fitness = [r for r in results if "Health" in r.get("primaryGenreName", "")]
        results = fitness or results
    if not results:
        raise SystemExit(f"no App Store result for {arg}")
    app = results[0]
    return re.sub(r"[^a-z0-9]+", "-", slug.lower()).strip("-") or str(app["trackId"]), app


def bigger(url, width=600):
    # mzstatic serves any size from the last path segment: …/392x696bb.png → …/600x0w.png
    return re.sub(r"/[^/]+$", f"/{width}x0w.png", url)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("out")
    p.add_argument("apps", nargs="+")
    p.add_argument("--country", default="us")
    p.add_argument("--frames", type=int, default=6)
    p.add_argument("--ours", help="slug=appID of your own live listing, shown first")
    p.add_argument("--ours-dir", help="folder of your proposed frames (1.png…), shown as 'ours (proposed)'")
    a = p.parse_args()

    os.makedirs(a.out, exist_ok=True)
    rows, summary = [], []
    entries = ([a.ours] if a.ours else []) + a.apps
    for arg in entries:
        try:
            slug, app = lookup(arg, a.country)
        except Exception as error:  # one missing app shouldn't sink the teardown
            print(f"{arg}: skipped ({error})", file=sys.stderr)
            continue
        folder = os.path.join(a.out, slug)
        os.makedirs(folder, exist_ok=True)
        files = []
        for i, url in enumerate(app.get("screenshotUrls", [])[: a.frames], start=1):
            path = os.path.join(folder, f"{i}.png")
            try:
                with urllib.request.urlopen(urllib.request.Request(bigger(url), headers=UA), timeout=30) as r:
                    open(path, "wb").write(r.read())
                files.append(f"{slug}/{i}.png")
            except Exception as error:  # keep going; the summary records the gap
                print(f"  {slug} frame {i}: {error}", file=sys.stderr)
        info = {
            "slug": slug, "name": app["trackName"], "seller": app.get("sellerName"), "id": app["trackId"],
            "rating": app.get("averageUserRating"), "ratingCount": app.get("userRatingCount"),
            "price": app.get("formattedPrice"), "url": app.get("trackViewUrl"),
            "screenshotCount": len(app.get("screenshotUrls", [])),
            "description": (app.get("description") or "")[:400], "frames": files, "ours": arg == a.ours,
        }
        summary.append(info)
        rows.append(info)
        print(f"{slug}: {info['name']} · {info['rating']} ({info['ratingCount']}) · {len(files)} frames")

    if a.ours_dir:
        frames = sorted(f for f in os.listdir(a.ours_dir) if f.endswith((".png", ".jpg", ".webp")))
        rel = os.path.relpath(a.ours_dir, a.out)
        rows.insert(0, {"slug": "ours-proposed", "name": "Ours (proposed)", "rating": None, "ratingCount": None,
                        "frames": [f"{rel}/{f}" for f in frames[: a.frames]], "ours": True})

    json.dump(summary, open(os.path.join(a.out, "summary.json"), "w"), indent=1)
    cells = []
    for row in rows:
        imgs = "".join(f'<img src="{html.escape(f)}" alt="">' for f in row["frames"])
        meta = f"{row['rating']:.2f}★ · {row['ratingCount']:,}" if row.get("rating") else ""
        cells.append(f'<section class="{"ours" if row.get("ours") else ""}"><h2>{html.escape(row["name"])}'
                     f'<small>{meta}</small></h2><div class="frames">{imgs}</div></section>')
    open(os.path.join(a.out, "contact-sheet.html"), "w").write(
        "<!doctype html><meta charset=utf-8><title>Store art teardown</title><style>"
        "body{margin:0;padding:24px;background:#f2f2f2;font:14px -apple-system,Inter,sans-serif}"
        "section{margin:0 0 28px}h2{font-size:16px;margin:0 0 8px}small{color:#777;font-weight:400;margin-left:8px}"
        ".frames{display:flex;gap:10px}img{width:150px;border-radius:10px;box-shadow:0 1px 3px rgba(0,0,0,.2)}"
        ".ours h2{color:#b81f24}</style>" + "".join(cells))
    print(f"wrote {a.out}/contact-sheet.html")


if __name__ == "__main__":
    main()
