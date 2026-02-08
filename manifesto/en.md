# Vibe Modeling: Natural Language as a CAD Interface

*A technical proposal for LLM-driven parametric 3D modeling.*

---

## Definition

**Vibe Modeling** is the practice of generating parametric 3D models through natural language instructions directed at a Large Language Model (LLM). The LLM translates human intent into executable CAD code, which is then compiled into manufacturing-ready geometry.

The term is derived from **Vibe Coding** — the established practice of delegating software development to LLMs via natural language prompts. Vibe Modeling extends this paradigm from source code to physical objects.

```
Input:  "Design an enclosure for a 34mm trackball with a PMW3360
         sensor mount, ergonomic palm rest, and two side buttons.
         The geometry must be printable without support structures."

  ↓  LLM generates CadQuery (Python) code  ↓

Output: trackball_case.py → trackball_case.3mf → Fabrication
```

---

## Background and Motivation

Three developments have made Vibe Modeling viable.

**1. LLM proficiency in CAD scripting languages.**
Current-generation LLMs demonstrate reliable competency in generating syntactically and geometrically valid CadQuery and OpenSCAD code from natural language specifications. CadQuery is particularly well-suited to this workflow: its Python foundation leverages the language in which LLMs exhibit strongest code generation performance, and its chained API produces readable, auditable output.

**2. Code as an intermediate representation for geometry.**
Mesh-based 3D generation (e.g., diffusion models producing OBJ/STL directly) yields non-parametric, non-editable output. In contrast, code-generated models are inherently parametric. Modifying a single variable propagates changes throughout the entire model. The output of Vibe Modeling is therefore not merely approximate — it is fully engineerable.

**3. The CAD skill gap in the maker community.**
Consumer 3D printers have achieved broad adoption. However, CAD proficiency remains a significant barrier to original design. A substantial portion of the 3D printing community relies on pre-made models from repositories such as Printables and Thingiverse, as the learning curve for traditional CAD software (Fusion 360, SolidWorks, FreeCAD) represents an investment of months to years. Vibe Modeling reduces this barrier to the ability to articulate design intent in natural language.

---

## Technical Architecture

```
┌─────────────────────────────────────────────┐
│  Design Intent (natural language)           │
│  "A ventilated enclosure with rounded edges │
│   for a Raspberry Pi 5, 2.5mm wall thickness│
│   with M3 mounting posts"                   │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  LLM (Claude, etc.)                         │
│  Generates CadQuery Python code             │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  CAD Kernel                                 │
│  CadQuery (OpenCASCADE) → BREP evaluation   │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  Export                                     │
│  STL / 3MF → Slicer → Fabrication          │
└─────────────────────────────────────────────┘
```

### Recommended Stack

| Layer | Selection | Rationale |
|-------|-----------|-----------|
| LLM | Claude (via Claude Code or API) | High-quality Python generation, extended context window |
| CAD Language | CadQuery | Python-native, BREP kernel (OpenCASCADE), native fillet/chamfer operations |
| Execution | Local Python environment | Immediate feedback, full debugging capability |
| Export Format | STL / 3MF | STL for universal compatibility; 3MF when metadata preservation is required |

### On Output Formats

CadQuery supports export to STL, STEP, AMF, and 3MF programmatically via `exporters.export()`. However, CQ-editor's GUI menu exposes only STL and STEP export. In practice, **STL is the primary output format** for Vibe Modeling workflows, as it is universally supported by all slicers and 3D printing toolchains.

For projects requiring unit, color, or material metadata, 3MF export can be invoked directly in the generated script:

```python
from cadquery import exporters
exporters.export(result, "output.3mf")
```

Note that most slicers (PrusaSlicer, Cura, Bambu Studio) accept both formats without issue. STL is the pragmatic default; 3MF is available when its additional capabilities are needed.

---

## Comparison with Traditional CAD Workflows

