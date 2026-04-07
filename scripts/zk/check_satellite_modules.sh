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

  rg -q 'apply from: "\$\{rootDir\}/gradle/zk-legacy-libs\.gradle"' "$module" \
    || { echo "ERROR: Missing shared ZK legacy libs apply in $module" >&2; exit 1; }

  rg -q 'include: zkLegacyWebuiLibs' "$module" \
    || { echo "ERROR: Missing include: zkLegacyWebuiLibs in $module" >&2; exit 1; }

done

echo "Satellite module checks: OK"
