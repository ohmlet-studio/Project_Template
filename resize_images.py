#!/usr/bin/env python3
"""
resize_images.py - Recursively resize images to fit within a max size, preserving aspect ratio.

Usage:
    python resize_images.py <folder> <max_size> [options]

Examples:
    python resize_images.py ./assets 1920
    python resize_images.py ./assets 1920 --suffix _resized
    python resize_images.py ./assets 1920 --inplace
    python resize_images.py ./assets 1920 --output ./resized --quality 85
"""

import argparse
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Pillow is required. Install it with: pip install Pillow")
    sys.exit(1)

SUPPORTED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".bmp", ".tiff", ".tif"}


def resize_image(src_path: Path, dst_path: Path, max_size: int, quality: int):
    with Image.open(src_path) as img:
        w, h = img.size
        if w <= max_size and h <= max_size:
            return False  # No resize needed

        # Compute new size preserving ratio
        ratio = min(max_size / w, max_size / h)
        new_w = int(w * ratio)
        new_h = int(h * ratio)

        resized = img.resize((new_w, new_h), Image.LANCZOS)
        dst_path.parent.mkdir(parents=True, exist_ok=True)

        # Preserve format; use quality for lossy formats
        fmt = img.format or "PNG"
        save_kwargs = {}
        if fmt in ("JPEG", "WEBP"):
            save_kwargs["quality"] = quality

        resized.save(dst_path, format=fmt, **save_kwargs)
        return True, (w, h), (new_w, new_h)


def main():
    parser = argparse.ArgumentParser(
        description="Recursively resize images to fit within a max dimension."
    )
    parser.add_argument("folder", help="Source folder to scan recursively")
    parser.add_argument("max_size", type=int, help="Max width or height in pixels")
    parser.add_argument(
        "--output", "-o",
        default=None,
        help="Output folder (mirrors source structure). Defaults to in-place if --inplace, else '<folder>_resized'."
    )
    parser.add_argument(
        "--inplace", action="store_true",
        help="Overwrite original files instead of saving to output folder"
    )
    parser.add_argument(
        "--suffix", default="",
        help="Suffix to add to output filenames (e.g. '_small'). Ignored with --inplace."
    )
    parser.add_argument(
        "--quality", type=int, default=85,
        help="JPEG/WebP quality (1-95, default: 85)"
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="Print what would be done without actually resizing"
    )

    args = parser.parse_args()

    src_folder = Path(args.folder)
    if not src_folder.is_dir():
        print(f"Error: '{src_folder}' is not a valid directory.")
        sys.exit(1)

    if args.inplace:
        out_folder = src_folder
    elif args.output:
        out_folder = Path(args.output)
    else:
        out_folder = src_folder.parent / (src_folder.name + "_resized")

    images = [
        p for p in src_folder.rglob("*")
        if p.is_file() and p.suffix.lower() in SUPPORTED_EXTENSIONS
    ]

    if not images:
        print("No supported images found.")
        sys.exit(0)

    print(f"Found {len(images)} image(s). Max size: {args.max_size}px")
    if not args.inplace:
        print(f"Output folder: {out_folder}")
    print()

    resized_count = 0
    skipped_count = 0

    for img_path in images:
        relative = img_path.relative_to(src_folder)

        if args.inplace:
            dst_path = img_path
        else:
            stem = relative.stem + args.suffix
            dst_path = out_folder / relative.parent / (stem + relative.suffix)

        if args.dry_run:
            with Image.open(img_path) as img:
                w, h = img.size
            if w > args.max_size or h > args.max_size:
                ratio = min(args.max_size / w, args.max_size / h)
                new_w, new_h = int(w * ratio), int(h * ratio)
                print(f"  [RESIZE] {relative}  {w}x{h} → {new_w}x{new_h}")
                resized_count += 1
            else:
                print(f"  [SKIP]   {relative}  {w}x{h} (already fits)")
                skipped_count += 1
            continue

        try:
            result = resize_image(img_path, dst_path, args.max_size, args.quality)
            if result is False:
                print(f"  [SKIP]   {relative}")
                skipped_count += 1
            else:
                _, orig, new = result
                print(f"  [OK]     {relative}  {orig[0]}x{orig[1]} → {new[0]}x{new[1]}")
                resized_count += 1
        except Exception as e:
            print(f"  [ERROR]  {relative}: {e}")

    print()
    print(f"Done. {resized_count} resized, {skipped_count} skipped.")


if __name__ == "__main__":
    main()