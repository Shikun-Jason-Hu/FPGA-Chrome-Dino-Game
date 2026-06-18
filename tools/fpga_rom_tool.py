#!/usr/bin/env python3
"""
fpga_rom_tool.py

Universal PNG-to-ROM tool for FPGA sprite/image projects.

Requires:
    pip install pillow
"""

from __future__ import annotations

import argparse
from pathlib import Path
from typing import List, Optional, Tuple

from PIL import Image, ImageOps


def find_bbox(
    img: Image.Image,
    alpha_threshold: int = 10,
    white_threshold: int = 250,
    use_alpha_only: bool = False,
) -> Optional[Tuple[int, int, int, int]]:
    """Find bounding box of visible sprite/object pixels."""
    img = img.convert("RGBA")
    pixels = img.load()
    w, h = img.size
    xs, ys = [], []

    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if a <= alpha_threshold:
                continue

            if use_alpha_only:
                xs.append(x)
                ys.append(y)
            else:
                is_near_white = r > white_threshold and g > white_threshold and b > white_threshold
                if not is_near_white:
                    xs.append(x)
                    ys.append(y)

    if not xs:
        return None

    return min(xs), min(ys), max(xs), max(ys)


def image_to_binary_rows(
    input_file: Path,
    rom_w: int,
    rom_h: int,
    resize_w: Optional[int] = None,
    resize_h: Optional[int] = None,
    threshold: int = 128,
    alpha_threshold: int = 10,
    white_threshold: int = 250,
    use_alpha_only_bbox: bool = False,
    preview_file: Optional[Path] = None,
) -> List[str]:
    """Convert one PNG image into binary ROM rows."""
    img = Image.open(input_file).convert("RGBA")

    bbox = find_bbox(
        img,
        alpha_threshold=alpha_threshold,
        white_threshold=white_threshold,
        use_alpha_only=use_alpha_only_bbox,
    )

    if bbox is None:
        raise RuntimeError(f"No object pixels found in {input_file}")

    left, top, right, bottom = bbox
    obj = img.crop((left, top, right + 1, bottom + 1))

    if resize_w is not None and resize_h is not None:
        obj = obj.resize((resize_w, resize_h), Image.Resampling.NEAREST)

    obj_w, obj_h = obj.size

    if obj_w > rom_w or obj_h > rom_h:
        raise RuntimeError(
            f"{input_file}: object is {obj_w}x{obj_h}, bigger than ROM slot {rom_w}x{rom_h}"
        )

    canvas = Image.new("RGBA", (rom_w, rom_h), (255, 255, 255, 0))
    x0 = (rom_w - obj_w) // 2
    y0 = (rom_h - obj_h) // 2
    canvas.paste(obj, (x0, y0), obj)

    if preview_file is not None:
        preview_file.parent.mkdir(parents=True, exist_ok=True)
        canvas.save(preview_file)

    gray = ImageOps.grayscale(canvas)
    rows = []

    for y in range(rom_h):
        bits = []
        for x in range(rom_w):
            _, _, _, a = canvas.getpixel((x, y))
            brightness = gray.getpixel((x, y))
            bit = "1" if (a > alpha_threshold and brightness < threshold) else "0"
            bits.append(bit)
        rows.append("".join(bits))

    print(
        f"{input_file}: bbox=({left},{top})-({right},{bottom}), "
        f"object={obj_w}x{obj_h}, slot={rom_w}x{rom_h}, placed=({x0},{y0})"
    )

    return rows


def binary_rows_to_hex_rows(rows: List[str]) -> List[str]:
    """Convert binary ROM rows to zero-padded hex rows."""
    hex_rows = []

    for row in rows:
        row = row.strip().replace(" ", "")
        if not row:
            continue
        if any(c not in "01" for c in row):
            raise ValueError(f"Invalid binary row: {row}")

        width = len(row)
        hex_digits = (width + 3) // 4
        value = int(row, 2)
        hex_rows.append(f"{value:0{hex_digits}X}")

    return hex_rows


def write_rows(rows: List[str], output_file: Path, output_format: str) -> None:
    """Write rows as .mem or .hex."""
    output_file.parent.mkdir(parents=True, exist_ok=True)

    if output_format == "mem":
        out_rows = rows
    elif output_format == "hex":
        out_rows = binary_rows_to_hex_rows(rows)
    else:
        raise ValueError("Format must be 'mem' or 'hex'.")

    with output_file.open("w", encoding="utf-8") as f:
        for row in out_rows:
            f.write(row + "\n")

    print(f"Created {output_file} ({len(out_rows)} rows, format={output_format})")


def convert_mem_to_hex(input_file: Path, output_file: Optional[Path]) -> None:
    """Convert binary .mem file to .hex file."""
    if output_file is None:
        output_file = input_file.with_suffix(".hex")

    rows = []
    with input_file.open("r", encoding="utf-8") as fin:
        for line in fin:
            row = line.strip().replace(" ", "")
            if not row:
                continue
            if any(c not in "01" for c in row):
                print(f"Warning: skipping invalid line: {row}")
                continue
            rows.append(row)

    write_rows(rows, output_file, "hex")


