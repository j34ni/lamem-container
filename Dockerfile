FROM ubuntu:24.04
ENV TZ="Europe/Oslo"
ENV PATH="/opt/conda/bin:/opt/julia-1.10.0/bin:$PATH"
SHELL ["/bin/bash", "-c"]

RUN apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  ca-certificates tzdata wget tar \
  && rm -rf /var/lib/apt/lists/*

RUN wget -q -nc --no-check-certificate -P /var/tmp \
  https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh \
  && bash /var/tmp/Miniforge3-Linux-x86_64.sh -b -p /opt/conda \
  && rm /var/tmp/Miniforge3-Linux-x86_64.sh

# Conda stack from the j34ni channel (MPICH 5.0.2rc2 ch4:ucx,ofi + nemesis, PETSc 3.25.5, LaMEM 3.1.0)
RUN source /opt/conda/etc/profile.d/conda.sh && \
  mamba install -y -c https://conda.anaconda.org/j34ni -c conda-forge \
  "mpich=5.0.2rc2=h14436af_1" \
  "mumps-mpi=5.7.3=h44b613e_3" \
  "scalapack=2.2.0=hcbf1af9_0" \
  "petsc=3.25.5=real_h799bd82_0" \
  "lamem=3.1.0=hc64fb75_0" \
  python=3.12 \
  numpy \
  scipy \
  && conda clean -afy

RUN wget -q -nc --no-check-certificate \
  https://julialang-s3.julialang.org/bin/linux/x64/1.10/julia-1.10.0-linux-x86_64.tar.gz \
  -O /tmp/julia.tar.gz \
  && tar -xzf /tmp/julia.tar.gz -C /opt \
  && rm /tmp/julia.tar.gz

RUN source /opt/conda/etc/profile.d/conda.sh && \
  julia -e 'using Pkg; Pkg.add("LaMEM")' && \
  rm -rf /root/.julia/compiled && \
  rm -rf /tmp/*

RUN JLL_BIN=$(find /root/.julia/artifacts -name "LaMEM" -path "*/bin/LaMEM" | head -1) && \
  cp /opt/conda/bin/lamem "$JLL_BIN"

RUN ln -s /opt/conda/bin/lamem /opt/lamem

ENV PETSC_DIR=/opt/conda
ENV LD_LIBRARY_PATH="/opt/conda/lib"
ENV PATH="/opt/conda/bin:/opt/julia-1.10.0/bin:$PATH"

COPY start.sh /opt/start.sh
RUN chmod +x /opt/start.sh

CMD ["/opt/start.sh"]
