#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

WEB_XML="zkwebui/WEB-INF/web.xml"
ZK_XML="zkwebui/WEB-INF/zk.xml"

require_pattern() {
  local file="$1"
  local pattern="$2"
  if ! rg -q "$pattern" "$file"; then
    echo "ERROR: pattern '$pattern' not found in $file" >&2
    exit 1
  fi
}

for f in "$WEB_XML" "$ZK_XML"; do
  if [ ! -f "$f" ]; then
    echo "ERROR: missing required file $f" >&2
    exit 1
  fi
done

# Structural sanity checks (best-effort without external xmllint dependency)
if ! rg -q '<web-app[^>]*version="(2\.4|3\.1)"' "$WEB_XML"; then
  echo "ERROR: web.xml version must be 2.4 or 3.1" >&2
  exit 1
fi
require_pattern "$WEB_XML" '<servlet-name>zkLoader</servlet-name>'
require_pattern "$WEB_XML" '<servlet-name>auEngine</servlet-name>'
require_pattern "$WEB_XML" '<url-pattern>/zkau/\*</url-pattern>'

require_pattern "$ZK_XML" '<session-config>'
require_pattern "$ZK_XML" '<timeout-uri>/timeout\.zul</timeout-uri>'
if ! rg -q '<automatic-timeout>true</automatic-timeout>|<automatic-timeout\s*/>' "$ZK_XML"; then
  echo "ERROR: automatic-timeout is not configured in $ZK_XML" >&2
  exit 1
fi
require_pattern "$ZK_XML" '<id-generator-class>org\.adempiere\.webui\.AdempiereIdGenerator</id-generator-class>'

# parser check via python stdlib
python - <<'PY'
import xml.etree.ElementTree as ET
for path in ["zkwebui/WEB-INF/web.xml", "zkwebui/WEB-INF/zk.xml"]:
    ET.parse(path)
print("XML parse check: OK")
PY

echo "ZK bootstrap config checks: OK"
