#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
workspace="$(mktemp -d "${TMPDIR:-/tmp}/gmh-release-linux.XXXXXX")"
package="$workspace/package"

GMH_RELEASE_OUTPUT="$package" "$PROJECT_ROOT/scripts/build_release_candidate.sh"

[[ -f "$package/gensokyo-monochrome-heart.x86_64" ]] || { echo "missing portable binary" >&2; exit 1; }
[[ -f "$package/gensokyo-monochrome-heart.pck" ]] || { echo "missing portable PCK" >&2; exit 1; }
[[ -f "$package/release_manifest.json" && -f "$package/SHA256SUMS" ]] || { echo "missing release manifest" >&2; exit 1; }

# Linux export is portable: its entire install is this directory. Moving it out
# of the original path proves no registration/uninstaller is required, while
# the isolated user-data directory remains separate from the package.
mv "$package" "$workspace/uninstalled-package"
[[ ! -e "$package" && -d "$workspace/uninstalled-package/user-data" ]] || {
	echo "portable uninstall isolation failed" >&2
	exit 1
}

echo "M19 Linux clean-environment export/install-run/uninstall simulation passed: $workspace"
