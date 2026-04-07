#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

LIB_DIR="${1:-zkwebui/WEB-INF/lib}"

if [ ! -d "$LIB_DIR" ]; then
  echo "ERROR: ZK library directory not found: $LIB_DIR" >&2
  exit 1
fi

CORE_JARS=(
  "zk.jar"
  "zul.jar"
  "zhtml.jar"
  "zweb.jar"
  "zcommon.jar"
  "zkplus.jar"
  "zkex.jar"
  "zkmax.jar"
  "zml.jar"
)

versions=()
missing=0

read_manifest_version() {
  local jar_path="$1"
  local version
  version="$( (unzip -p "$jar_path" META-INF/MANIFEST.MF 2>/dev/null || true) \
    | awk -F': ' '/^(Implementation-Version|Specification-Version):/{gsub(/\r/,"",$2); print $2; exit}')"
  if [ -z "$version" ]; then
    version="unknown"
  fi
  printf '%s' "$version"
}

echo "Checking ZK core jars in: $LIB_DIR"
for jar in "${CORE_JARS[@]}"; do
  jar_path="$LIB_DIR/$jar"
  if [ ! -f "$jar_path" ]; then
    echo "ERROR: Missing required jar: $jar_path" >&2
    missing=1
    continue
  fi

  version="$(read_manifest_version "$jar_path")"
  echo "- $jar => $version"

  if [ "$version" = "unknown" ]; then
    echo "ERROR: Unable to determine version for $jar_path" >&2
    exit 1
  fi

  versions+=("$version")
done

if [ "$missing" -ne 0 ]; then
  exit 1
fi

unique_versions="$(printf '%s\n' "${versions[@]}" | sort -u)"
unique_count="$(printf '%s\n' "$unique_versions" | sed '/^$/d' | wc -l | tr -d ' ')"

if [ "$unique_count" -ne 1 ]; then
  echo "ERROR: ZK core jars are not aligned to a single version." >&2
  echo "Found versions:" >&2
  printf '%s\n' "$unique_versions" >&2
  exit 1
fi

echo "OK: all ZK core jars are aligned to version $(printf '%s' "$unique_versions")"
