#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

OUTPUT_FILE="${1:-}"
TMP_FILE="$(mktemp)"

run() {
  "$@" 2>/dev/null || true
}

{
  echo "# ZK Inventory Report"
  echo
  echo "- Generated at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo "- Repository: $(basename "$ROOT_DIR")"
  echo

  echo "## 1) ZK jars in zkwebui/WEB-INF/lib"
  echo
  if [ -d "zkwebui/WEB-INF/lib" ]; then
    while IFS= read -r jar; do
      jar_name="$(basename "$jar")"
      case "$jar_name" in
        zk*.jar|zul*.jar|zhtml*.jar|zweb*.jar|zcommon*.jar|zkmax*.jar|zkplus*.jar|zkex*.jar|zml*.jar|timelinez*.jar|gmapsz*.jar|fckez*.jar|keylistener*.jar) ;;
        *) continue;;
      esac
      version="$( (unzip -p "$jar" META-INF/MANIFEST.MF 2>/dev/null || true) | awk -F': ' '/^(Implementation-Version|Specification-Version):/{gsub(/\r/,"",$2); print $2; exit}')"
      version="${version:-unknown}"
      printf -- "- %s (version: %s)\n" "$jar_name" "$version"
    done < <(find zkwebui/WEB-INF/lib -maxdepth 1 -type f -name '*.jar' | sort)
  else
    echo "- Directory not found: zkwebui/WEB-INF/lib"
  fi
  echo

  echo "## 2) Java imports inventory"
  echo
  total_zk_imports="$(run rg -n '^\s*import org\.zkoss|^\s*import org\.zkforge' zkwebui/WEB-INF/src | wc -l | tr -d ' ')"
  zkex_imports="$(run rg -n '^\s*import org\.zkoss\.zkex' zkwebui/WEB-INF/src | wc -l | tr -d ' ')"
  zhtml_imports="$(run rg -n '^\s*import org\.zkoss\.zhtml' zkwebui/WEB-INF/src | wc -l | tr -d ' ')"
  zkforge_imports="$(run rg -n '^\s*import org\.zkforge' zkwebui/WEB-INF/src | wc -l | tr -d ' ')"

  echo "- Total imports (org.zkoss + org.zkforge): ${total_zk_imports}"
  echo "- Imports org.zkoss.zkex.*: ${zkex_imports}"
  echo "- Imports org.zkoss.zhtml.*: ${zhtml_imports}"
  echo "- Imports org.zkforge.*: ${zkforge_imports}"
  echo

  echo "### Top files with legacy references"
  echo
  run rg -n 'org\.zkoss\.zkex|org\.zkforge|timelinez|gmapsz|fckez|zml' zkwebui/WEB-INF/src \
    | cut -d: -f1 \
    | sort \
    | uniq -c \
    | sort -nr \
    | head -n 20 \
    | awk '{printf "- %s (%s refs)\n", $2, $1}'
  echo

  echo "## 3) View/config references"
  echo
  zul_count="$(run find zkwebui -type f -name '*.zul' | wc -l | tr -d ' ')"
  zhtml_count="$(run find zkwebui -type f -name '*.zhtml' | wc -l | tr -d ' ')"
  dsp_count="$(run find zkwebui -type f -name '*.dsp' | wc -l | tr -d ' ')"
  echo "- .zul files: ${zul_count}"
  echo "- .zhtml files: ${zhtml_count}"
  echo "- .dsp files: ${dsp_count}"
  echo

  echo "## 4) Commands used to generate this report"
  echo
  echo '```bash'
  echo "./scripts/zk/generate_inventory.sh docs/zk-inventory.md"
  echo '```'
} > "$TMP_FILE"

if [ -n "$OUTPUT_FILE" ]; then
  mkdir -p "$(dirname "$OUTPUT_FILE")"
  cp "$TMP_FILE" "$OUTPUT_FILE"
  echo "Inventory report written to $OUTPUT_FILE"
else
  cat "$TMP_FILE"
fi

rm -f "$TMP_FILE"
