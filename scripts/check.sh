#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo 'Full checks require macOS and Xcode. For web checks, run npm run test:web, build, and test:browser.' >&2
  exit 1
fi
command -v node >/dev/null
command -v swift >/dev/null
xcrun --find xcodebuild >/dev/null

while IFS= read -r executable; do
  if [[ "$executable" == "$PWD/artifacts/mac/MementoMori.app/Contents/MacOS/MementoMori" ]]; then
    echo 'Quit the Mac MementoMori app before running full checks; its app bundle will be rebuilt.' >&2
    exit 1
  fi
done < <(ps -A -o comm=)

# Fail at the first error. Build web assets before testing the browser.
npm run test:web
npm run test:core
npm run build
npm run test:browser
npm run build:mac
npm run build:ios
npm run test:ios
echo 'Web, shared core, macOS build, and iOS build/UI checks passed.'
