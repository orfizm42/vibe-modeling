"""Vibe Modeling テストスクリプト: シンプルな箱"""
import cadquery as cq

# パラメータ（Vibe Modelingの原則4: パラメトリック構造を維持）
WIDTH = 30.0
DEPTH = 20.0
HEIGHT = 10.0
FILLET_RADIUS = 2.0
HOLE_DIAMETER = 8.0

# モデル生成
result = (
    cq.Workplane("XY")
    .box(WIDTH, DEPTH, HEIGHT)
    .faces(">Z")
    .workplane()
    .hole(HOLE_DIAMETER)
    .edges("|Z")
    .fillet(FILLET_RADIUS)
)

# バウンディングボックスで実寸を計算
bb = result.val().BoundingBox()
actual_x = bb.xmax - bb.xmin
actual_y = bb.ymax - bb.ymin
actual_z = bb.zmax - bb.zmin

# STLエクスポート
stl_path = "/work/output/test-box.stl"
cq.exporters.export(result, stl_path)

# 結果表示
print(f"Exported: {stl_path}")
print(f"")
print(f"=== Dimensions ===")
print(f"  X: {actual_x:.2f} mm")
print(f"  Y: {actual_y:.2f} mm")
print(f"  Z: {actual_z:.2f} mm")
print(f"  Bounding Box: {actual_x:.2f} x {actual_y:.2f} x {actual_z:.2f} mm")
print(f"")
print(f"=== Parameters ===")
print(f"  Fillet: {FILLET_RADIUS} mm")
print(f"  Hole: {HOLE_DIAMETER} mm")
