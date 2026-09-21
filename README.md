# LaMEM Container

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.22869618.svg)](https://doi.org/10.5281/zenodo.22869618)

Apptainer container for [LaMEM](https://github.com/UniMainzGeo/LaMEM) 3.1.0 — the Lithosphere and Mantle Evolution Model — with PETSc 3.25.5 on MPICH 5.0.2rc2 (conda build), on Ubuntu 24.04.

This container provides a **LaMEM binary linked against conda MPICH** (not OpenMPI from Julia BinaryBuilder), making it suitable for HPC systems with modern interconnects.

## Why this container

The standard `LaMEM.jl` Julia package downloads pre-compiled binaries linked against OpenMPI (via BinaryBuilder.jl). This container instead installs a purpose-built conda stack, compiled for HPC use (package sources in the `Dockerfile`):

- **LaMEM**: 3.1.0
- **PETSc**: 3.25.5 (MPICH build, no ParMETIS)
- **MPI**: MPICH 5.0.2rc2, `ch4:ucx,ofi` device (supports both UCX InfiniBand and OFI/CXI)
- **Linear algebra**: OpenBLAS, METIS, ScaLAPACK, MUMPS 5.7.3

Nothing is compiled inside the image: the stack is pulled entirely from pre-built conda packages, so the image builds in roughly 15 minutes.

## Quick start

### Build locally

```bash
docker build -t lamem .
```

### Run a simple test

```bash
# Check LaMEM binary is linked against MPICH (not OpenMPI)
docker run --rm lamem sh -c 'ldd /opt/conda/bin/lamem | grep -i mpi'
# Should show: libmpi.so.0 => /opt/conda/lib/libmpi.so.0
```

### Run with MPI (parallel)

```bash
# Run with 4 MPI processes
docker run --rm \
  -v /path/to/LaMEM/examples:/opt/examples \
  lamem bash -c 'source /opt/start.sh; \
  mpirun -n 4 lamem -ParamFile /opt/examples/BuiltInSetups/FallingBlock_Multigrid.dat -nstep_max 1'
```

More granular control of the number of ranks on a single host:

```bash
docker run --rm \
  -v "$PWD:/output" -w /output \
  ghcr.io/j34ni/lamem-container/lamem:latest \
  bash -c 'source /opt/start.sh; \
  mpirun -n 4 lamem -ParamFile /opt/examples/BuiltInSetups/FallingBlock_Multigrid.dat -nstep_max 10'
```

## HPC jobs (SLURM + Apptainer)

On systems such as [Olivia](https://documentation.sigma2.no/hpc_machines/olivia.html), pull the
image from GitHub Container Registry and submit the included job scripts:

```bash
apptainer pull docker://ghcr.io/j34ni/lamem-container/lamem:latest
sbatch job-1-node.sh    # 4 ranks on 1 node   (partition small)
sbatch job-2-nodes.sh   # 4 ranks on 2 nodes  (partition large)
```

Both scripts bind the current directory to `/opt/uio` (`APPTAINER_BIND="${PWD}:/opt/uio"`) and rely on
`srun --mpi=pmi2` as the MPI launcher.

Notes:
- The `-ParamFile` option must be space-separated (`-ParamFile <file>`), together with `-nstep_max <n>`,
  or PETSc reports the options as unused.
- Inside a container the CMA transport is unavailable: the job scripts export
  `MPIR_CVAR_CH4_CMA_ENABLE=0` (required, or MPICH aborts on first collective).
- On Olivia, multi-node runs must set `MPICH_CH4_NETMOD=ofi` and `FI_PROVIDER=cxi`, as
  communications go through the network.

## Benchmark results

Model: `FallingBlock_Multigrid.dat` (32³ grid, 10 steps), 4 MPI ranks, conda-based MPICH image
(LaMEM 3.1.0 / PETSc 3.25.5 / MPICH 5.0.2rc2 `ch4:ucx,ofi`).
`Total solution time` as reported by LaMEM:

| Platform | 1 node | 2 nodes |
|----------|-------:|--------:|
| 32-core VM (Docker, this repo) | 11.98s | *n/a* |
| Olivia, x86 | 14.63s (job 2295756) | 13.02s (job 2295907) |

Olivia jobs used SLURM + Apptainer (OFI/CXI over Slingshot,
`srun --mpi=pmi2`), exited normally (status 0) and produced identical `FB_multigrid` /
`FB_multigrid_phase` VTK output.

## ParMETIS note

ParMETIS is not included in the PETSc package due to its non-commercial redistribution license.
Scotch is under the more permissive CeCILL-C license (commercial use allowed, with attribution and
share-alike of modifications to Scotch itself), but it is not part of this build either. Users who
want either can rebuild the `petsc` conda package by adding `--download-parmetis` or
`--download-scotch` to the PETSc configure step in its recipe.

## Files

- `Dockerfile` — container recipe (installs the pre-built conda stack)
- `start.sh` — container entrypoint with environment setup
- `CITATION.cff` — citation metadata (DOI via Zenodo)
- `LICENSE` — MIT
- `job-1-node.sh` — SLURM job: 4 ranks on 1 node (partition `small`)
- `job-2-nodes.sh` — SLURM job: 4 ranks on 2 nodes (partition `large`)
- `bench/` — local benchmark outputs / logs (git-ignored)

## References

- LaMEM: https://github.com/UniMainzGeo/LaMEM
- LaMEM.jl: https://juliageodynamics.github.io/LaMEM.jl/
- PETSc: https://petsc.org
- MPICH: https://www.mpich.org

## Citation

If you use this container in your research, please cite:

```bibtex
@software{lamem_container,
  author = {Iaquinta, Jean},
  title = {LaMEM Container Environment},
  version = {0.1.0},
  year = {2026},
  doi = {10.5281/zenodo.22869619},
  url = {https://github.com/j34ni/lamem-container},
}
```
