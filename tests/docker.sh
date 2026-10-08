#!/bin/bash
# Build a test image per distribution and run tests/run.sh in it.
#
#   tests/docker.sh                    all supported distributions
#   tests/docker.sh fedora:latest ...  only these base images

set -uo pipefail

cd "$(dirname "$0")/.." || exit 2

IMAGES=(
    debian:stable-slim
    debian:oldstable-slim
    ubuntu:24.04
    ubuntu:22.04
    archlinux:latest
    fedora:latest
    almalinux:9
    almalinux:10
)
[ "$#" -eq 0 ] || IMAGES=("$@")

failed=()
for image in "${IMAGES[@]}"; do
    tag=en_pl-test:${image//[:\/]/-}
    echo "=== $image"
    if docker build -q -f tests/Dockerfile --build-arg BASE_IMAGE="$image" -t "$tag" . >/dev/null \
        && docker run --rm "$tag"; then
        :
    else
        failed+=("$image")
    fi
    echo
done

if [ "${#failed[@]}" -gt 0 ]; then
    echo "FAILED: ${failed[*]}"
    exit 1
fi
echo "All passed: ${IMAGES[*]}"
