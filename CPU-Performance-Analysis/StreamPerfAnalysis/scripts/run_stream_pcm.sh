#!/usr/bin/env bash
set -euo pipefail

# Example:
#   bash run_stream_pcm.sh --pcm-bin-dir /opt/pcm/build/bin

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$SCRIPT_DIR/run_stream_analysis.sh" pcm "$@"
