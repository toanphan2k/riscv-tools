
#!/usr/bin/env bash

set -Eeuo pipefail

DOCKERFILE="Dockerfile"


# Input argument: build context path (default: current directory)
BUILD_CONTEXT="${1:-.}"
BUILD_CONTEXT="$(cd "$BUILD_CONTEXT" && pwd)"

ENV_FILE="${BUILD_CONTEXT}/image.env"

if [[ ! -f "$ENV_FILE" ]]; then
    echo "ERROR: Configuration file not found: $ENV_FILE"
    exit 1
fi

source "$ENV_FILE"

IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"

echo "========================================"
echo " Building RISC-V HDL Docker Image"
echo "========================================"
echo "Image:         ${IMAGE}"
echo "Dockerfile:    ${DOCKERFILE}"
echo "Build context: ${BUILD_CONTEXT}"
echo

# Check Docker availability
if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: Docker is not installed or not in PATH."
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo "ERROR: Docker daemon is not running or permission is denied."
    exit 1
fi

# Validate build context
if [[ ! -d "${BUILD_CONTEXT}" ]]; then
    echo "ERROR: Build context directory does not exist: ${BUILD_CONTEXT}"
    exit 1
fi

# Resolve context to an absolute path
BUILD_CONTEXT="$(cd "${BUILD_CONTEXT}" && pwd)"

# Dockerfile is expected inside the build context
if [[ ! -f "${BUILD_CONTEXT}/${DOCKERFILE}" ]]; then
    echo "ERROR: Dockerfile not found: ${BUILD_CONTEXT}/${DOCKERFILE}"
    exit 1
fi

# Build image
docker build \
    --progress=plain \
    --file "${BUILD_CONTEXT}/${DOCKERFILE}" \
    --tag "${IMAGE}" \
    "${BUILD_CONTEXT}"

echo
echo "Build completed successfully: ${IMAGE}"

echo "Image ready: ${IMAGE}"