def parse_sprite_arg(value: str) -> Tuple[Path, int, int]:
    """
    Parse:
        --sprite image_path,width,height
    Example:
        --sprite assets/sprites/dino_run1.png,22,26
    """
    parts = [p.strip() for p in value.split(",")]
    if len(parts) != 3:
        raise argparse.ArgumentTypeError("Sprite format must be: image_path,width,height")

    try:
        return Path(parts[0]), int(parts[1]), int(parts[2])
    except ValueError as exc:
        raise argparse.ArgumentTypeError("width and height must be integers") from exc


def command_single(args: argparse.Namespace) -> None:
    preview_file = None
    if args.preview:
        preview_file = args.output.with_name(args.output.stem + "_preview.png")

    rows = image_to_binary_rows(
        input_file=args.image,
        rom_w=args.w,
        rom_h=args.h,
        resize_w=args.resize_w,
        resize_h=args.resize_h,
        threshold=args.threshold,
        alpha_threshold=args.alpha_threshold,
        white_threshold=args.white_threshold,
        use_alpha_only_bbox=args.alpha_bbox,
        preview_file=preview_file,
    )

    write_rows(rows, args.output, args.format)


def command_sprites(args: argparse.Namespace) -> None:
    all_rows = []

    if args.preview_dir is not None:
        args.preview_dir.mkdir(parents=True, exist_ok=True)

    for sid, (image_path, real_w, real_h) in enumerate(args.sprite):
        preview_file = None
        if args.preview_dir is not None:
            preview_file = args.preview_dir / f"{sid}_{image_path.name}"

        rows = image_to_binary_rows(
            input_file=image_path,
            rom_w=args.slot_w,
            rom_h=args.slot_h,
            resize_w=real_w,
            resize_h=real_h,
            threshold=args.threshold,
            alpha_threshold=args.alpha_threshold,
            white_threshold=args.white_threshold,
            use_alpha_only_bbox=True,
            preview_file=preview_file,
        )

        all_rows.extend(rows)
        print(f"SID {sid}: {image_path} -> resized {real_w}x{real_h}")

    write_rows(all_rows, args.output, args.format)
    print(f"Total sprite rows: {len(all_rows)}")
    print(f"Sprites: {len(args.sprite)}")
    print(f"Slot size: {args.slot_w}x{args.slot_h}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Generate FPGA ROM .mem/.hex files from PNG images."
    )
    sub = parser.add_subparsers(dest="command", required=True)

    p_single = sub.add_parser("single", help="Convert one PNG image to ROM")
    p_single.add_argument("image", type=Path)
    p_single.add_argument("-o", "--output", type=Path, required=True)
    p_single.add_argument("--w", type=int, required=True, help="ROM width in pixels")
    p_single.add_argument("--h", type=int, required=True, help="ROM height in pixels")
    p_single.add_argument("--resize-w", type=int, default=None)
    p_single.add_argument("--resize-h", type=int, default=None)
    p_single.add_argument("--format", choices=["mem", "hex"], default="hex")
    p_single.add_argument("--threshold", type=int, default=128)
    p_single.add_argument("--alpha-threshold", type=int, default=10)
    p_single.add_argument("--white-threshold", type=int, default=250)
    p_single.add_argument("--alpha-bbox", action="store_true")
    p_single.add_argument("--preview", action="store_true")
    p_single.set_defaults(func=command_single)

    p_sprites = sub.add_parser("sprites", help="Convert multiple sprites into one ROM")
    p_sprites.add_argument("-o", "--output", type=Path, required=True)
    p_sprites.add_argument("--slot-w", type=int, default=32)
    p_sprites.add_argument("--slot-h", type=int, default=40)
    p_sprites.add_argument(
        "--sprite",
        type=parse_sprite_arg,
        action="append",
        required=True,
        help="image_path,width,height. Can be repeated.",
    )
    p_sprites.add_argument("--format", choices=["mem", "hex"], default="hex")
    p_sprites.add_argument("--threshold", type=int, default=128)
    p_sprites.add_argument("--alpha-threshold", type=int, default=10)
    p_sprites.add_argument("--white-threshold", type=int, default=250)
    p_sprites.add_argument("--preview-dir", type=Path, default=None)
    p_sprites.set_defaults(func=command_sprites)

    p_bin = sub.add_parser("bin2hex", help="Convert binary .mem rows to hex .hex rows")
    p_bin.add_argument("input", type=Path)
    p_bin.add_argument("-o", "--output", type=Path, default=None)
    p_bin.set_defaults(func=lambda args: convert_mem_to_hex(args.input, args.output))

    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
