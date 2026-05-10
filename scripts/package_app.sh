#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="A2te"
VISIBLE_DIST_DIR="${ROOT_DIR}/dist"
APP_BUNDLE="${VISIBLE_DIST_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
LEGACY_VISIBLE_ZIP_PATH="${VISIBLE_DIST_DIR}/${APP_NAME}.app.zip"
STALE_BUILD_APP_BUNDLE="${ROOT_DIR}/.build/dist/${APP_NAME}.app"
STALE_XCODE_APP_BUNDLE="${ROOT_DIR}/.xcodebuild/Build/Products/Release/${APP_NAME}.app"

ICON_APP="${ROOT_DIR}/assets/icons/A2te.icns"
ICON_DOC="${ROOT_DIR}/assets/icons/A2teProject.icns"
DOC_ICON_BUNDLE_NAME="A2teProjectDoc"
INFO_PLIST_TEMPLATE="${ROOT_DIR}/packaging/Info.plist"

if [[ ! -f "${ICON_APP}" || ! -f "${ICON_DOC}" ]]; then
  echo "icon files are missing: ${ICON_APP} and/or ${ICON_DOC}" >&2
  exit 1
fi

if [[ ! -f "${INFO_PLIST_TEMPLATE}" ]]; then
  echo "missing Info.plist template: ${INFO_PLIST_TEMPLATE}" >&2
  exit 1
fi

echo "Building ${APP_NAME} (release)..."
swift build -c release --package-path "${ROOT_DIR}"
BIN_DIR="$(swift build -c release --show-bin-path --package-path "${ROOT_DIR}")"
BIN_PATH="${BIN_DIR}/${APP_NAME}"

if [[ ! -x "${BIN_PATH}" ]]; then
  echo "build output not found: ${BIN_PATH}" >&2
  exit 1
fi

echo "Packaging app bundle..."
rm -rf "${APP_BUNDLE}"
rm -rf "${STALE_BUILD_APP_BUNDLE}"
rm -rf "${STALE_XCODE_APP_BUNDLE}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"
cp "${BIN_PATH}" "${MACOS_DIR}/${APP_NAME}"
cp "${INFO_PLIST_TEMPLATE}" "${CONTENTS_DIR}/Info.plist"
cp "${ICON_APP}" "${RESOURCES_DIR}/A2te.icns"
cp "${ICON_DOC}" "${RESOURCES_DIR}/${DOC_ICON_BUNDLE_NAME}.icns"

echo "Cleaning legacy artifacts..."
rm -f "${LEGACY_VISIBLE_ZIP_PATH}"

# Keep LaunchServices focused on dist bundle only.
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
if [[ -x "${LSREGISTER}" ]]; then
  "${LSREGISTER}" -u "${STALE_BUILD_APP_BUNDLE}" >/dev/null 2>&1 || true
  "${LSREGISTER}" -u "${STALE_XCODE_APP_BUNDLE}" >/dev/null 2>&1 || true
  "${LSREGISTER}" -f "${APP_BUNDLE}" >/dev/null 2>&1 || true
fi

echo "Done."
echo "App bundle: ${APP_BUNDLE}"
