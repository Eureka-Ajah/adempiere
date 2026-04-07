#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

./scripts/zk/check_zk_versions.sh
./scripts/zk/check_zk_bootstrap_config.sh
./scripts/zk/check_satellite_modules.sh
./scripts/zk/check_zul_theme_refs.sh > /tmp/zk-theme-audit-current.md
./scripts/zk/generate_inventory.sh > /tmp/zk-inventory-current.md

grep -v '^- Generated at:' docs/zk-inventory.md > /tmp/zk-inventory-baseline.notime.md
grep -v '^- Generated at:' /tmp/zk-inventory-current.md > /tmp/zk-inventory-current.notime.md
diff -u /tmp/zk-inventory-baseline.notime.md /tmp/zk-inventory-current.notime.md
diff -u docs/zk-theme-audit.md /tmp/zk-theme-audit-current.md

echo "ZK guard suite: OK"
