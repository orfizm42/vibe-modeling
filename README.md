# Vibe Modeling

自然言語 → CadQuery → STL。作りたいものを言葉で伝えれば、印刷可能な3Dモデルが手に入ります。

```
あなた: "30x20x10mmの箱、角にR2フィレット、天面にφ8の穴"

  ↓ LLMがCadQueryコードを生成 ↓

=== 寸法 ===
  X: 30.00 mm
  Y: 20.00 mm
  Z: 10.00 mm
```

**Vibe Modeling（バイブモデリング）** とは、自然言語の指示をLLMに与えてパラメトリック3Dモデルを生成する手法です。LLMが人間の意図を実行可能な [CadQuery](https://github.com/CadQuery/cadquery) コードに変換し、製造可能なジオメトリを出力します。

## クイックスタート

### 前提条件

- [Podman](https://podman.io/) または [Docker](https://www.docker.com/)
- [f3d](https://f3d.app/)（任意、プレビュー用）

### 実行

```bash
git clone https://github.com/orfizm42/vibe-modeling.git
cd vibe-modeling
chmod +x vibe.sh

# STL生成（初回はコンテナイメージのビルドに約2分）
./vibe.sh projects/test-box.py

# 生成 + f3dでプレビュー
./vibe.sh --preview projects/test-box.py
```

出力は `output/` に保存されます。

## 仕組み

```
┌──────────────────────────┐
│  設計意図                 │ 自然言語のプロンプトを
│  （部品を言葉で記述）        │ Claude、ChatGPTなどに入力
└────────────┬─────────────┘
             ▼
┌──────────────────────────┐
│  LLM                     │  CadQuery Pythonコードを生成
└────────────┬─────────────┘
             ▼
┌──────────────────────────┐
│  vibe.sh                 │  コンテナ内でスクリプトを実行
│  (Podman/Docker)         │  ローカル環境へのインストール不要
└────────────┬─────────────┘
             ▼
┌──────────────────────────┐
│  output/*.stl            │  スライサー/プリンターで使用可能
│  + ターミナルに寸法表示     │  寸法は標準出力に表示
└──────────────────────────┘
```

コンテナにCadQuery + OpenCASCADEが同梱されているため、Podman/Docker以外のインストールは不要です。

## 使い方

```
./vibe.sh [オプション] <cadquery-script.py>

オプション:
  -p, --preview   エクスポート後にf3dでSTLを表示
  -h, --help      ヘルプを表示
```

### スクリプトの書き方

LLMにCadQueryスクリプトの生成を依頼し、`projects/` ディレクトリに保存してください。主な規約：

1. **パラメータはファイル先頭に** — `WIDTH = 30.0`, `WALL_THICKNESS = 2.5`
2. **`/work/output/` にエクスポート** — `cq.exporters.export(result, "/work/output/name.stl")`
3. **寸法を出力** — `BoundingBox()` で検証

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

### 結果の確認

寸法はターミナルに出力されます。視覚的な確認には：

```bash
# f3d（推奨 — 軽量・高速）
f3d output/box.stl

# f3dの便利なホットキー
# H     — 全ホットキーを表示
# E     — エッジ表示の切替
# G     — グリッドの切替
# X     — 軸の切替
# Enter — カメラリセット
# F12   — スクリーンショット
```

## プロジェクト構成

```
vibe-modeling/
├── Containerfile       # CadQueryコンテナのレシピ
├── vibe.sh             # ワンコマンドランナー
├── projects/           # CadQueryスクリプト置き場
│   └── test-box.py     # サンプル: フィレットと穴のある箱
├── output/             # 生成されたSTL（gitignore対象）
├── skill/
│   └── SKILL.md        # Claude Skill定義
├── manifesto/
│   ├── en.md           # マニフェスト（英語）
│   └── ja.md           # マニフェスト（日本語）
└── README.md
```

`projects/` にCadQueryスクリプトを配置することで、ツールキット本体のファイルと作業ファイルが混在しません。

## 原則

1. **形ではなく機能を指定する** — 部品が何をするかを記述し、描き方は指示しない(指定した方が良い結果を生むこともあるので参考程度)
2. **会話的に反復する** — コードを編集するのではなく、LLMとの対話で改善する
3. **すべての出力を検証する** — 印刷前に寸法と形状を必ず確認する
4. **パラメトリック構造を維持する** — マジックナンバーではなく名前付きパラメータをファイル先頭に
5. **プロンプトを成果物と共に配布する** — モデルを生成したプロンプトを共有する

詳細は [マニフェスト (JA)](manifesto/ja.md) / [Manifesto (EN)](manifesto/en.md) を参照してください。

## 動作要件

| コンポーネント | 必須 | 用途 |
|-----------|----------|---------|
| Podman または Docker | ✅ | コンテナランタイム |
| f3d | 任意 | STLプレビューア |
| スライサー (PrusaSlicer等) | 任意 | 印刷準備 |

ホストにPython、Conda、CadQueryのインストールは不要です。

## ライセンス

[MIT](LICENSE)

---

<details>
<summary><strong> English</strong></summary>

# Vibe Modeling

Natural language → CadQuery → STL. Describe what you want, get a printable model.

```
You: "30x20x10mm box, R2 fillet on edges, φ8 hole on top"

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
./vibe.sh projects/test-box.py

# Generate + preview in f3d
./vibe.sh --preview projects/test-box.py
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

Ask your LLM to generate a CadQuery script and save it in the `projects/` directory. Key conventions:

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
├── projects/           # CadQuery scripts go here
│   └── test-box.py     # Sample: box with fillet and hole
├── output/             # Generated STLs (gitignored)
├── skill/
│   └── SKILL.md        # Claude Skill definition
├── manifesto/
│   ├── en.md           # Manifesto (English)
│   └── ja.md           # Manifesto (Japanese)
└── README.md
```

Place CadQuery scripts in `projects/` to keep them separate from toolkit files.

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

</details>
