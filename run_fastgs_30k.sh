#!/usr/bin/env bash
# Time FastGS 30000 steps on the organizer's three example scenes.
#
# Usage:
#   BASE=/data/ffsplat/official/baseline bash run_fastgs_30k.sh        # all three
#   BASE=... INIT=random bash run_fastgs_30k.sh                        # random init variant
set -uo pipefail

BASE="${BASE:-/data/ffsplat/official/baseline}"
ITERATIONS="${ITERATIONS:-30000}"
INIT="${INIT:-ply}"          # ply | random
OUT="${OUT:-$BASE/results}"
TIMINGS="${TIMINGS:-$PWD/timings.txt}"
SCENES="${SCENES:-dl3dv mipnerf360 hw}"

export PYTHONPATH="$BASE/fastgs:${PYTHONPATH:-}"
export OMP_NUM_THREADS="${OMP_NUM_THREADS:-4}"

cd "$BASE"

for GRP in $SCENES; do
  SCENE=$(python -c "import json;print(json.load(open('scenes.json'))['$GRP']['scene'])")
  WORK="work/$GRP/$SCENE"
  PLY="results/$GRP/$SCENE/resplat/resplat_world.ply"
  RES="$OUT/$GRP/$SCENE/fastgs_${ITERATIONS}_${INIT}"
  if [ ! -f "$WORK/split.json" ]; then echo "SKIP $GRP (no work dir $WORK)"; continue; fi
  if [ -f "$RES/module_b.json" ] && [ "${FORCE:-0}" != "1" ]; then
    echo "SKIP $GRP (already timed: $RES/module_b.json)"; continue
  fi
  if [ "$INIT" = "ply" ] && [ ! -f "$PLY" ]; then echo "SKIP $GRP (no ReSplat PLY)"; continue; fi

  case "$INIT" in
    ply) INIT_ARGS=(--init_ply "$PLY") ;;
    random) INIT_ARGS=(--init_random) ;;
    *) echo "unknown INIT=$INIT" >&2; exit 2 ;;
  esac

  START=$(date +%s)
  python module_b/train_from_ply_fastgs.py -s "$WORK" -m "$RES" --eval -r 1 \
      --sh_degree 3 --iterations "$ITERATIONS" "${INIT_ARGS[@]}" --quiet \
      > "/tmp/fastgs30k-$GRP.log" 2>&1
  RC=$?
  END=$(date +%s)
  LINE="FASTGS30K $GRP $SCENE init=$INIT iters=$ITERATIONS rc=$RC wall=$((END - START))s"
  echo "$LINE" | tee -a "$TIMINGS"
done
