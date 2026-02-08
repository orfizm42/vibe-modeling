# Vibe Modeling

Natural language → CadQuery → STL. Describe what you want, get a printable model.

```
You: "30x20x10mmの箱、角にR2フィレット、天面にφ8の穴"

  ↓ LLM generates CadQuery code ↓

=== Dimensions ===
  X: 30.00 mm
  Y: 20.00 mm
  Z: 10.00 mm
```

**Vibe Modeling** is the practice of generating parametric 3D models through natural language instructions directed at an LLM. The LLM translates human intent into executable [CadQuery](https://github.com/CadQuery/cadquery) code, which compiles into manufacturing-ready geometry.

## Quick Start

### Prerequisites

- [Podman](https://podman.io/) or [Docker](https://www.docker.com/)
- [f3d](https://f3d.app/) (optional, for preview)

### Run

```bash
git clone https://github.com/orfizm42/vibe-modeling.git
cd vibe-modeling
chmod +x vibe.sh

# Generate STL (first run builds the container image ~2 min)
./vibe.sh examples/test-box.py

# Generate + preview in f3d
./vibe.sh --preview examples/test-box.py
```

Output appears in `output/`.

## How It Works

```
┌──────────────────────────┐
│  Design Intent           │  Natural language prompt
│  (you describe a part)   │  to Claude, ChatGPT, etc.
└────────────┬─────────────┘
             ▼
┌──────────────────────────┐
│  LLM                     │  Generates CadQuery Python
└────────────┬─────────────┘
             ▼
┌──────────────────────────┐
│  vibe.sh                 │  Runs script in container
│  (Podman/Docker)         │  No local install needed
└────────────┬─────────────┘
             ▼
┌──────────────────────────┐
│  output/*.stl            │  Ready for slicer / printer
│  + terminal dimensions   │  Dimensions printed to stdout
└──────────────────────────┘
```

The container bundles CadQuery + OpenCASCADE so you don't need to install anything beyond Podman/Docker.

## Usage

```
./vibe.sh [OPTIONS] <cadquery-script.py>

Options:
  -p, --preview   Open the generated STL in f3d after export
  -h, --help      Show help
```

### Writing Scripts

Ask your LLM to generate a CadQuery script. Key conventions:

1. **Parameters at the top** — `WIDTH = 30.0`, `WALL_THICKNESS = 2.5`
2. **Export to `/work/output/`** — `cq.exporters.export(result, "/work/output/name.stl")`
3. **Print dimensions** — Use `BoundingBox()` for verification

```python
import cadquery as cq

WIDTH = 30.0
DEPTH = 20.0
HEIGHT = 10.0

result = cq.Workplane("XY").box(WIDTH, DEPTH, HEIGHT)

bb = result.val().BoundingBox()
print(f"Bounding Box: {bb.xmax - bb.xmin:.2f} x {bb.ymax - bb.ymin:.2f} x {bb.zmax - bb.zmin:.2f} mm")

cq.exporters.export(result, "/work/output/box.stl")
```

### Viewing Results

Dimensions are printed in the terminal. For visual inspection:

```bash
# f3d (recommended — lightweight, fast)
f3d output/box.stl

# Useful f3d hotkeys
# H     — show all hotkeys
# E     — toggle edge display
# G     — toggle grid
# X     — toggle axis
# Enter — reset camera
# F12   — screenshot
```

## Project Structure

```
vibe-modeling/
├── Containerfile       # CadQuery container recipe
├── vibe.sh             # One-command runner
├── examples/
│   └── test-box.py     # Sample: box with fillet and hole
├── output/             # Generated STLs (gitignored)
├── manifesto/
│   ├── en.md           # Manifesto (English)
│   └── ja.md           # マニフェスト (日本語)
└── README.md
```

## Principles

1. **Specify Function, Not Form** — Describe what the part does, not how to draw it
2. **Iterate Conversationally** — Refine by talking to the LLM, not editing code
3. **Validate All Output** — Always check dimensions and visual shape before printing
4. **Preserve Parametric Structure** — Named parameters at the top, not magic numbers
5. **Distribute Prompts Alongside Artifacts** — Share the prompt that created the model

See the full [Manifesto (EN)](manifesto/en.md) / [マニフェスト (JA)](manifesto/ja.md).

## Requirements

| Component | Required | Purpose |
|-----------|----------|---------|
| Podman or Docker | ✅ | Container runtime |
| f3d | Optional | STL preview viewer |
| Slicer (PrusaSlicer, etc.) | Optional | Print preparation |

No Python, Conda, or CadQuery installation required on the host.

## License

[MIT](LICENSE)
