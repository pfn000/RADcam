#!/usr/bin/env bash
set -euo pipefail

if ! command -v npx >/dev/null 2>&1; then
  echo "npx is required (install Node.js 18+)." >&2
  exit 1
fi

if [ ! -d node_modules ]; then
  npm install
fi

# Builds iOS dev client in Expo's cloud (works from Windows/Linux/macOS)
npx eas build --platform ios --profile development

echo "Cloud build triggered. Install build on iPhone, then run:"
echo "  npx expo start --dev-client --tunnel"
