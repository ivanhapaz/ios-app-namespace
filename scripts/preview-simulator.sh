#!/usr/bin/env bash
#
# Preview "Will They Keep Their Head?" in the iOS Simulator.
#
# Works on any macOS machine with Xcode installed — including a Namespace
# mac/silicon Instance reached over SSH. After it runs, open the instance's
# "Remote Display" (VNC) tab in the Namespace dashboard (or `nsc vnc <id>`)
# to watch/interact with the running app.
#
# Usage:
#   ./scripts/preview-simulator.sh
#   SIM_NAME="iPhone 15" ./scripts/preview-simulator.sh   # override device
#
set -euo pipefail

SCHEME="TudorCourt"
PROJECT="TudorCourt.xcodeproj"
BUNDLE_ID="com.namespace.tudorcourt"
SIM_NAME="${SIM_NAME:-iPhone 16}"
DERIVED="build"

echo "==> Ensuring XcodeGen is installed"
if ! command -v xcodegen >/dev/null 2>&1; then
  brew install xcodegen
fi

echo "==> Generating Xcode project from project.yml"
xcodegen generate

echo "==> Opening the Simulator app (so it shows up on the remote desktop)"
open -a Simulator || true

echo "==> Resolving simulator UDID for '$SIM_NAME'"
UDID=$(xcrun simctl list devices available | awk -F '[()]' -v name="$SIM_NAME" '$0 ~ name {print $2; exit}')
if [ -z "${UDID:-}" ]; then
  echo "!! Simulator '$SIM_NAME' not found. Available devices:"
  xcrun simctl list devices available
  echo "Set SIM_NAME to one of the above and re-run."
  exit 1
fi

echo "==> Booting $SIM_NAME ($UDID)"
xcrun simctl boot "$UDID" 2>/dev/null || true

echo "==> Building for the simulator"
xcodebuild -project "$PROJECT" -scheme "$SCHEME" \
  -destination "id=$UDID" \
  -derivedDataPath "$DERIVED" \
  CODE_SIGNING_ALLOWED=NO build

APP_PATH="$DERIVED/Build/Products/Debug-iphonesimulator/${SCHEME}.app"

echo "==> Installing and launching $BUNDLE_ID"
xcrun simctl install "$UDID" "$APP_PATH"
xcrun simctl launch "$UDID" "$BUNDLE_ID"

echo ""
echo "Done. Touch-and-drag on the phone screen to summon the thumbstick and walk"
echo "the courtier between rooms. Open Remote Display (VNC) to interact."
