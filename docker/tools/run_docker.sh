
#!/usr/bin/env bash
set -Eeuo pipefail

# Defaults
MODE=""
IMAGE=""
PROJECT_DIR="$(pwd)"
CONTAINER_WORKDIR="/workspace"
DEV_CONTAINER_NAME="riscv-hdl-dev"
TEST_CONTAINER_NAME="riscv-hdl-test"

usage() {
    cat <<EOF
Usage:
  $0 --mode <dev|test> --name <image:tag>

Options:
  -h, --help          Show this help message
      --mode MODE     Run mode: dev or test
      --name IMAGE    Docker image name and tag

Examples:
  $0 --mode dev  --name riscv-hdl-tools:latest
  $0 --mode test --name riscv-hdl-tools:latest
  $0 --help

Modes:
  dev   Start an interactive Bash shell
  test  Run ./test/run_tests.sh and exit
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
        *)
            error "Unknown argument: $1"
            usage
            ;;
    esac
done

# Validate arguments
[[ -n "$MODE" ]] || error "Missing required argument: --mode"
[[ -n "$IMAGE" ]] || error "Missing required argument: --name"

case "$MODE" in
    dev|test) ;;
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
)

# Mode-specific arguments
case "$MODE" in
    dev)
        DOCKER_ARGS+=(
            -it
            --volume "${PROJECT_DIR}:${CONTAINER_WORKDIR}"
        )
        DOCKER_CMD=(bash)
        ;;

    test)
        DOCKER_ARGS+=(
            --volume "${PROJECT_DIR}:${CONTAINER_WORKDIR}"
        )
        DOCKER_CMD=(python3 tests/run_tests.py)
        ;;
esac

# Run the container
docker run "${DOCKER_ARGS[@]}" "$IMAGE" "${DOCKER_CMD[@]}"
