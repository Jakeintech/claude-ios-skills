#!/usr/bin/env python3
"""Frame raw simulator captures into App Store screenshots.

Usage: compose-appstore-screenshots.py <raw_dir> <out_dir>
  raw_dir/<kind>/<NN-slug>.png   kind = iphone | ipad | watch
  out_dir/<DISPLAY_TYPE>/<NN-slug>.png, ready for appstore/asc/screenshots.rb (MyApp)

Captions come from CAPTIONS below, keyed by slug. Watch captures are passed
through unframed (Apple shows them on a watch bezel already).
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

BG = (11, 11, 18)            # tokens.json bg (dark)
ACCENT = (214, 244, 90)      # Airglow #D6F45A
CREAM = (245, 245, 247)
MUTED = (174, 174, 186)
# Per-shot stage gradients (top, bottom) from docs/design/screens/AppStore.dc.html.
GRADIENTS = {  # slug -> stage gradient (top, bottom), from the design's App Store board
    "outcome":  ((20, 26, 0), (61, 74, 16)),
    "daily":    ((21, 21, 31), (58, 58, 92)),
    "input":    ((20, 26, 0), (61, 74, 16)),
    "wow":      ((11, 11, 18), (42, 42, 74)),
    "night":    ((32, 0, 0), (74, 0, 0)),
    "tools":    ((21, 21, 31), (58, 58, 92)),
}
def _font(env, candidates):
    """First existing font: $env, then Linux Inter, then macOS system fonts."""
    for path in [os.environ.get(env)] + candidates:
        if path and os.path.exists(path):
            return path
    sys.exit(f"no font found; set {env} to a .ttf/.otf path")


FONT_BOLD = _font("SCREENSHOT_FONT_BOLD", [
    "/usr/share/fonts/opentype/inter/InterDisplay-Bold.otf",
    "/System/Library/Fonts/SFNSRounded.ttf",
    "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
])
FONT_MED = _font("SCREENSHOT_FONT_MEDIUM", [
    "/usr/share/fonts/opentype/inter/InterDisplay-Medium.otf",
    "/System/Library/Fonts/SFNS.ttf",
    "/System/Library/Fonts/Supplemental/Arial.ttf",
])

CAPTIONS = {  # headline, subline. Say what the app does first; every claim matches the screen under it.
    "outcome": ("<The result the user came for>", "<How the app gets them there>"),
    "daily":   ("<The answer they check every day>", "<What it combines>"),
    "input":   ("<The signature input>", "<A concrete example>"),
    "wow":     ("<The view that makes people stop>", "<Why it is true>"),
    "night":   ("<Accessibility or field mode>", "<Who it helps>"),
    "tools":   ("<The toolbox>", "<How many, set from their gear>"),
}

SPECS = {  # kind -> (display type, canvas size)
    "iphone": ("APP_IPHONE_67", (1320, 2868)),
    "ipad":   ("APP_IPAD_PRO_3GEN_129", (2048, 2732)),
}


def wrap(draw, text, font, width):
    words, lines, cur = text.split(), [], ""
    for w in words:
        t = (cur + " " + w).strip()
        if draw.textlength(t, font=font) <= width or not cur:
            cur = t
        else:
            lines.append(cur); cur = w
    lines.append(cur)
    # balance two-line titles so a single word doesn't hang on its own
    if len(lines) == 2 and len(lines[1].split()) == 1 and len(lines[0].split()) > 2:
        first = lines[0].split()
        lines = [" ".join(first[:-1]), first[-1] + " " + lines[1]]
    return lines


def frame(raw_path, out_path, size, slug):
    W, H = size
    top, bottom = GRADIENTS.get(slug, (BG, BG))
    canvas = Image.new("RGB", size, BG)
    gd = ImageDraw.Draw(canvas)
    for yy in range(H):  # vertical stage gradient, as on the designed App Store page
        f = yy / (H - 1)
        gd.line([(0, yy), (W, yy)], fill=tuple(int(top[k] + (bottom[k] - top[k]) * f) for k in range(3)))
    d = ImageDraw.Draw(canvas)

    title, sub = CAPTIONS.get(slug, (slug.replace("-", " ").title(), ""))
    margin = int(W * 0.08)
    tsize = int(min(W * 0.074, H * 0.042))
    tf = ImageFont.truetype(FONT_BOLD, tsize)
    sf = ImageFont.truetype(FONT_MED, int(tsize * 0.42))
    y = int(H * 0.055)
    for line in wrap(d, title, tf, W - 2 * margin):
        lw = d.textlength(line, font=tf)
        d.text(((W - lw) / 2, y), line, font=tf, fill=CREAM)
        y += int(tsize * 1.12)
    y += int(tsize * 0.18)
    for line in wrap(d, sub, sf, W - 2 * margin):
        lw = d.textlength(line, font=sf)
        d.text(((W - lw) / 2, y), line, font=sf, fill=MUTED)
        y += int(tsize * 0.55)
    # accent rule
    y += int(tsize * 0.35)
    d.rounded_rectangle(((W - 90) / 2, y, (W + 90) / 2, y + 10), radius=5, fill=ACCENT)
    y += int(tsize * 0.75)

    shot = Image.open(raw_path).convert("RGB")
    if "/ipad/" in raw_path:
        # The iPad status bar shows today's weekday whatever the override says: crop it (24 pt at 2x).
        shot = shot.crop((0, 48, shot.width, shot.height))
    avail_h = H - y - int(H * 0.035)
    scale = min((W * 0.88) / shot.width, avail_h / shot.height)
    sw, sh = int(shot.width * scale), int(shot.height * scale)
    shot = shot.resize((sw, sh), Image.LANCZOS)
    radius = int(sw * 0.075)
    mask = Image.new("L", (sw, sh), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, sw - 1, sh - 1), radius=radius, fill=255)
    x = (W - sw) // 2
    # subtle border
    border = Image.new("L", (sw + 6, sh + 6), 0)
    ImageDraw.Draw(border).rounded_rectangle((0, 0, sw + 5, sh + 5), radius=radius + 3, fill=255)
    canvas.paste(Image.new("RGB", border.size, (60, 56, 52)), (x - 3, y - 3), border)
    canvas.paste(shot, (x, y), mask)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    canvas.save(out_path, "PNG", optimize=True)


# Upload order per device (App Store shows the first two or three in search results).
ORDER = {
    "iphone": ["outcome", "daily", "input", "wow", "night", "tools"],
    "ipad":   ["outcome", "daily", "input", "wow", "night", "tools"],
}


def main(raw_dir, out_dir):
    for kind in sorted(os.listdir(raw_dir)):
        src = os.path.join(raw_dir, kind)
        if not os.path.isdir(src):
            continue
        names = sorted(f for f in os.listdir(src) if f.endswith(".png"))
        order = ORDER.get(kind)
        if order:  # store order: strongest screens first; unknown slugs keep their place at the end
            rank = {slug: i for i, slug in enumerate(order)}
            names.sort(key=lambda f: (rank.get(f[:-4].split("-", 1)[-1], len(order)), f))
        for i, name in enumerate(names, 1):
            slug = name[:-4].split("-", 1)[-1]
            if kind == "watch":
                im = Image.open(os.path.join(src, name)).convert("RGB")
                dest = os.path.join(out_dir, "APP_WATCH_ULTRA", name)
                os.makedirs(os.path.dirname(dest), exist_ok=True)
                im.save(dest, "PNG")
            else:
                dtype, size = SPECS[kind]
                frame(os.path.join(src, name), os.path.join(out_dir, dtype, "%02d-%s.png" % (i, slug)), size, slug)
            print("framed", kind, name)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
