# fastgs-30k-bench-1030

Timing bench for the competition's Module B time bound: **FastGS 30000 steps** on the
organizer's three example scenes, measured on the execution host.

The bound is a wall-clock budget, so every scene is timed end to end inside the
FastGS training loop (scene load, init, training, save) and reported as
`FASTGS30K <group> <scene> wall=<seconds>`.

## Protocol

- Scenes and work directories come from the organizer bundle Module A output:
  - `DL3DV/001dccbc1f78146a9f03861026613d8e73f39f372b545b26118e37a23c740d5f`
  - `mipnerf360/counter`
  - `hw/billboard`
- Same `split.json`, same resolution, same train views as the pipeline.
- Initialization: the ReSplat world PLY (`results/<group>/<scene>/resplat/resplat_world.ply`),
  i.e. exactly what Module B starts from; `--init_random` timings are recorded
  separately if requested.
- 30000 iterations, `--sh_degree 3`, `--eval -r 1`, FastGS defaults otherwise.
- One warm run is not counted; each scene is timed once and the raw wall time is kept.

## Layout

```
setup.sh            fetch FastGS upstream and build diff_gaussian_rasterization_fastgs
run_fastgs_30k.sh   time FastGS 30000 steps on the three scenes -> timings.txt
```

Datasets, checkpoints and the compiled extensions stay outside Git.

## Usage

```bash
bash setup.sh
BASE=/data/ffsplat/official/baseline bash run_fastgs_30k.sh
cat timings.txt
```
