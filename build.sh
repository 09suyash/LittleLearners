#!/usr/bin/env bash
set -e

# LittleLearners / Zoodles Professional Build Script
APP_NAME="LittleLearners"
MODE="${1:-release}" # release, debug, or bundle
VERSION_ARG="$2"     # optional version override, e.g. 1.0.3+5

# Determine version
if [ -n "$VERSION_ARG" ]; then
    if [[ "$VERSION_ARG" == *"+"* ]]; then
        BUILD_NAME=$(echo "$VERSION_ARG" | cut -d'+' -f1)
        BUILD_NUMBER=$(echo "$VERSION_ARG" | cut -d'+' -f2)
    else
        BUILD_NAME="$VERSION_ARG"
        BUILD_NUMBER=$(grep -E '^version:' pubspec.yaml | sed 's/version: //' | tr -d '\r' | tr -d ' ' | cut -d'+' -f2)
    fi
    EXTRA_FLAGS="--build-name=$BUILD_NAME --build-number=$BUILD_NUMBER"
    VERSION_TAG="${BUILD_NAME}+${BUILD_NUMBER}"
else
    FULL_VER=$(grep -E '^version:' pubspec.yaml | sed 's/version: //' | tr -d '\r' | tr -d ' ')
    BUILD_NAME=$(echo "$FULL_VER" | cut -d'+' -f1)
    BUILD_NUMBER=$(echo "$FULL_VER" | cut -d'+' -f2)
    VERSION_TAG="${BUILD_NAME}+${BUILD_NUMBER}"
    EXTRA_FLAGS=""
fi

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M")
OUTPUT_DIR="build/outputs"

mkdir -p "$OUTPUT_DIR"

echo "=================================================="
echo "🚀 Building $APP_NAME ($MODE mode)..."
echo "📌 Version: v$VERSION_TAG | Timestamp: $TIMESTAMP"
echo "=================================================="

if [ "$MODE" = "bundle" ] || [ "$MODE" = "aab" ]; then
    flutter build appbundle --release $EXTRA_FLAGS
    SOURCE="build/app/outputs/bundle/release/app-release.aab"
    DEST_NAME="${APP_NAME}_v${VERSION_TAG}_${TIMESTAMP}.aab"
elif [ "$MODE" = "debug" ]; then
    flutter build apk --debug $EXTRA_FLAGS
    SOURCE="build/app/outputs/flutter-apk/app-debug.apk"
    DEST_NAME="${APP_NAME}_debug_v${VERSION_TAG}_${TIMESTAMP}.apk"
else
    flutter build apk --release $EXTRA_FLAGS
    SOURCE="build/app/outputs/flutter-apk/app-release.apk"
    DEST_NAME="${APP_NAME}_v${VERSION_TAG}_${TIMESTAMP}.apk"
fi

DEST_PATH="$OUTPUT_DIR/$DEST_NAME"
cp "$SOURCE" "$DEST_PATH"

SIZE=$(du -h "$DEST_PATH" | cut -f1)

echo ""
echo "=================================================="
echo "✅ BUILD SUCCESSFUL!"
echo "📦 File: $DEST_NAME"
echo "📁 Path: $DEST_PATH"
echo "⚖️  Size: $SIZE"
echo "=================================================="

# Reveal in macOS Finder
if command -v open >/dev/null 2>&1; then
    open -R "$DEST_PATH"
fi