| Criterion | Traditional CAD | Vibe Modeling |
|-----------|----------------|---------------|
| Input modality | GUI manipulation, parameter entry | Natural language specification |
| Required training | Months to years | Ability to describe design intent |
| Iteration method | Manual feature editing | Conversational refinement |
| Parametric output | Conditional on modeling discipline | Inherent (output is source code) |
| Dimensional precision | Full control | Full control (generated code is editable) |
| Reproducibility | Project file exchange | Prompt + script distribution |

Vibe Modeling does not replace traditional CAD for complex multi-part assemblies, tolerance-critical production engineering, or designs requiring simulation integration. Its primary domain is the broad category of functional parts — enclosures, brackets, adapters, mounts, organizers — that constitute the majority of personal fabrication projects.

---

## Principles

### 1. Specify Function, Not Form

Begin with the object's purpose and constraints rather than its geometry. The LLM infers appropriate geometry from functional requirements.

> "A mount that clips onto a 25mm-diameter tube and retains a GoPro with a standard tripod thread."

### 2. Iterate Conversationally

Refinement should occur in natural language rather than through direct code modification.

> "The clip interference fit is too aggressive. Add 0.5mm of radial clearance. Additionally, apply a 1mm fillet to all external edges."

### 3. Validate All Output

LLMs may generate dimensionally incorrect geometry or produce shapes that are topologically valid but not manufacturable. All output must be validated through visual inspection in a CAD viewer and slicer analysis prior to fabrication.

### 4. Preserve Parametric Structure

Effective prompts produce code with clearly named parameters at the module level — `TRACKBALL_DIAMETER = 34.0`, `WALL_THICKNESS = 2.5`, `FILLET_RADIUS = 1.0` — enabling modification without re-prompting.

### 5. Distribute Prompts Alongside Artifacts

When publishing a Vibe-Modeled design, include the original prompt, the generated source code, and the compiled output (STL/3MF). This enables full reproducibility and modification by downstream users, in contrast to the opaque nature of shared mesh files.

---

## Setup and Initial Workflow

### Environment Preparation

1. Install CadQuery: `conda install -c cadquery cadquery`
2. Install CQ-Editor for interactive preview (optional but recommended)
3. Configure LLM access (Claude via claude.ai, Claude Code, or API)

### Workflow

1. Describe the target geometry to the LLM with dimensional constraints, functional requirements, and manufacturing considerations.
2. Receive generated CadQuery code.
3. Execute locally. Inspect in CQ-Editor or export directly.
4. Export as STL (or 3MF via script if metadata preservation is required).
5. Import into slicer, validate printability, fabricate.
6. If refinement is needed, describe modifications to the LLM and repeat from step 2.

### Example Prompt

> "Write CadQuery code for a desktop phone stand. Requirements: hold a phone at 60 degrees from horizontal, base width of 80mm with sufficient depth for stability, cable routing slot (10mm × 5mm) at the base center, 2mm wall thickness, 1.5mm fillets on all exposed edges. Include STL export."

---

## Future Directions

- **Browser-based real-time preview**: LLM code generation coupled with WebAssembly-compiled CadQuery for immediate in-browser visualization without local installation.
- **Multi-part assembly generation**: Automated tolerance calculation and snap-fit/press-fit joint generation for multi-component designs.
- **Material-aware geometry**: Automatic adjustment of wall thickness, overhang angles, and feature sizes based on specified material properties (PLA, PETG, TPU, resin).
- **Prompt repositories**: Community-maintained libraries of Vibe Modeling prompts as a complement to existing mesh repositories, enabling parametric remixing at the intent level.
- **VR/XR integration**: Spatial preview and evaluation of generated models in VR environments prior to fabrication.

---

## Conclusion

Vibe Modeling is an open methodology, not bound to a specific tool, vendor, or platform. It is a practice that places design intent before implementation detail, making parametric 3D modeling accessible to anyone capable of articulating what they need.

The barrier between idea and physical object has never been thinner.

---

*ORFIZM — 2025*

*#VibeModeling #CadQuery #LLM #AdditiveManufacturing*
