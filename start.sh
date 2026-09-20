#!/bin/bash
set -e

export LD_LIBRARY_PATH="/opt/conda/lib:${LD_LIBRARY_PATH}"
export PETSC_DIR=/opt/conda

if [ $# -gt 0 ]; then
  exec "$@"
fi
