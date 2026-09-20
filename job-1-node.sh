#!/bin/bash
#SBATCH --job-name=lamem-1node
#SBATCH --account=nn9997k
#SBATCH --time=01:30:00
#SBATCH --partition=small
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=2G
#SBATCH --output=lamem-1node-%j.out
#SBATCH --error=lamem-1node-%j.err

set -o errexit
set -o nounset

export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export UCX_POSIX_USE_PROC_LINK=n
export MPIR_CVAR_CH4_CMA_ENABLE=0
export APPTAINER_QUIET=1

IMAGE="${PWD}/lamem_latest.sif"
export APPTAINER_BIND="${PWD}:/opt/uio"

echo "Nodes: ${SLURM_NODELIST}"
echo "Ranks: ${SLURM_NTASKS}"

srun -n $SLURM_NTASKS --mpi=pmi2 apptainer exec ${IMAGE} bash -c "source /opt/start.sh && exec /opt/lamem -ParamFile /opt/uio/LaMEM/examples/BuiltInSetups/FallingBlock_Multigrid.dat -nstep_max 10"
