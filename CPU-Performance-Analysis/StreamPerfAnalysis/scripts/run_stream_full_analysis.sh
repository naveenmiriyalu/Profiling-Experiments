#!/usr/bin/env bash
set -euo pipefail

# End-to-end GNR STREAM analysis:
# build + metadata + core sweep + long Triad + TMA + CAS + PCM.
#
# Example:
#   bash run_stream_full_analysis.sh --pcm-bin-dir /opt/pcm/build/bin

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$SCRIPT_DIR/run_stream_analysis.sh" all "$@"
