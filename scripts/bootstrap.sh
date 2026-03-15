#!/usr/bin/env bash
set -euo pipefail

npm install
npx expo prebuild --clean

echo "Bootstrap complete. Next: npx expo run:ios --device"
