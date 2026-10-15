#!/bin/bash
# 从 1024x1024 PNG 生成 AppIcon.icns。
# 用法：./Scripts/make-icon.sh <input.png>
set -euo pipefail
cd "$(dirname "$0")/.."

SRC="${1:-}"
if [ -z "$SRC" ] || [ ! -f "$SRC" ]; then
  echo "用法: ./Scripts/make-icon.sh <1024x1024.png>" >&2
  exit 1
fi

ICONSET=".icon-build/AppIcon.iconset"
mkdir -p "$ICONSET"

for s in 16 32 128 256 512; do
  d=$((s * 2))
  sips -z "$s" "$s" "$SRC" --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
  sips -z "$d" "$d" "$SRC" --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
done

iconutil -c icns "$ICONSET" -o Resources/AppIcon.icns
rm -rf "$ICONSET"
echo "OK: Resources/AppIcon.icns"
