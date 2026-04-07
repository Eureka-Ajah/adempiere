#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

modules=(
  "org.adempiere.pos/build.gradle"
  "org.eevolution.manufacturing/build.gradle"
)

for module in "${modules[@]}"; do
  if [ ! -f "$module" ]; then
    echo "ERROR: Missing module build file: $module" >&2
    exit 1
  fi

  rg -q "dir: '../zkwebui/WEB-INF/lib'" "$module" \
    || { echo "ERROR: Missing zkwebui lib fileTree in $module" >&2; exit 1; }

  if ! rg -q 'include: zkLegacyWebuiLibs' "$module" \
      && ! rg -q "'zhtml\.jar'" "$module" \
      && ! rg -q "'keylistener\.jar'" "$module"; then
    echo "ERROR: Missing expected ZK legacy include list in $module" >&2
    exit 1
  fi
done

echo "Satellite module checks: OK"
