#!/usr/bin/env bash
set -euo pipefail

if [ ! -d node_modules ]; then
  npm install
fi

npx expo prebuild
npx expo run:ios --device
