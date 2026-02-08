#!/bin/bash
set -euo pipefail

# === Vibe Modeling Runner ===
# Usage: ./vibe.sh [--preview] <script.py>
# CadQueryスクリプトをコンテナ内で実行し、output/ にSTLを出力する

IMAGE_NAME="vibe-modeling"
PREVIEW=false

# --- オプション解析 ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --preview|-p)
            PREVIEW=true
            shift
            ;;
        -h|--help)
            echo "Usage: ./vibe.sh [OPTIONS] <cadquery-script.py>"
            echo ""
            echo "Options:"
            echo "  -p, --preview   STL生成後にf3dで自動プレビュー"
            echo "  -h, --help      このヘルプを表示"
            echo ""
            echo "Examples:"
            echo "  ./vibe.sh examples/test-box.py"
            echo "  ./vibe.sh --preview examples/test-box.py"
            exit 0
            ;;
        -*)
            echo "Error: Unknown option: $1"
            echo "Run './vibe.sh --help' for usage"
            exit 1
            ;;
        *)
            SCRIPT="$1"
            shift
            ;;
    esac
done

# --- 引数チェック ---
if [ -z "${SCRIPT:-}" ]; then
    echo "Error: No script specified"
    echo "Usage: ./vibe.sh [--preview] <cadquery-script.py>"
    exit 1
fi

if [ ! -f "$SCRIPT" ]; then
    echo "Error: File not found: $SCRIPT"
    exit 1
fi

# --- コンテナランタイムを自動検出 (podman優先) ---
if command -v podman &> /dev/null; then
    RUNTIME="podman"
elif command -v docker &> /dev/null; then
    RUNTIME="docker"
else
    echo "Error: podman or docker is required"
    exit 1
fi

# --- outputディレクトリ作成 ---
mkdir -p output

# --- イメージが未ビルドならビルド ---
if ! $RUNTIME image exists "$IMAGE_NAME" 2>/dev/null; then
    echo "Building $IMAGE_NAME image (initial build takes a few minutes)..."
    $RUNTIME build -t "$IMAGE_NAME" .
fi

# --- 実行 ---
echo "Running: $SCRIPT"
$RUNTIME run --rm \
    -v "$(pwd)/$SCRIPT:/work/input.py:ro" \
    -v "$(pwd)/output:/work/output:Z" \
    "$IMAGE_NAME" \
    /work/input.py

echo ""
echo "Done. Check output/ for results."

# --- プレビュー ---
if [ "$PREVIEW" = true ]; then
    # output/ 内の最新STLファイルを開く
    LATEST_STL=$(find output/ -name '*.stl' -printf '%T@ %p\n' 2>/dev/null \
        | sort -n | tail -1 | cut -d' ' -f2-)

    if [ -z "$LATEST_STL" ]; then
        echo "Warning: No STL files found in output/"
        exit 0
    fi

    if ! command -v f3d &> /dev/null; then
        echo "Warning: f3d not found. Install it for preview: https://f3d.app"
        echo "  File: $LATEST_STL"
        exit 0
    fi

    echo "Opening preview: $LATEST_STL"
    f3d "$LATEST_STL" &
fi
