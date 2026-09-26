#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mode="${1:-build}"
node scripts/prepare-ios.mjs
project="apps/ios/MementoMori.xcodeproj"
build_dir="artifacts/ios/DerivedData"
if [[ "$mode" == "build" ]]; then
  xcodebuild -quiet -project "$project" -scheme MementoMori -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath "$build_dir" CODE_SIGNING_ALLOWED=NO build
  echo "Built: $build_dir/Build/Products/Debug-iphonesimulator/MementoMori.app"
  exit 0
fi
simulator_id="${MEMENTO_IOS_SIMULATOR_UDID:-$(xcrun simctl list devices available --json | python3 -c 'import json,sys; data=json.load(sys.stdin); phones=[d for runtime,devices in data["devices"].items() if "iOS" in runtime for d in devices if d["name"].startswith("iPhone")]; phones.sort(key=lambda d:d["state"]!="Booted"); print(phones[0]["udid"] if phones else "")')}"
if [[ -z "$simulator_id" ]]; then
  echo "No iPhone simulator. Install an iOS runtime in Xcode > Settings > Components." >&2
  exit 1
fi
if [[ "$mode" == "test" ]]; then
  xcodebuild -quiet -project "$project" -scheme MementoMori -configuration Debug -destination "platform=iOS Simulator,id=$simulator_id" -derivedDataPath "$build_dir" -parallel-testing-enabled NO CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES test
elif [[ "$mode" == "run" ]]; then
  bash scripts/ios.sh build
  if ! xcrun simctl boot "$simulator_id" 2>/dev/null; then
    if ! xcrun simctl list devices booted --json | python3 -c 'import json,sys; data=json.load(sys.stdin); sys.exit(0 if any(d["udid"]==sys.argv[1] for items in data["devices"].values() for d in items) else 1)' "$simulator_id"; then
      echo "Could not boot iPhone simulator." >&2; exit 1
    fi
  fi
  xcrun simctl bootstatus "$simulator_id" -b
  xcrun simctl install "$simulator_id" "$build_dir/Build/Products/Debug-iphonesimulator/MementoMori.app"
  open -a Simulator
  ios_bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$build_dir/Build/Products/Debug-iphonesimulator/MementoMori.app/Info.plist")"
  xcrun simctl launch "$simulator_id" "$ios_bundle_id"
else
  echo "Usage: bash scripts/ios.sh [build|run|test]" >&2
  exit 1
fi
