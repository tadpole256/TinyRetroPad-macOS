#!/usr/bin/env python3
"""Generate a Windows 2000 Notepad-style app icon for TinyRetroPad.

Classic look: a white page with a dog-eared (folded) top-right corner
and a few horizontal ruled lines, rendered at high resolution and
downsampled for crisp results at every macOS icon size.
"""

import math
import os
import sys

from PIL import Image, ImageDraw, ImageFilter

ICONSET_DIR = sys.argv[1] if len(sys.argv) > 1 else "/tmp/AppIcon.iconset"
os.makedirs(ICONSET_DIR, exist_ok=True)

MASTER = 1024


def draw_notepad(size):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    # Page bounds
    left = size * 0.20
    top = size * 0.11
    right = size * 0.82
    bottom = size * 0.91
    fold = (right - left) * 0.24

    page_white = (255, 255, 255, 255)
    page_border = (120, 128, 145, 255)
    fold_fill = (222, 227, 234, 255)
    fold_crease = (168, 176, 190, 255)
    line_color = (46, 108, 196, 255)
    margin_color = (214, 90, 100, 200)

    border_w = max(2, round(size * 0.006))

    # --- Drop shadow ---
    shadow_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow_layer)
    page_poly = [
        (left, top),
        (right - fold, top),
        (right, top + fold),
        (right, bottom),
        (left, bottom),
    ]
    shadow_offset = size * 0.018
    shadow_poly = [(x + shadow_offset, y + shadow_offset * 1.2) for x, y in page_poly]
    sd.polygon(shadow_poly, fill=(20, 20, 30, 90))
    shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(radius=size * 0.02))
    img = Image.alpha_composite(img, shadow_layer)

    draw = ImageDraw.Draw(img)

    # --- Page body (with dog-eared corner cut) ---
    draw.polygon(page_poly, fill=page_white, outline=page_border, width=border_w)

    # --- Folded corner flap ---
    flap_poly = [
        (right - fold, top),
        (right, top),
        (right, top + fold),
    ]
    draw.polygon(flap_poly, fill=fold_fill, outline=page_border, width=border_w)
    draw.line([(right - fold, top), (right, top + fold)], fill=fold_crease, width=max(1, round(size * 0.004)))

    # --- Left ruled margin line ---
    margin_x = left + (right - left) * 0.16
    draw.line(
        [(margin_x, top + fold * 0.55), (margin_x, bottom - (bottom - top) * 0.05)],
        fill=margin_color,
        width=max(1, round(size * 0.006)),
    )

    # --- Ruled horizontal lines ---
    line_left = margin_x + (right - left) * 0.05
    line_right = right - (right - left) * 0.08
    first_y = top + fold * 1.35
    last_y = bottom - (bottom - top) * 0.08
    line_w = max(1, round(size * 0.008))
    available = last_y - first_y
    min_gap = max(line_w * 3.2, size * 0.045)
    n_lines = max(3, min(9, int(available // min_gap) + 1))
    for i in range(n_lines):
        y = first_y + (available * i / (n_lines - 1) if n_lines > 1 else 0)
        draw.line([(line_left, y), (line_right, y)], fill=line_color, width=line_w)

    return img


def create_all_sizes():
    master = draw_notepad(MASTER)

    sizes = {
        "icon_16x16.png": 16,
        "icon_16x16@2x.png": 32,
        "icon_32x32.png": 32,
        "icon_32x32@2x.png": 64,
        "icon_128x128.png": 128,
        "icon_128x128@2x.png": 256,
        "icon_256x256.png": 256,
        "icon_256x256@2x.png": 512,
        "icon_512x512.png": 512,
        "icon_512x512@2x.png": 1024,
    }

    for name, size in sizes.items():
        resized = master.resize((size, size), Image.LANCZOS)
        resized.save(os.path.join(ICONSET_DIR, name))

    print(f"  Generated {len(sizes)} icon sizes in {ICONSET_DIR}")


create_all_sizes()
