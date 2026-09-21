#!/usr/bin/env bash
set -euo pipefail

# Build the latest Intel Performance Counter Monitor (PCM) from source.
#
# Usage:
#   ./build_intel_pcm.sh [source-directory]
#
# Example:
#   ./build_intel_pcm.sh "$HOME/src/intel-pcm"
#
# Install RHEL build dependencies first:
#   sudo dnf install -y git cmake gcc gcc-c++ make libasan

PCM_SOURCE_DIR="${1:-${PWD}/intel-pcm}"
PCM_REPOSITORY="https://github.com/intel/pcm.git"
BUILD_JOBS="${BUILD_JOBS:-$(nproc)}"

for command_name in git cmake; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Error: required command '$command_name' was not found." >&2
        echo "Install dependencies with:" >&2
        echo "  sudo dnf install -y git cmake gcc gcc-c++ make libasan" >&2
        exit 1
    fi
done

if [[ -e "$PCM_SOURCE_DIR" ]]; then
    echo "Error: destination already exists: $PCM_SOURCE_DIR" >&2
    echo "Choose another directory or update the existing checkout manually." >&2
    exit 1
fi

echo "Cloning Intel PCM into: $PCM_SOURCE_DIR"
git clone --recursive "$PCM_REPOSITORY" "$PCM_SOURCE_DIR"

echo "Configuring release build..."
cmake     -S "$PCM_SOURCE_DIR"     -B "$PCM_SOURCE_DIR/build"     -DCMAKE_BUILD_TYPE=Release

echo "Building with $BUILD_JOBS parallel jobs..."
cmake --build "$PCM_SOURCE_DIR/build" --parallel "$BUILD_JOBS"

echo
echo "Intel PCM build completed."
echo "Binaries: $PCM_SOURCE_DIR/build/bin"
echo "Git revision: $(git -C "$PCM_SOURCE_DIR" rev-parse HEAD)"
"$PCM_SOURCE_DIR/build/bin/pcm-memory" --version || true
