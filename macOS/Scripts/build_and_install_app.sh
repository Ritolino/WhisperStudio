#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MACOS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENGINE_DIR="$MACOS_DIR/Engine"
APP_DIR="$MACOS_DIR/App"
DEST_APP="/Applications/Whisper Studio.app"
PYINSTALLER_BIN="${PYINSTALLER_BIN:-$ENGINE_DIR/.venv/bin/pyinstaller}"

if [[ ! -x "$PYINSTALLER_BIN" ]]; then
    PYINSTALLER_BIN="$(command -v pyinstaller || true)"
fi
if [[ -z "$PYINSTALLER_BIN" ]]; then
    echo "Error: pyinstaller not found." >&2
    exit 1
fi

PY_BIN="$(dirname "$PYINSTALLER_BIN")/python3"
if [[ -x "$PY_BIN" ]]; then
    PY_VER_STR="$("$PY_BIN" -c 'import platform, sys; print(f"Python {sys.version.split()[0]} ({platform.machine()})")' 2>/dev/null || echo "unknown")"
else
    PY_VER_STR="unknown"
fi

echo "==> [1/4] Building WhisperEngine (--onedir helper) using $PY_VER_STR..."
cd "$ENGINE_DIR"
"$PYINSTALLER_BIN" --noconfirm --clean \
    --distpath "$MACOS_DIR/dist_engine" \
    --workpath "$MACOS_DIR/build_engine" \
    "WhisperEngine.spec"

echo "==> [2/4] Building WhisperStudio SwiftUI executable (arm64 release)..."
cd "$APP_DIR"
swift build -c release --arch arm64
SWIFT_BIN="$APP_DIR/.build/arm64-apple-macosx/release/WhisperStudio"
if [[ ! -x "$SWIFT_BIN" ]]; then
    SWIFT_BIN="$APP_DIR/.build/release/WhisperStudio"
fi

echo "==> [3/4] Assembling bundle at $DEST_APP..."
rm -rf "$DEST_APP"
mkdir -p "$DEST_APP/Contents/MacOS" \
         "$DEST_APP/Contents/Resources"

cp "$APP_DIR/Info.plist" "$DEST_APP/Contents/Info.plist"
cp "$SWIFT_BIN" "$DEST_APP/Contents/MacOS/WhisperStudio"
chmod +x "$DEST_APP/Contents/MacOS/WhisperStudio"

cp -R "$MACOS_DIR/dist_engine/WhisperEngine" "$DEST_APP/Contents/Resources/WhisperEngine"
if [[ -f "$DEST_APP/Contents/Resources/WhisperEngine/ffmpeg" ]]; then
    chmod +x "$DEST_APP/Contents/Resources/WhisperEngine/ffmpeg"
fi

for res in AppIcon.icns wispr.png app_icon_black.png; do
    if [[ -f "$MACOS_DIR/$res" ]]; then
        cp "$MACOS_DIR/$res" "$DEST_APP/Contents/Resources/$res"
    fi
done

echo "==> [4/4] Signing inside-out & cleaning build artifacts..."
SIGN_ID="${DEVELOPER_ID_APP:--}"
if [[ "$SIGN_ID" == "-" ]]; then
    find "$DEST_APP/Contents/Resources/WhisperEngine" -type f \( -name "*.dylib" -o -name "*.so" \) -exec codesign --force --sign - {} \;
    if [[ -f "$DEST_APP/Contents/Resources/WhisperEngine/ffmpeg" ]]; then
        codesign --force --sign - "$DEST_APP/Contents/Resources/WhisperEngine/ffmpeg"
    fi
    codesign --force --sign - "$DEST_APP/Contents/Resources/WhisperEngine/WhisperEngine"
    codesign --force --sign - "$DEST_APP/Contents/MacOS/WhisperStudio"
    codesign --force --sign - "$DEST_APP"
else
    find "$DEST_APP/Contents/Resources/WhisperEngine" -type f \( -name "*.dylib" -o -name "*.so" \) -exec codesign --force --options runtime --timestamp --sign "$SIGN_ID" {} \;
    if [[ -f "$DEST_APP/Contents/Resources/WhisperEngine/ffmpeg" ]]; then
        codesign --force --options runtime --timestamp --sign "$SIGN_ID" "$DEST_APP/Contents/Resources/WhisperEngine/ffmpeg"
    fi
    codesign --force --options runtime --timestamp --sign "$SIGN_ID" "$DEST_APP/Contents/Resources/WhisperEngine/WhisperEngine"
    codesign --force --options runtime --timestamp --sign "$SIGN_ID" "$DEST_APP/Contents/MacOS/WhisperStudio"
    codesign --force --options runtime --timestamp --sign "$SIGN_ID" "$DEST_APP"
fi

xattr -dr com.apple.quarantine "$DEST_APP" 2>/dev/null || true

rm -rf "$MACOS_DIR/dist_engine" "$MACOS_DIR/build_engine"

echo "Done! Installed at: $DEST_APP"
