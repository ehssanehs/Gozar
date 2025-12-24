#!/bin/bash
# Script to verify Flutter app build
# This should be run locally with Flutter SDK installed

set -e

echo "=== Flutter Doctor ==="
flutter doctor -v

echo ""
echo "=== Installing Dependencies ==="
cd flutter_app
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
