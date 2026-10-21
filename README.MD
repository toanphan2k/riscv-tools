# RISC-V Development Tools

`rv_tools` provides a shared Docker environment for building and working with
RISC-V software and hardware projects. The image includes a bare-metal RISC-V
GNU toolchain configured for RV32IM, along with Icarus Verilog and Verilator
for RTL simulation.

The container is intended to be used with the projects in this workspace,
including the RV32IM core and the RISC-V test sources. The workspace is mounted
into the container when you start development mode, so edits made on the host
are available inside the container.

## Included tools

- RISC-V GNU bare-metal toolchain, built from source with RV32IM/ILP32 defaults
  and installed under `/opt/riscv`
- Icarus Verilog (`iverilog`) and Verilator
- Ubuntu 24.04 build environment and dependencies for the toolchain
- Docker scripts for building the image and starting a development container
- A Python/YAML-based test runner and sample C test under `docker/tests/`

The image does not currently install Spike, QEMU, or other RISC-V instruction
set simulators. Icarus Verilog and Verilator are HDL simulators for the RTL.

## Requirements

- Docker Engine (or a compatible Docker installation) with a running daemon
- Bash to run the helper scripts
- Internet access when building the image, to download the GNU toolchain source
- Sufficient time, disk space, and memory for a source build of the toolchain

## Build the Docker image

From the workspace root:

```bash
bash ./rv_tools/docker/tools/build_docker.sh ./rv_tools/docker
```

The script reads the image name and tag from
[`docker/image.env`](docker/image.env), then builds using
[`docker/Dockerfile`](docker/Dockerfile). The default image is
`riscv-tools:0.1`.

## Start a development container

Run this from the workspace directory you want to make available inside the
container. For example, from the workspace root:

```bash
./rv_tools/docker/tools/run_docker.sh \
  --mode dev \
  --name riscv-tools:0.1
```

The current directory is mounted at `/workspace`, and the container opens an
interactive Bash shell. For example, to compile a freestanding RV32IM program:

```bash
riscv64-unknown-elf-gcc \
  -march=rv32im -mabi=ilp32 \
  -ffreestanding -nostdlib \
  -Wl,-e,main \
  -o program.elf path/to/program.c
```

Use `iverilog` or `verilator` from the same shell to compile and simulate RTL.
The exact commands depend on the testbench and simulator options used by each
project.

To see the script's supported arguments:

```bash
./rv_tools/docker/tools/run_docker.sh --help
```

## Build the RISC-V ISA tests

From either the workspace root (containing `riscv-tests/`) or the `rv_tools/`
directory, run:

```bash
./docker/tools/run_docker.sh --build-test
```

When run from the workspace root, use:

```bash
./rv_tools/docker/tools/run_docker.sh --build-test
```

This starts `toan_test:lastest`, mounts the workspace at `/workspace`,
initializes the `riscv-tests` Git submodules (including the environment headers),
then builds only the RV32 user-level integer (`rv32ui`) and multiply/divide
(`rv32um`) ISA test groups using `-march=rv32im_zicsr_zifencei -mabi=ilp32`.
`Zicsr` is needed by the harness, and
`Zifencei` is needed by the `fence_i` test. The generated programs therefore
require both extensions in addition to RV32IM to run. This does not build
benchmarks, floating-point tests, or other ISA groups. Generated test binaries
are written under `riscv-tests/isa/` in the mounted workspace. The image must
already be available locally, and the container needs network access to fetch
submodules that have not been initialized yet.

## Test tooling

`run_test.py` is a Python test helper that loads YAML test definitions and
checks command results against regular expressions. Sample C and YAML test
inputs are in `docker/tests/`.

The Docker runner's `--mode test` entry point currently refers to
`tests/run_tests.py`, which is not present in this project tree. Use development
mode for now; the test-mode integration needs to be aligned with the existing
runner and test files before it can be used.

## Directory layout

```text
rv_tools/
├── docker/
│   ├── Dockerfile          # Toolchain and simulator image definition
│   ├── image.env           # Docker image name and tag
│   ├── tools/              # Image build and container run scripts
│   └── tests/              # Sample C program and YAML test cases
├── run_test.py             # YAML-driven test helper
└── README.MD
```