#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

GODOT_BIN="${GODOT_BIN:-godot}"
RELEASE_VERSION="$(sed -n 's/^config\/version="\(.*\)"$/\1/p' project.godot)"
CONTENT_REVISION="$(python3 -c 'import json; print(json.load(open("content/indexes/runtime_content_index.json", encoding="utf-8"))["content_revision"])')"
SAVE_SCHEMA="$(sed -n 's/^save\/schema_version=\([0-9][0-9]*\)$/\1/p' project.godot)"
RELEASE_PLATFORM="${GMH_RELEASE_PLATFORM:-linux}"

case "$RELEASE_PLATFORM" in
	linux)
		PRESET_NAME="Release Linux"
		PACKAGE_NAME="gensokyo-monochrome-heart.x86_64"
		PLATFORM_ID="linux-x86_64"
		;;
	windows)
		PRESET_NAME="Release Windows"
		PACKAGE_NAME="gensokyo-monochrome-heart.exe"
		PLATFORM_ID="windows-x86_64"
		;;
	*)
		echo "RELEASE BUILD FAILED: unsupported GMH_RELEASE_PLATFORM=$RELEASE_PLATFORM" >&2
		exit 2
		;;
esac

OUTPUT_DIR="${GMH_RELEASE_OUTPUT:-build/release-candidate/gensokyo-monochrome-heart-${RELEASE_VERSION}-${PLATFORM_ID}}"

fail() {
	echo "RELEASE BUILD FAILED: $*" >&2
	exit 1
}

command -v "$GODOT_BIN" >/dev/null 2>&1 || fail "Godot is unavailable"
[[ -n "$RELEASE_VERSION" && -n "$CONTENT_REVISION" && -n "$SAVE_SCHEMA" ]] || fail "release metadata is incomplete"
[[ ! -e "$OUTPUT_DIR" ]] || fail "output already exists: $OUTPUT_DIR (choose a new GMH_RELEASE_OUTPUT)"

python3 scripts/sync_design_content.py --check
"$GODOT_BIN" --headless --path . --script res://src/tools/build_content_cache.gd -- --check
"$GODOT_BIN" --headless --path . --script res://src/tools/validate_release.gd -- --release

mkdir -p "$OUTPUT_DIR"
"$GODOT_BIN" --headless --path . --export-release "$PRESET_NAME" "$OUTPUT_DIR/$PACKAGE_NAME"
[[ -s "$OUTPUT_DIR/$PACKAGE_NAME" && -s "$OUTPUT_DIR/${PACKAGE_NAME%.*}.pck" ]] || fail "export did not create the ${PLATFORM_ID} binary and PCK"

cp CREDITS.generated.md "$OUTPUT_DIR/CREDITS.md"
for document in NOTICE SAVE_COMPATIBILITY KNOWN_ISSUES STORE_COPY_DRAFT SUPPORT; do
	cp "docs/release/${document}.md" "$OUTPUT_DIR/${document}.md"
done

if [[ "$RELEASE_PLATFORM" == "linux" ]]; then
	XDG_DATA_HOME="$OUTPUT_DIR/user-data" \
		"$OUTPUT_DIR/$PACKAGE_NAME" --headless --quit-after 12 >"$OUTPUT_DIR/smoke.log" 2>&1
	if grep -Eq 'SCRIPT ERROR:|ERROR \[|^[[:space:]]*ERROR:' "$OUTPUT_DIR/smoke.log"; then
		cat "$OUTPUT_DIR/smoke.log"
		fail "exported release smoke emitted an error"
	fi
else
	printf '%s\n' "Windows executable exported; Windows clean-machine run remains pending." >"$OUTPUT_DIR/smoke.log"
fi

python3 - "$OUTPUT_DIR" "$RELEASE_VERSION" "$CONTENT_REVISION" "$SAVE_SCHEMA" "$PLATFORM_ID" <<'PY'
import hashlib
import json
import subprocess
import sys
from pathlib import Path

output = Path(sys.argv[1])
version, revision, save_schema, platform = sys.argv[2:]
files = []
for path in sorted(output.iterdir()):
    if path.is_file() and path.name not in {"SHA256SUMS", "release_manifest.json"}:
        files.append({"path": path.name, "sha256": hashlib.sha256(path.read_bytes()).hexdigest(), "bytes": path.stat().st_size})
commit = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
manifest = {
    "schema": "gmh-release-manifest-v1",
    "game_version": version,
    "content_revision": revision,
    "save_schema": int(save_schema),
    "commit": commit,
    "platform": platform,
    "files": files,
}
(output / "release_manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
(output / "SHA256SUMS").write_text("".join(f"{entry['sha256']}  {entry['path']}\n" for entry in files), encoding="utf-8")
PY

(cd "$OUTPUT_DIR" && sha256sum -c SHA256SUMS)
echo "Release candidate built: $OUTPUT_DIR"
