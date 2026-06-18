# FPGA ROM Tool

This tool converts PNG images into FPGA ROM initialization files for use with `$readmemh()`.

## Install

```bash
pip install pillow
```

## Convert one image

```bash
python fpga_rom_tool.py single assets/game_over.png -o rom/game_over.hex --w 100 --h 50 --format hex --preview
```

## Convert `.mem` to `.hex`

```bash
python fpga_rom_tool.py bin2hex rom/sprite_rom.mem -o rom/sprite_rom.hex
```

## Generate the Chrome Dino sprite ROM

```bash
python fpga_rom_tool.py sprites -o rom/sprite_rom.hex --format hex --slot-w 32 --slot-h 40 \
  --sprite assets/sprites/dino_run1.png,22,26 \
  --sprite assets/sprites/dino_run2.png,22,26 \
  --sprite assets/sprites/dino_jump.png,22,26 \
  --sprite assets/sprites/dino_duck1.png,30,16 \
  --sprite assets/sprites/dino_duck2.png,30,16 \
  --sprite assets/sprites/dino_hit.png,30,16 \
  --sprite assets/sprites/cactus.png,18,36 \
  --sprite assets/sprites/ptero_up.png,22,14 \
  --sprite assets/sprites/ptero_dn.png,22,14 \
  --preview-dir previews
```

## Pipeline

```text
PNG images
    ↓
fpga_rom_tool.py
    ↓
.hex ROM file
    ↓
$readmemh()
    ↓
FPGA ROM
    ↓
VGA renderer
```
