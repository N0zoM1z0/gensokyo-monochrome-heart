#!/usr/bin/env bash
set -euo pipefail

VERSION="4.7.1-stable"
ARCHIVE="Godot_v4.7.1-stable_linux.x86_64.zip"
SHA512="4ccdab7a48eeccbe8819a2fc1f6262f8d72065d98601bcb3743fcbd7ebd39f373758a788ee3293a05ec5b2c48538266c437404312e372225cd2df273945a2de9"
URL="https://github.com/godotengine/godot/releases/download/${VERSION}/${ARCHIVE}"
INSTALL_ROOT="${GMH_GODOT_INSTALL_ROOT:-$HOME/.local/opt/godot-${VERSION}}"
BIN_DIR="${GMH_GODOT_BIN_DIR:-$HOME/.local/bin}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/gensokyo-monochrome-heart"

if [[ "${GMH_USE_CLASH:-0}" == "1" ]]; then
	if [[ ! -f "$HOME/clash.sh" ]]; then
		echo "GMH_USE_CLASH=1 but $HOME/clash.sh does not exist" >&2
		exit 2
	fi
	# shellcheck source=/dev/null
	source "$HOME/clash.sh"
	proxy_on >/dev/null
fi

mkdir -p "$CACHE_DIR" "$INSTALL_ROOT" "$BIN_DIR"
archive_path="$CACHE_DIR/$ARCHIVE"

curl -fL -C - --retry 8 --retry-all-errors --retry-delay 2 --connect-timeout 20 \
	--silent --show-error -o "$archive_path" "$URL"
printf '%s  %s\n' "$SHA512" "$archive_path" | sha512sum -c -
unzip -tq "$archive_path"
unzip -qo "$archive_path" -d "$INSTALL_ROOT"
chmod 0755 "$INSTALL_ROOT/Godot_v4.7.1-stable_linux.x86_64"
ln -sfn "$INSTALL_ROOT/Godot_v4.7.1-stable_linux.x86_64" "$BIN_DIR/godot"

actual_version="$($BIN_DIR/godot --version)"
expected_version="4.7.1.stable.official.a13da4feb"
if [[ "$actual_version" != "$expected_version" ]]; then
	echo "Unexpected Godot version: $actual_version (expected $expected_version)" >&2
	exit 1
fi

echo "Installed Godot $actual_version at $INSTALL_ROOT"
