#!/usr/bin/env bash
# GOZAR VPN build helper for Linux
# - Installs prerequisites (Debian/Ubuntu)
# - Prompts for target platform
# - Builds artifacts for Android (APK/AAB) and Linux (bundle + tar.gz; AppImage if possible)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$REPO_ROOT/mobile/flutter_app"
DIST_DIR="$REPO_ROOT/dist"
ANDROID_SDK_DEFAULT="$HOME/Android/Sdk"
FLUTTER_DEFAULT="$HOME/flutter"
GO_VERSION="${GO_VERSION:-1.22.6}"
ANDROID_API="${ANDROID_API:-34}"
BUILD_TOOLS="${BUILD_TOOLS:-34.0.0}"
JAVA_PKG="openjdk-17-jdk"

need_cmd() { command -v "$1" >/dev/null 2>&1; }
confirm() {
  local prompt="$1"
  read -r -p "$prompt [y/N]: " ans
  [[ "${ans:-}" =~ ^[Yy]$ ]]
}

section() { echo -e "\n===== $* =====\n"; }

install_prereqs_debian() {
  section "Installing system prerequisites (Debian/Ubuntu)"
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    git curl wget unzip zip xz-utils ca-certificates \
    build-essential clang cmake ninja-build pkg-config \
    libgtk-3-dev liblzma-dev libstdc++-12-dev \
    $JAVA_PKG
}

install_flutter() {
  if need_cmd flutter; then
    section "Flutter already installed: $(flutter --version 2>/dev/null | head -n1)"
    return
  fi
  section "Installing Flutter (stable) to $FLUTTER_DEFAULT"
  mkdir -p "$FLUTTER_DEFAULT"
  cd "$(dirname "$FLUTTER_DEFAULT")"
  # Download latest stable tarball
  FL_URL="$(curl -s https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json | \
    grep -oE 'https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_[^"]+_stable.tar.xz' | head -n1)"
  [[ -n "$FL_URL" ]] || { echo "Failed to resolve Flutter download URL"; exit 1; }
  FNAME="$(basename "$FL_URL")"
  curl -LO "$FL_URL"
  tar -xf "$FNAME"
  rm -f "$FNAME"
  # Move to $FLUTTER_DEFAULT if necessary
  if [[ ! -d "$FLUTTER_DEFAULT/bin" && -d flutter ]]; then
    mv flutter "$FLUTTER_DEFAULT"
  fi
  export PATH="$FLUTTER_DEFAULT/bin:$PATH"
  if confirm "Add Flutter to PATH in ~/.bashrc?"; then
    if ! grep -q 'export PATH=.*flutter/bin' "$HOME/.bashrc" 2>/dev/null; then
      echo "export PATH=\"$FLUTTER_DEFAULT/bin:\$PATH\"" >> "$HOME/.bashrc"
    fi
  fi
  flutter --version
}

install_go() {
  if need_cmd go; then
    section "Go already installed: $(go version)"
    return
  fi
  section "Installing Go $GO_VERSION"
  cd /tmp
  sudo rm -rf /usr/local/go || true
  curl -LO "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
  sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
  rm -f "go${GO_VERSION}.linux-amd64.tar.gz"
  export PATH="/usr/local/go/bin:$PATH"
  if confirm "Add Go to PATH in ~/.bashrc?"; then
    if ! grep -q '/usr/local/go/bin' "$HOME/.bashrc" 2>/dev/null; then
      echo 'export PATH="/usr/local/go/bin:$PATH"' >> "$HOME/.bashrc"
    fi
  fi
  go version
}

install_gomobile() {
  section "Installing gomobile tools"
  export PATH="/usr/local/go/bin:$PATH"
  go install golang.org/x/mobile/cmd/gomobile@latest
  go install golang.org/x/mobile/cmd/gobind@latest
}

install_android_sdk() {
  if [[ -n "${ANDROID_SDK_ROOT:-}" && -d "$ANDROID_SDK_ROOT" ]]; then
    section "Using ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT"
  else
    export ANDROID_SDK_ROOT="$ANDROID_SDK_DEFAULT"
  fi
  mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools"
  if ! need_cmd sdkmanager; then
    section "Installing Android commandline-tools to $ANDROID_SDK_ROOT"
    cd /tmp
    curl -LO https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
    unzip -q commandlinetools-linux-*_latest.zip -d cmdline-temp
    mv cmdline-temp/cmdline-tools "$ANDROID_SDK_ROOT/cmdline-tools/latest"
    rm -rf cmdline-temp commandlinetools-linux-*_latest.zip
  fi
  export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"
  yes | sdkmanager --licenses >/dev/null || true
  sdkmanager "platform-tools" "platforms;android-${ANDROID_API}" "build-tools;${BUILD_TOOLS}" >/dev/null
  section "Android SDK installed at $ANDROID_SDK_ROOT"
  if confirm "Add Android SDK to PATH in ~/.bashrc?"; then
    if ! grep -q 'ANDROID_SDK_ROOT' "$HOME/.bashrc" 2>/dev/null; then
      {
        echo "export ANDROID_SDK_ROOT=\"$ANDROID_SDK_ROOT\""
        echo 'export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"'
      } >> "$HOME/.bashrc"
    fi
  fi
}

