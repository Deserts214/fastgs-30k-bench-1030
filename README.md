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

## Measured (2026-10-30, RTX 4090 24 GB, organizer Module A work dirs, ReSplat PLY init)

| group | scene | FastGS 30000 steps | note |
|---|---|---:|---|
| dl3dv | 001dccbc…5f | **127 s** | 288 train views |
| mipnerf360 | counter | **133 s** | 210 train views |
| hw | billboard | **129 s** | 56 train views |

Machine notes: container has an 11-CPU quota and shares one 4090, so these wall times
include host-side starvation; compare against classic-3DGS 30k on the same host
(dl3dv 568 s, counter 529 s measured here). The bound is iteration-bound, not
scene-bound: all three land at 127-133 s.

Implication for Module B: the budget is ~130 s on every scene. A 6000-update MCMC
run (115-134 s) sits at 87-101% of it, i.e. almost no time credit and one scene
invalid under the strict `<` rule; full time credit (<=10%) allows only ~13 s.
