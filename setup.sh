#!/usr/bin/env bash
# Fetch FastGS upstream and build its CUDA rasterizer extension.
#
# The organizer bundle ships only the Python wrappers in baseline/fastgs; the
# `diff_gaussian_rasterization_fastgs` package must come from FastGS upstream.
set -euo pipefail

FASTGS_REPO="${FASTGS_REPO:-https://github.com/fastgs/FastGS.git}"
SRC="${FASTGS_SRC:-$PWD/_fastgs}"

export CUDA_HOME="${CUDA_HOME:-/usr/local/cuda}"
export TORCH_CUDA_ARCH_LIST="${TORCH_CUDA_ARCH_LIST:-8.9}"
export MAX_JOBS="${MAX_JOBS:-8}"

echo "[setup] cloning $FASTGS_REPO -> $SRC"
if [ ! -d "$SRC/.git" ]; then
  git clone --depth 1 "$FASTGS_REPO" "$SRC"
fi

echo "[setup] submodules"
git -C "$SRC" submodule update --init --recursive --depth 1 || true

echo "[setup] patching missing <cstdint> includes (GCC 13+ no longer transitively includes it)"
RASTER_DIR="$(dirname "$(find "$SRC/submodules" -name setup.py -path '*rasterization*' | head -1)")"
for f in "$RASTER_DIR"/cuda_rasterizer/*.h "$RASTER_DIR"/cuda_rasterizer/*.cu; do
  [ -f "$f" ] || continue
  grep -q cstdint "$f" || sed -i '1i #include <cstdint>' "$f"
done

echo "[setup] building rasterizer"
shopt -s nullglob
built=0
for candidate in "$SRC"/submodules/*rasterization* "$SRC"/*rasterization* "$SRC"/submodules/simple-knn; do
  [ -d "$candidate" ] || continue
  echo "[setup] pip install --no-build-isolation $candidate"
  python -m pip install -q --no-build-isolation "$candidate" || echo "[setup] WARN build failed: $candidate"
  built=1
done
if [ "$built" -eq 0 ]; then
  echo "[setup] no rasterizer source found under $SRC" >&2
  exit 1
fi

python - <<'PY'
try:
    import diff_gaussian_rasterization_fastgs as m
    print("[setup] OK", m.__file__)
except Exception as exc:  # noqa: BLE001
    raise SystemExit(f"[setup] import failed: {exc}")
PY

