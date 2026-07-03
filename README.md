# TinyRetroPad for macOS

A native macOS port of [TinyRetroPad](https://github.com/PlummersSoftwareLLC/TinyRetroPad) by [Plummer's Software](https://github.com/PlummersSoftwareLLC), which was built on [Dave's Tiny Editor (DTE)](https://github.com/PlummersSoftwareLLC/TinyRetroPad) by Matt Power.

The original TinyRetroPad is a working Notepad-style Windows text editor written in x86 assembly that fits in roughly 2.5 KB (with Crinkler compression). This port brings the same minimalist spirit to macOS using AppKit and NSTextView — a clean, fast, native text editor that does one thing well.

```
 _____      _             _____          _
|  __ \    | |           |  __ \        | |
| |__) |___| |_ _ __ ___ | |__) |_ _  __| |
|  _  // _ \ __| '__/ _ \|  ___/ _` |/ _` |
| | \ \  __/ |_| | | (_) | |  | (_| | (_| |
|_|  \_\___|\__|_|  \___/|_|   \__,_|\__,_|
 T I N Y  X 86   D E S K T O P   E D I T O R
          —  now on macOS  —
```

## Features

| Feature | Shortcut |
|---------|----------|
| New, Open, Save, Save As | ⌘N, ⌘O, ⌘S, ⇧⌘S |
| Page Setup, Print | ⇧⌘P, ⌘P |
| Undo, Redo | ⌘Z, ⇧⌘Z |
| Cut, Copy, Paste, Delete | Standard macOS shortcuts |
| Select All | ⌘A |
| Find / Find Next / Find Previous | ⌘F, ⌘G, ⇧⌘G |
| Use Selection for Find | ⌘E |
| Go To Line | ⌘L |
| Insert Time/Date | ⇧⌘T |
| Word Wrap | Toggle in Format menu |
| Font panel | ⌘T |
| Status Bar (Ln, Col) | ⌘/ |
| Drag-and-drop file open | Drop a file on the window |
| Right-click context menu | Built-in via NSTextView |
| Dark mode | Automatic with system setting |

## Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon (arm64) — native, no Rosetta needed
- Xcode Command Line Tools (for `swiftc`)

## Install

Download the latest release from [Releases](https://github.com/tadpole256/TinyRetroPad-macOS/releases) and drag `TinyRetroPad.app` to `/Applications`.

Or build from source:

```bash
git clone https://github.com/tadpole256/TinyRetroPad-macOS.git
cd TinyRetroPad-macOS
bash build.sh
open build/TinyRetroPad.app
```

## What's different from the Windows version

The Windows TinyRetroPad is 2,686 lines of x86 assembly calling Win32 API directly, compressed to ~2.5 KB via Crinkler. This macOS port is:

- **~430 lines of Swift** using AppKit (NSWindow, NSTextView, NSMenu)
- **Native Cocoa text engine** — NSTextView gives us undo, spell check, find bar, and rich text infrastructure for free, the same way Win32 RichEdit did for the original
- **154 KB binary** (uncompressed, with debug symbols stripped)
- **Single file** (`main.swift`) — no Xcode project needed

Where the original fought for every byte via assembly tricks, this port fights for simplicity via Cocoa's built-in controls. Same spirit, different battlefield.

## Project structure

```
TinyRetroPad-macOS/
├── README.md          ← You are here
├── LICENSE            ← Apache 2.0 (same as upstream)
├── main.swift         ← The entire app, ~430 lines
├── Info.plist         ← App bundle metadata
├── build.sh           ← Builds the .app bundle
└── images/
    └── screenshot.png ← Screenshot for README
```

## Credits

This is a macOS port of **[TinyRetroPad](https://github.com/PlummersSoftwareLLC/TinyRetroPad)**, copyright Plummer's Software, Ltd., licensed under Apache 2.0.

TinyRetroPad itself is built on:

- **[Dave's Tiny Editor (DTE)](https://github.com/PlummersSoftwareLLC/TinyRetroPad)** — Copyright (c) 2026 Matthew M. Power. The sub-1KB Win32 RichEdit editor that TinyRetroPad extends with full Notepad-style menus and dialogs.
- **[tiny.asm / HelloAssembly](https://github.com/PlummersSoftwareLLC/HelloAssembly)** — Copyright (c) [Dave Plummer](https://github.com/davepl). The original x86 assembly foundation that started it all.

**macOS port** by [Anthony](https://github.com/tadpole256). All original code is licensed under Apache 2.0.

See [NOTICE](NOTICE) for full attribution details.

## License

Apache License 2.0 — same as the upstream TinyRetroPad. See [LICENSE](LICENSE).
