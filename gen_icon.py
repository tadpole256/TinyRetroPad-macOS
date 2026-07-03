#!/usr/bin/env python3
"""Generate a Notepad-style app icon for TinyRetroPad."""

import struct, zlib, os, sys

ICONSET_DIR = sys.argv[1] if len(sys.argv) > 1 else "/tmp/AppIcon.iconset"
os.makedirs(ICONSET_DIR, exist_ok=True)

def png_chunk(ctype, data):
    c = ctype + data
    return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)

def rgba(r, g, b, a=255):
    return bytes([r, g, b, a])

def draw_notepad(size):
    """Draw a classic Notepad icon: blue header, white body with lines, spiral left edge."""
    pixels = bytearray()
    header_h = int(size * 0.22)  # Blue title bar height
    spiral_w = int(size * 0.10)  # Left spiral binding width
    
    # Colors (classic Windows Notepad)
    title_blue = (0, 60, 160)       # Deep blue
    title_light = (70, 130, 220)     # Lighter blue highlight
    paper = (255, 255, 255)          # White
    page_bg = (250, 251, 252)        # Slightly off-white
    line_gray = (210, 218, 230)      # Faint ruled lines
    spiral_dark = (140, 150, 165)    # Dark spiral ring
    spiral_light = (180, 188, 200)   # Light spiral ring
    shadow = (0, 0, 0, 30)          # Subtle page shadow
    border = (180, 185, 195)         # Page border
    
    for y in range(size):
        pixels.extend(b'\x00')  # filter none
        
        for x in range(size):
            # Shadow (offset right and down)
            if x > size - 4 or y > size - 4:
                pixels.extend(rgba(0, 0, 0, 0))
                continue
            
            # Spiral binding area (left edge)
            if x < spiral_w:
                ring = y % (spiral_w + 2)
                if ring < spiral_w // 3:
                    pixels.extend(rgba(*spiral_dark))
                elif ring < spiral_w * 2 // 3:
                    pixels.extend(rgba(*spiral_light))
                else:
                    pixels.extend(rgba(*spiral_dark))
                continue
            
            # Title bar (blue header)
            if y < header_h:
                if y < 3:
                    pixels.extend(rgba(*title_light))  # Top highlight
                elif y > header_h - 3:
                    pixels.extend(rgba(0, 40, 120))     # Bottom edge
                else:
                    # Subtle gradient in title bar
                    t = (y - 3) / (header_h - 6)
                    r = int(title_blue[0] + (title_light[0] - title_blue[0]) * t * 0.4)
                    g = int(title_blue[1] + (title_light[1] - title_blue[1]) * t * 0.4)
                    b = int(title_blue[2] + (title_light[2] - title_blue[2]) * t * 0.4)
                    pixels.extend(rgba(r, g, b))
                continue
            
            # Page body
            local_y = y - header_h
            page_h = size - header_h
            
            # Page border
            if x == spiral_w or x == size - 5 or y == header_h or y == size - 5:
                pixels.extend(rgba(*border))
            # Ruled lines every ~12px
            elif local_y > 0 and local_y % max(4, size // 48) == 0:
                pixels.extend(rgba(*line_gray))
            else:
                pixels.extend(rgba(*page_bg))
    
    return bytes(pixels)

def create_all_sizes():
    sizes = {
        'icon_16x16.png': 16,       'icon_16x16@2x.png': 32,
        'icon_32x32.png': 32,       'icon_32x32@2x.png': 64,
        'icon_128x128.png': 128,    'icon_128x128@2x.png': 256,
        'icon_256x256.png': 256,    'icon_256x256@2x.png': 512,
        'icon_512x512.png': 512,    'icon_512x512@2x.png': 1024,
    }
    
    for name, size in sizes.items():
        raw = draw_notepad(size)
        header = (b'\x89PNG\r\n\x1a\n'
                  + png_chunk(b'IHDR', struct.pack('>IIBBBBB', size, size, 8, 6, 0, 0, 0))
                  + png_chunk(b'IDAT', zlib.compress(raw))
                  + png_chunk(b'IEND', b''))
        path = os.path.join(ICONSET_DIR, name)
        with open(path, 'wb') as f:
            f.write(header)
    print(f"  Generated {len(sizes)} icon sizes in {ICONSET_DIR}")

create_all_sizes()