ensure_flutter_linux_enabled() {
  section "Enabling Flutter Linux desktop"
  export PATH="${FLUTTER_DEFAULT}/bin:$PATH"
  flutter config --enable-linux-desktop
  cd "$APP_DIR"
  if [[ ! -d linux ]]; then
    flutter create --platforms=linux .
  fi
}

build_android() {
  section "Building Android (APK & AAB)"
  export PATH="${FLUTTER_DEFAULT}/bin:$PATH"
  export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$ANDROID_SDK_DEFAULT}"
  cd "$APP_DIR"
  flutter pub get
  flutter build apk --release
  flutter build appbundle --release
  mkdir -p "$DIST_DIR/android"
  cp -f build/app/outputs/flutter-apk/app-release.apk "$DIST_DIR/android/GOZAR-release.apk"
  AAB_PATH="$(find build/app/outputs/bundle -name '*release.aab' -type f | head -n1 || true)"
  if [[ -n "$AAB_PATH" ]]; then
    cp -f "$AAB_PATH" "$DIST_DIR/android/GOZAR-release.aab"
  fi
  echo "Android artifacts in: $DIST_DIR/android"
}

build_linux() {
  section "Building Linux desktop"
  export PATH="${FLUTTER_DEFAULT}/bin:$PATH"
  ensure_flutter_linux_enabled
  cd "$APP_DIR"
  flutter pub get
  flutter build linux --release
  BUNDLE_DIR="$APP_DIR/build/linux/x64/release/bundle"
  [[ -d "$BUNDLE_DIR" ]] || { echo "Linux bundle not found at $BUNDLE_DIR"; exit 1; }
  mkdir -p "$DIST_DIR/linux"
  tar -C "$BUNDLE_DIR" -czf "$DIST_DIR/linux/GOZAR-linux-x64.tar.gz" .
  echo "Created $DIST_DIR/linux/GOZAR-linux-x64.tar.gz"

  if [[ -x "$HOME/.local/bin/appimagetool" ]]; then
    APPIMG_TOOL="$HOME/.local/bin/appimagetool"
  else
    mkdir -p "$HOME/.local/bin"
    if command -v curl >/dev/null; then
      curl -L -o "$HOME/.local/bin/appimagetool" https://github.com/AppImage/AppImageKit/releases/download/13/appimagetool-x86_64.AppImage || true
      chmod +x "$HOME/.local/bin/appimagetool" || true
    fi
    APPIMG_TOOL="$HOME/.local/bin/appimagetool"
  fi

  if [[ -x "$APPIMG_TOOL" ]]; then
    section "Packaging AppImage"
    APPDIR="/tmp/Gozar.AppDir"
    rm -rf "$APPDIR"
    mkdir -p "$APPDIR/usr/bin"
    cp -r "$BUNDLE_DIR"/* "$APPDIR/usr/bin/"
    cat > "$APPDIR/AppRun" << 'EOF'
#!/usr/bin/env bash
HERE="$(dirname "$(readlink -f "$0")")"
export LD_LIBRARY_PATH="$HERE/usr/bin/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
exec "$HERE/usr/bin/gozar_vpn" "$@"
EOF
    chmod +x "$APPDIR/AppRun"
    cat > "$APPDIR/gozar-vpn.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=GOZAR VPN
Exec=gozar_vpn
Icon=gozar-vpn
Categories=Network;Security;
Terminal=false
EOF
    convert -size 256x256 xc:teal "$APPDIR/gozar-vpn.png" 2>/dev/null || cp "$APPDIR/usr/bin/data/flutter_assets/assets/icon.png" "$APPDIR/gozar-vpn.png" 2>/dev/null || true
    "$APPIMG_TOOL" "$APPDIR" "$DIST_DIR/linux/GOZAR-linux-x64.AppImage" || echo "AppImage packaging failed (skipping)."
    echo "Linux artifacts in: $DIST_DIR/linux"
  else
    echo "appimagetool not available; skipped AppImage packaging."
  fi
}

main_menu() {
  echo "Select target platform to build:"
  echo "  1) Android (APK & AAB)"
  echo "  2) Linux desktop (bundle + tar.gz, AppImage if possible)"
  echo "  3) Windows desktop (not supported on Linux host)"
  echo "  4) macOS desktop (not supported on Linux host)"
  echo "  5) iOS (not supported on Linux host)"
  echo "  0) Exit"
  read -r -p "Enter choice: " choice
  case "${choice:-}" in
    1)
      install_prereqs_debian
      install_flutter
      install_go
      install_gomobile
      install_android_sdk
      build_android
      ;;
    2)
      install_prereqs_debian
      install_flutter
      install_go
      build_linux
      ;;
    3)
      echo "Windows releases must be built on Windows with MSVC toolchain and Flutter for Windows."
      ;;
    4)
      echo "macOS releases must be built on macOS with Xcode and Flutter for macOS."
      ;;
    5)
      echo "iOS releases must be built on macOS with Xcode (Network Extensions capability required)."
      ;;
    0|q|Q)
      exit 0
      ;;
    *)
      echo "Invalid choice"; exit 1
      ;;
  esac
}

pre_checks() {
  if [[ ! -d "$APP_DIR" ]]; then
    echo "Could not find Flutter app at: $APP_DIR"
    echo "Run this script from within the repository tree. Expected layout: mobile/flutter_app/..."
    exit 1
  fi
}

pre_checks
mkdir -p "$DIST_DIR"
main_menu
echo "Done."
