#!/usr/bin/env python3
"""Draw the app icon in code: a background, a glowing disc and a bold foreground subject on a horizon.

Replace subject() and the LOOKS colours with your own art; keep the .icon manifest writer and the preview sheet. Writes:
  MyApp/Resources/AppIcon.icon/            Icon Composer bundle (iOS 26 Liquid Glass): three layers
                                             (background, disc, foreground) x default/dark/tinted
  MyApp/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon{,-Dark,-Tinted}.png   flat fallbacks
  MyAppWatch/Assets.xcassets/AppIcon.appiconset/AppIcon.png                     Apple Watch (circle)
  <out>/icon-preview.png                     the three looks side by side, for review

Usage: scripts/make-app-icon.py [preview_dir]
Drawn at 4x and downsampled, so edges are smooth. Colours are the brand's icon tokens.
"""
import json, os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ICON = os.path.join(ROOT, "MyApp/Resources/AppIcon.icon")
SET = os.path.join(ROOT, "MyApp/Resources/Assets.xcassets/AppIcon.appiconset")
N = 1024
SS = 4
W = N * SS

# Brand.dc.html icon looks: background, disc, foreground. Sky gradients and glow are ours; the dark and
# tinted ground is darker than the board's so it never reads lighter than the sky.
LOOKS = {
    "default": dict(sky=("#101019", "#262640"), disc=("#E6FB8F", "#D6F45A"), glow="#D6F45A", fg="#0B0B12", glint="#D6F45A"),
    "dark":    dict(sky=("#000000", "#0E0E14"), disc=("#E6FB8F", "#D6F45A"), glow="#D6F45A", fg="#050507", glint="#D6F45A"),
    "tinted":  dict(sky=("#141416", "#2A2A2E"), disc=("#F2F2F7", "#D1D1D6"), glow="#E5E5EA", fg="#0E0E10", glint="#E5E5EA"),
}

CX, CY, R = 512, 470, 300      # the disc (Brand: cx 60, cy 58, r 34 of 120, enlarged for the bolder family style)
HORIZON = 800
BARS = os.environ.get("ICON_BARS", "0") == "1"


def rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def s(v):
    return int(round(v * SS))


def finish(img):
    return img.resize((N, N), Image.LANCZOS)


def background(look):
    top, horizon = np.array(rgb(look["sky"][0]), float), np.array(rgb(look["sky"][1]), float)
    y = np.linspace(0, 1, N)[:, None]
    t = np.clip(y / (HORIZON / N), 0, 1) ** 1.6          # darker overhead, lighter toward the horizon
    sky = top + (horizon - top) * t[..., None]
    arr = np.repeat(sky, N, axis=1).astype(np.uint8)
    return Image.fromarray(arr, "RGB").convert("RGBA")


def disc(look):
    img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    # Glow: a soft ring of the disc colour just outside its edge.
    glow = Image.new("L", (W, W), 0)
    gd = ImageDraw.Draw(glow)
    gd.ellipse((s(CX - R - 18), s(CY - R - 18), s(CX + R + 18), s(CY + R + 18)), fill=120)
    glow = glow.filter(ImageFilter.GaussianBlur(s(46)))
    img.paste(Image.new("RGBA", (W, W), rgb(look["glow"]) + (255,)), (0, 0), glow)
    # The disc, a touch lighter at the centre.
    yy, xx = np.mgrid[0:W, 0:W].astype(np.float32)
    d = np.sqrt((xx - s(CX)) ** 2 + (yy - s(CY)) ** 2) / s(R)
    inner, outer = np.array(rgb(look["disc"][0]), np.float32), np.array(rgb(look["disc"][1]), np.float32)
    t = np.clip(d, 0, 1)[..., None] ** 1.5
    col = (inner + (outer - inner) * t).astype(np.uint8)
    mask = Image.new("L", (W, W), 0)
    ImageDraw.Draw(mask).ellipse((s(CX - R), s(CY - R), s(CX + R), s(CY + R)), fill=255)
    img.paste(Image.fromarray(np.dstack([col, np.full(col.shape[:2], 255, np.uint8)]), "RGBA"), (0, 0), mask)
    return finish(img)


