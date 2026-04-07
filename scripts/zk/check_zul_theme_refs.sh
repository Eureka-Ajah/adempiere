#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

STRICT="${1:-}"
CSS_FILE="zkwebui/theme/default/css/img.css.dsp"
THEME_IMG_DIR="zkwebui/theme/default/images"
ZUL_DIR="zkwebui/zul"

if [ ! -f "$CSS_FILE" ]; then
  echo "ERROR: Missing CSS reference file: $CSS_FILE" >&2
  exit 1
fi

if [ ! -d "$THEME_IMG_DIR" ]; then
  echo "ERROR: Missing theme image directory: $THEME_IMG_DIR" >&2
  exit 1
fi

missing=0

mapfile -t urls < <(rg -o "url\([^)]*\)" "$CSS_FILE" | sed -E "s#.*url\(([^)]*)\).*#\1#" | tr -d "'\"" | sed 's#^\s*##;s#\s*$##' | sed 's#^\.\./images/#images/#' | sort -u)

echo "# ZUL/Theme Audit"
echo
for ref in "${urls[@]}"; do
  [ -z "$ref" ] && continue
  case "$ref" in
    data:*|http:*|https:*|//*) continue ;;
  esac
  path="zkwebui/theme/default/${ref}"
  if [ ! -f "$path" ]; then
    echo "- missing_asset: $path"
    missing=$((missing + 1))
  fi
done

zul_count="$(find "$ZUL_DIR" -type f -name '*.zul' | wc -l | tr -d ' ')"
use_count="$(rg -n "<window use=| use=\"" "$ZUL_DIR" | wc -l | tr -d ' ')"

echo "- zul_files: $zul_count"
echo "- zul_use_occurrences: $use_count"
echo "- missing_assets_count: $missing"

if [ "$STRICT" = "--strict" ] && [ "$missing" -gt 0 ]; then
  echo "ERROR: found $missing missing theme asset(s)." >&2
  exit 1
fi

exit 0
