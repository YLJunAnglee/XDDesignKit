#!/bin/bash

set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
demo_project="Examples/XDDesignKitDemo/XDDesignKitDemo.xcodeproj"

if [[ -n "${XD_SIMULATOR_DESTINATION:-}" ]]; then
  simulator_destination="$XD_SIMULATOR_DESTINATION"
else
  simulator_id="$(xcrun simctl list devices available | sed -nE '/iPhone/ { s/.*\(([0-9A-F-]{36})\).*/\1/p; q; }')"
  if [[ -z "$simulator_id" ]]; then
    echo "No available iPhone Simulator was found." >&2
    exit 1
  fi
  simulator_destination="platform=iOS Simulator,arch=$(uname -m),id=$simulator_id"
fi

cd "$project_root"

xcodebuild \
  -project "$demo_project" \
  -scheme XDDesignKit \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/xd-designkit-ci-build \
  SWIFT_SUPPRESS_WARNINGS=NO \
  SWIFT_STRICT_CONCURRENCY=complete \
  SWIFT_TREAT_WARNINGS_AS_ERRORS=YES \
  build

xcodebuild \
  -project "$demo_project" \
  -scheme XDDesignKitDemo \
  -destination "$simulator_destination" \
  -derivedDataPath /tmp/xd-designkit-ci-test \
  SWIFT_SUPPRESS_WARNINGS=NO \
  SWIFT_STRICT_CONCURRENCY=complete \
  SWIFT_TREAT_WARNINGS_AS_ERRORS=YES \
  test
