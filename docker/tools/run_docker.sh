
#!/usr/bin/env bash
set -Eeuo pipefail

# Defaults
MODE=""
IMAGE=""
BUILD_TEST=false
PROJECT_DIR="$(pwd)"
CONTAINER_WORKDIR="/workspace"
BUILD_TEST_IMAGE="toan_test:lastest"

usage() {
    cat <<EOF
Usage:
  $0 --mode <dev|test> --name <image:tag>
  $0 --build-test

Options:
  -h, --help          Show this help message
      --mode MODE     Run mode: dev or test
      --name IMAGE    Docker image name and tag
      --build-test    Build RV32 RISC-V tests using ${BUILD_TEST_IMAGE}

Examples:
  $0 --mode dev  --name riscv-hdl-tools:latest
  $0 --mode test --name riscv-hdl-tools:latest
  $0 --build-test
  $0 --help

Modes:
  dev   Start an interactive Bash shell
  test  Run python3 tests/run_tests.py and exit
  --build-test builds the tests in ../riscv-tests (or ./riscv-tests)
EOF
}

error() {
    echo "ERROR: $*" >&2
    echo "Use '$0 --help' for usage." >&2
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --mode)
            [[ $# -ge 2 ]] || error "--mode requires a value"
            MODE="$2"
            shift 2
            ;;
        --name)
            [[ $# -ge 2 ]] || error "--name requires an image:tag value"
            IMAGE="$2"
            shift 2
            ;;
        --build-test)
            BUILD_TEST=true
            shift
            ;;
        *)
            error "Unknown argument: $1"
            usage
            ;;
    esac
done

if [[ "$BUILD_TEST" == true ]]; then
    [[ -z "$MODE" && -z "$IMAGE" ]] ||
        error "--build-test cannot be combined with --mode or --name"
    MODE="build-test"
    IMAGE="$BUILD_TEST_IMAGE"

    if [[ ! -d "${PROJECT_DIR}/riscv-tests" &&
          -d "${PROJECT_DIR}/../riscv-tests" ]]; then
        PROJECT_DIR="$(cd "${PROJECT_DIR}/.." && pwd)"
    fi

    [[ -d "${PROJECT_DIR}/riscv-tests" ]] ||
        error "Could not find riscv-tests in ${PROJECT_DIR} or its parent directory."
fi

# Validate arguments
[[ -n "$MODE" ]] || error "Missing required argument: --mode"
[[ -n "$IMAGE" ]] || error "Missing required argument: --name"

case "$MODE" in
    dev|test|build-test) ;;
    *) error "Invalid mode '$MODE'. Choose dev or test." ;;
esac

# Check Docker availability
command -v docker >/dev/null 2>&1 ||
    error "Docker is not installed or not in PATH."

docker info >/dev/null 2>&1 ||
    error "Docker daemon is not running or permission is denied."

# Check local image
docker image inspect "$IMAGE" >/dev/null 2>&1 ||
    error "Docker image not found locally: $IMAGE. Build or pull it first."

# Common Docker arguments
DOCKER_ARGS=(
    --rm
    --workdir "$CONTAINER_WORKDIR"
    --volume "${PROJECT_DIR}:${CONTAINER_WORKDIR}"
)

# Mode-specific arguments
case "$MODE" in
    dev)
        DOCKER_ARGS+=(-it)
        DOCKER_CMD=(bash)
        ;;

    test)
        DOCKER_CMD=(python3 tests/run_tests.py)
        ;;

    build-test)
        DOCKER_CMD=(
            bash -lc
            'cd /workspace/riscv-tests &&
             git submodule update --init --recursive &&
             ./configure --prefix="${RISCV:-/opt/riscv}/target" --with-xlen=32 &&
             make ABI=ilp32 &&
             make ABI=ilp32 install'
        )
        ;;
esac

# Run the container
docker run "${DOCKER_ARGS[@]}" "$IMAGE" "${DOCKER_CMD[@]}"
