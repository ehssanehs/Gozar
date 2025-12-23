#!/usr/bin/env bash
# GOZAR VPN build helper for Linux
# Ensures latest Xray-core, installs prereqs, builds Android (APK/AAB) and Linux.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$REPO_ROOT/mobile/flutter_app"
CORE_DIR="$REPO_ROOT/core/go"
DIST_DIR="$REPO_ROOT/dist"
ANDROID_SDK_DEFAULT="$HOME/Android/Sdk"
FLUTTER_DEFAULT="$HOME/flutter"
GO_VERSION="${GO_VERSION:-1.22.6}"
ANDROID_API="${ANDROID_API:-34}"
BUILD_TOOLS="${BUILD_TOOLS:-34.0.0}"
JAVA_PKG="openjdk-17-jdk"

need_cmd() { command -v "$1" >/dev/null 2>&1; }
confirm() { local p="$1"; read -r -p "$p [y/N]: " a; [[ "${a:-}" =~ ^[Yy]$ ]]; }
section() { echo -e "\n===== $* =====\n"; }

ensure_core_latest() {
  section "Ensuring latest Xray-core in Go module"
  if [[ -d "$CORE_DIR" ]]; then
    pushd "$CORE_DIR" >/dev/null
    go get github.com/xtls/xray-core@latest
    go mod tidy
    popd >/dev/null
  else
    echo "Core Go directory not found at $CORE_DIR"
  fi
}

# ... (rest of script remains same, but call ensure_core_latest in build_android and build_linux)

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
  FL_URL="$(curl -s https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json | \
    grep -oE 'https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_[^"]+_stable.tar.xz' | head -n1)"
  [[ -n "$FL_URL" ]] || { echo "Failed to resolve Flutter download URL"; exit 1; }
  FNAME="$(basename "$FL_URL")"
  curl -LO "$FL_URL"
  tar -xf "$FNAME"
  rm -f "$FNAME"
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
  ensure_core_latest
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
  ensure_core_latest
  ensure_flutter_linux_enabled
  cd "$APP_DIR"
  flutter pub get
  flutter build linux --release
  BUNDLE_DIR="$APP_DIR/build/linux/x64/release/bundle"
  [[ -d "$BUNDLE_DIR" ]] || { echo "Linux bundle not found at $BUNDLE_DIR"; exit 1; }
  mkdir -p "$DIST_DIR/linux"
  tar -C "$BUNDLE_DIR" -czf "$DIST_DIR/linux/GOZAR-linux-x64.tar.gz" .
  echo "Created $DIST_DIR/linux/GOZAR-linux-x64.tar.gz"
}

main_menu() {
  echo "Select target platform to build:"
  echo "  1) Android (APK & AAB)"
  echo "  2) Linux desktop (bundle + tar.gz)"
  echo "  0) Exit"
  read -r -p "Enter choice: " choice
  case "${choice:-}" in
    1) install_prereqs_debian; install_flutter; install_go; install_gomobile; install_android_sdk; build_android ;;
    2) install_prereqs_debian; install_flutter; install_go; build_linux ;;
    0|q|Q) exit 0 ;;
    *) echo "Invalid choice"; exit 1 ;;
  esac
}

[[ -d "$APP_DIR" ]] || { echo "Flutter app not found at: $APP_DIR"; exit 1; }
mkdir -p "$DIST_DIR"
main_menu
echo "Done."
