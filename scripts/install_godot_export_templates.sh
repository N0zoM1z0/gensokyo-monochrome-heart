#!/usr/bin/env bash
set -euo pipefail

# Installs the official non-Mono templates matching the engine locked by
# docs/decisions/0002-engine-lock.md. The SHA-256 is the release-asset digest
# published by Godot's official GitHub release API for 4.7.1-stable.
VERSION="4.7.1-stable"
TEMPLATE_VERSION="4.7.1.stable"
ARCHIVE="Godot_v4.7.1-stable_export_templates.tpz"
SHA256="86409db6200b6f8fd3230989c2d2002851f3dd18acf11d7bdbafddf5a0dd0f72"
URL="https://github.com/godotengine/godot/releases/download/${VERSION}/${ARCHIVE}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/gensokyo-monochrome-heart"
TEMPLATE_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/${TEMPLATE_VERSION}"

if [[ "${GMH_USE_CLASH:-0}" == "1" ]]; then
	if [[ ! -f "$HOME/clash.sh" ]]; then
		echo "GMH_USE_CLASH=1 but $HOME/clash.sh does not exist" >&2
		exit 2
	fi
	# shellcheck source=/dev/null
	source "$HOME/clash.sh"
	proxy_on >/dev/null
fi

mkdir -p "$CACHE_DIR" "$TEMPLATE_ROOT"
archive_path="$CACHE_DIR/$ARCHIVE"

if ! [[ -f "$archive_path" ]] || ! printf '%s  %s\n' "$SHA256" "$archive_path" | sha256sum -c --status; then
	curl -fL -C - --retry 8 --retry-all-errors --retry-delay 2 --connect-timeout 20 \
		--silent --show-error -o "$archive_path" "$URL"
fi
printf '%s  %s\n' "$SHA256" "$archive_path" | sha256sum -c -
unzip -tq "$archive_path"
unzip -qo "$archive_path" -d "$TEMPLATE_ROOT"

# The .tpz archive has a top-level templates/ directory, while Godot resolves
# template binaries directly from the version directory.
if [[ -d "$TEMPLATE_ROOT/templates" ]]; then
	shopt -s dotglob nullglob
	for template in "$TEMPLATE_ROOT/templates"/*; do
		mv -f "$template" "$TEMPLATE_ROOT/"
	done
	rmdir "$TEMPLATE_ROOT/templates"
fi

for required in linux_debug.x86_64 linux_release.x86_64; do
	if [[ ! -f "$TEMPLATE_ROOT/$required" ]]; then
		echo "Template archive did not install $required at $TEMPLATE_ROOT" >&2
		exit 1
	fi
done

echo "Installed Godot ${VERSION} export templates at $TEMPLATE_ROOT"
