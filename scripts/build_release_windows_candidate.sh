#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GMH_RELEASE_PLATFORM=windows "$PROJECT_ROOT/scripts/build_release_candidate.sh"