def subject(draw, fill):
    """Bold, few pieces, rounded corners (match the owner's other icons). Example subject: a tower."""
    # Tower: a tapered body.
    draw.polygon([(s(420), s(HORIZON)), (s(604), s(HORIZON)), (s(572), s(572)), (s(452), s(572))], fill=fill)
    # Gallery: one wide rounded bar.
    draw.rounded_rectangle((s(400), s(540), s(624), s(584)), radius=s(18), fill=fill)
    # Lantern room, then a half dome with a rounded cap.
    draw.rounded_rectangle((s(456), s(430), s(568), s(552)), radius=s(12), fill=fill)
    draw.pieslice((s(444), s(372), s(580), s(492)), 180, 360, fill=fill)
    draw.ellipse((s(498), s(352), s(526), s(380)), fill=fill)


def foreground(look):
    img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    fill = rgb(look["fg"]) + (255,)
    d.rectangle((0, s(HORIZON), W, W), fill=fill)          # sea
    # Headland: a broad rounded hill the tower stands on.
    d.ellipse((s(250), s(HORIZON - 52), s(774), s(HORIZON + 200)), fill=fill)
    subject(d, fill)
    # Lantern window: cut out, so the disc shows through as the light.
    cut = Image.new("L", (W, W), 255)
    ImageDraw.Draw(cut).rounded_rectangle((s(482), s(450), s(542), s(526)), radius=s(10), fill=0)
    img.putalpha(Image.fromarray(np.minimum(np.array(img.getchannel("A")), np.array(cut))))
    if BARS:  # the disc's reflection: two bold rounded bars either side of the headland
        g = rgb(look["glint"])
        for y, x0, x1, a in ((872, 96, 246, 200), (872, 778, 928, 200), (930, 150, 236, 140), (930, 788, 874, 140)):
            d.rounded_rectangle((s(x0), s(y), s(x1), s(y + 30)), radius=s(15), fill=g + (a,))
    return finish(img)


def composite(layers):
    out = layers[0].copy()
    for layer in layers[1:]:
        out = Image.alpha_composite(out, layer)
    return out.convert("RGB")


def main():
    preview_dir = sys.argv[1] if len(sys.argv) > 1 else ROOT
    os.makedirs(os.path.join(ICON, "Assets"), exist_ok=True)
    flats = {}
    for name, look in LOOKS.items():
        suffix = "" if name == "default" else f"-{name}"
        layers = [background(look), disc(look), foreground(look)]
        for layer, part in zip(layers, ("background", "disc", "foreground")):
            img = layer.convert("RGB") if part == "background" else layer
            img.save(os.path.join(ICON, "Assets", f"{part}{suffix}.png"))
        flats[name] = composite(layers)
    flats["default"].save(os.path.join(SET, "AppIcon.png"))
    # Apple Watch: the same art; watchOS masks it to a circle, which the centred disc fits.
    watch = os.path.join(ROOT, "MyAppWatch/Assets.xcassets/AppIcon.appiconset")
    if os.path.isdir(watch):
        flats["default"].save(os.path.join(watch, "AppIcon.png"))
    flats["dark"].save(os.path.join(SET, "AppIcon-Dark.png"))
    flats["tinted"].convert("L").convert("RGB").save(os.path.join(SET, "AppIcon-Tinted.png"))

    def specs(part):
        return [{"value": f"{part}.png"}, {"appearance": "dark", "value": f"{part}-dark.png"},
                {"appearance": "tinted", "value": f"{part}-tinted.png"}]
    manifest = {
        "groups": [{
            "layers": [{"name": p, "image-name-specializations": specs(p)} for p in ("foreground", "disc", "background")],
            "shadow": {"kind": "neutral", "opacity": 0.5},
            "translucency": {"enabled": True, "value": 0.3},
        }],
        "supported-platforms": {"circles": ["watchOS"], "squares": "shared"},
    }
    with open(os.path.join(ICON, "icon.json"), "w") as f:
        json.dump(manifest, f, indent=2)
        f.write("\n")

    # Review sheet: the three looks with the iOS corner mask, large and at Home Screen sizes.
    sheet = Image.new("RGB", (3 * 560 + 40, 760), (40, 40, 46))
    mask = Image.new("L", (N, N), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, N - 1, N - 1), radius=230, fill=255)
    for i, name in enumerate(("default", "dark", "tinted")):
        icon = flats[name].copy()
        icon.putalpha(mask)
        big = icon.resize((520, 520), Image.LANCZOS)
        sheet.paste(big, (40 + i * 560, 40), big)
        for j, size in enumerate((180, 120, 58)):
            small = icon.resize((size, size), Image.LANCZOS)
            sheet.paste(small, (40 + i * 560 + j * 200, 580 + (180 - size) // 2), small)
    sheet.save(os.path.join(preview_dir, "icon-preview.png"))
    print("wrote", ICON, "and", SET)


if __name__ == "__main__":
    main()
