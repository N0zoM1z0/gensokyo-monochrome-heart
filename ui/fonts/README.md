# Font Assets

Run `python3 scripts/sync_fonts.py --write` to regenerate the project-original Kiri8 bitmap font and synchronize the approved DotGothic16 WOFF2 files from the pinned design package.

Kiri8 is a 5×7 prototype in a 6×8 advance cell and is imported through Godot's fixed-cell image-font importer. DotGothic16 remains under the SIL Open Font License 1.1. Runtime font policy disables antialiasing, mipmaps, subpixel positioning, and system fallback; integer-scale screenshots remain the acceptance reference.
