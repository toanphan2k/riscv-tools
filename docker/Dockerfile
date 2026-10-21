
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV RISCV=/opt/riscv

# Install simulator tools and RISC-V GNU toolchain build dependencies
RUN apt-get update && apt-get install -y \
    autoconf \
    automake \
    autotools-dev \
    bc \
    bison \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    device-tree-compiler \
    expect \
    flex \
    gawk \
    g++ \
    gcc \
    git \
    gperf \
    libexpat-dev \
    libglib2.0-dev \
    libgmp-dev \
    libmpc-dev \
    libmpfr-dev \
    libncurses-dev \
    libslirp-dev \
    libtool \
    libzstd-dev \
    make \
    meson \
    ninja-build \
    patchutils \
    perl \
    python3 \
    python3-pip \
    python3-pytest \
    python3-tomli \
    texinfo \
    zlib1g-dev \
    iverilog \
    verilator \
    autoconf \
    && rm -rf /var/lib/apt/lists/*

# Build the RISC-V bare-metal GNU toolchain for RV32IM
# Note: building from source takes considerable time and disk space.
RUN git clone https://github.com/riscv-collab/riscv-gnu-toolchain \
        /tmp/riscv-gnu-toolchain \
    && cd /tmp/riscv-gnu-toolchain \
    && ./configure \
        --prefix="${RISCV}" \
        --with-arch=rv32im \
        --with-abi=ilp32 \
        --disable-linux \
    && make -j4 \
    && rm -rf /tmp/riscv-gnu-toolchain

ENV PATH="${RISCV}/bin:${PATH}"

WORKDIR /workspace

CMD ["bash"]
