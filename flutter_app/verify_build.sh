#!/bin/bash
# Script to verify Flutter app build
# Run from repository root or flutter_app directory

set -e

# Detect if we're in flutter_app or repository root
if [ -f "pubspec.yaml" ]; then
    # We're in flutter_app
    APP_DIR="."
    cd ..
    REPO_ROOT=$(pwd)
    cd "$APP_DIR"
elif [ -d "flutter_app" ]; then
    # We're in repository root
    REPO_ROOT=$(pwd)
    APP_DIR="flutter_app"
    cd "$APP_DIR"
else
    echo "Error: Run this script from repository root or flutter_app directory"
    exit 1
fi

echo "=== Flutter Doctor ==="
flutter doctor -v

echo ""
echo "=== Installing Dependencies ==="
flutter pub get

echo ""
echo "=== Running Tests ==="
flutter test

echo ""
echo "=== Building Release APK ==="
flutter build apk --release

echo ""
echo "=== Build Complete ==="
echo "APK location: flutter_app/build/app/outputs/apk/release/app-release.apk"

if [ -f "build/app/outputs/apk/release/app-release.apk" ]; then
    ls -lh build/app/outputs/apk/release/app-release.apk
    echo ""
    echo "✅ Build successful!"
else
    echo "❌ Build failed - APK not found"
    exit 1
fi
