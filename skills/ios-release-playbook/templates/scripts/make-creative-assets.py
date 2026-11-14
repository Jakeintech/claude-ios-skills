#!/usr/bin/env python3
"""Product page header (3840x1646) and search results card (3840x2560) for App Store Connect.

Usage: python3 scripts/make-creative-assets.py
Reads the raw iPhone captures in appstore/screenshots/raw/iphone (run capture-appstore-screens.sh)
and the app icon; writes appstore/creative/header-3840x1646.png and search-3840x2560.png.
Upload with: ruby appstore/asc/creative_assets.rb place <PLACEMENT_TYPE> <file.png>
Apple overlays the app name and Get button on these, so the art keeps text to one line, left.
"""
import glob, os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW = os.path.join(ROOT, "appstore/screenshots/raw/iphone")
OUT = os.path.join(ROOT, "appstore/creative")
ICON = os.path.join(ROOT, "MyApp/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
BG_TOP, BG_BOTTOM = (11, 11, 18), (42, 42, 74)
ACCENT, LABEL, MUTED = (214, 244, 90), (245, 245, 247), (174, 174, 186)
BOLD = "/System/Library/Fonts/SFNSRounded.ttf"
TEXT = "/System/Library/Fonts/SFNS.ttf"


def shot(slug):
    return Image.open(glob.glob(os.path.join(RAW, f"*-{slug}.png"))[0]).convert("RGB")


def stage(w, h):
    im = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(im)
    for y in range(h):
        f = y / (h - 1)
        d.line([(0, y), (w, y)], fill=tuple(int(BG_TOP[k] + (BG_BOTTOM[k] - BG_TOP[k]) * f) for k in range(3)))
    # a soft airglow band low on the horizon
    glow = Image.new("L", (w, h), 0)
    ImageDraw.Draw(glow).ellipse((-w * 0.2, h * 0.78, w * 1.2, h * 1.5), fill=70)
    tint = Image.new("RGB", (w, h), (60, 80, 20))
    im.paste(tint, (0, 0), glow.filter(ImageFilter.GaussianBlur(h * 0.12)))
    return im


def phone(im, x, y, height, radius_ratio=0.075):
    s = im.resize((int(im.width * height / im.height), height), Image.LANCZOS)
    r = int(s.width * radius_ratio)
    shadow = Image.new("L", (s.width + 160, s.height + 160), 0)
    ImageDraw.Draw(shadow).rounded_rectangle((80, 100, s.width + 80, s.height + 80), radius=r, fill=150)
    return s, r, shadow.filter(ImageFilter.GaussianBlur(50)), (x, y)


def place(canvas, s, r, shadow, xy):
    x, y = xy
    canvas.paste((0, 0, 0), (x - 80, y - 80), shadow)
    mask = Image.new("L", s.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, s.width - 1, s.height - 1), radius=r, fill=255)
    edge = Image.new("L", (s.width + 8, s.height + 8), 0)
    ImageDraw.Draw(edge).rounded_rectangle((0, 0, s.width + 7, s.height + 7), radius=r + 4, fill=255)
    canvas.paste((70, 70, 90), (x - 4, y - 4), edge)
    canvas.paste(s, (x, y), mask)


def brand(canvas, x, y, scale):
    d = ImageDraw.Draw(canvas)
    icon = Image.open(ICON).convert("RGB").resize((int(150 * scale), int(150 * scale)), Image.LANCZOS)
    m = Image.new("L", icon.size, 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, icon.width - 1, icon.height - 1), radius=int(34 * scale), fill=255)
    canvas.paste(icon, (x, y), m)
    d.text((x, y + int(200 * scale)), "<Tagline.>", font=ImageFont.truetype(BOLD, int(150 * scale)), fill=LABEL)
    d.text((x, y + int(390 * scale)), "<What it is>", font=ImageFont.truetype(TEXT, int(64 * scale)), fill=MUTED)
    d.rounded_rectangle((x, y + int(500 * scale), x + int(140 * scale), y + int(516 * scale)), radius=int(8 * scale), fill=ACCENT)


def header():
    W, H = 3840, 1646
    c = stage(W, H)
    brand(c, 300, 470, 1.25)
    for slug, x, y, h in (("daily", 1980, 260, 1300), ("outcome", 2560, 140, 1420), ("input", 3180, 300, 1260)):
        place(c, *phone(shot(slug), x, y, h))
    return c


def search():
    W, H = 3840, 2560
    c = stage(W, H)
    brand(c, 260, 900, 1.15)
    for slug, x, y, h in (("daily", 1700, 560, 1640), ("outcome", 2330, 360, 1900), ("wow", 3060, 620, 1560)):
        place(c, *phone(shot(slug), x, y, h))
    return c


os.makedirs(OUT, exist_ok=True)
header().save(os.path.join(OUT, "header-3840x1646.png"), optimize=True)
search().save(os.path.join(OUT, "search-3840x2560.png"), optimize=True)
print("wrote", OUT)
