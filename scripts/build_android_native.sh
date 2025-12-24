#!/usr/bin/env bash
# GOZAR Native Android Build Script
# Installs prerequisites and builds signed release APK/AAB for Play Store submission
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_DIR="$REPO_ROOT/android"
DIST_DIR="$REPO_ROOT/dist"
ANDROID_SDK_DEFAULT="$HOME/Android/Sdk"
JAVA_PKG="openjdk-17-jdk"
GRADLE_VERSION="8.2.2"
ANDROID_API="${ANDROID_API:-34}"
BUILD_TOOLS="${BUILD_TOOLS:-34.0.0}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

need_cmd() { command -v "$1" >/dev/null 2>&1; }
confirm() { local p="$1"; read -r -p "$p [y/N]: " a; [[ "${a:-}" =~ ^[Yy]$ ]]; }
section() { echo -e "\n${GREEN}===== $* =====${NC}\n"; }
error() { echo -e "${RED}ERROR: $*${NC}" >&2; exit 1; }
warning() { echo -e "${YELLOW}WARNING: $*${NC}"; }

check_prerequisites() {
    section "Checking prerequisites"
    
    if [[ ! -d "$ANDROID_DIR" ]]; then
        error "Android directory not found at: $ANDROID_DIR"
    fi
    
    echo "Repository root: $REPO_ROOT"
    echo "Android project: $ANDROID_DIR"
    echo "Output directory: $DIST_DIR"
}

install_prereqs_debian() {
    section "Installing system prerequisites (Debian/Ubuntu)"
    
    if ! need_cmd apt-get; then
        error "This script requires apt-get (Debian/Ubuntu). For other distros, install Java 17, Android SDK manually."
    fi
    
    sudo apt-get update
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        git curl wget unzip zip \
        build-essential \
        $JAVA_PKG \
        ca-certificates
    
    echo "System prerequisites installed."
}

setup_java() {
    section "Setting up Java"
    
    if need_cmd java; then
        JAVA_VERSION=$(java -version 2>&1 | head -n1 | cut -d'"' -f2 | cut -d'.' -f1)
        echo "Java already installed: $(java -version 2>&1 | head -n1)"
        
        if [[ "$JAVA_VERSION" -lt 17 ]]; then
            warning "Java version is less than 17. Installing Java 17..."
            sudo apt-get install -y $JAVA_PKG
        fi
    else
        echo "Java not found. Installing..."
        sudo apt-get install -y $JAVA_PKG
    fi
    
    export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
    echo "JAVA_HOME: $JAVA_HOME"
}

install_android_sdk() {
    section "Setting up Android SDK"
    
    if [[ -n "${ANDROID_SDK_ROOT:-}" && -d "$ANDROID_SDK_ROOT" ]]; then
        echo "Using existing ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT"
    else
        export ANDROID_SDK_ROOT="$ANDROID_SDK_DEFAULT"
        echo "Using default Android SDK location: $ANDROID_SDK_ROOT"
    fi
    
    mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools"
    
    if [[ ! -f "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" ]]; then
        echo "Installing Android commandline-tools to $ANDROID_SDK_ROOT"
        cd /tmp
        curl -LO https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
        unzip -q commandlinetools-linux-*_latest.zip -d cmdline-temp
        mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools"
        rm -rf "$ANDROID_SDK_ROOT/cmdline-tools/latest"
        mv cmdline-temp/cmdline-tools "$ANDROID_SDK_ROOT/cmdline-tools/latest"
        rm -rf cmdline-temp commandlinetools-linux-*_latest.zip
        cd "$REPO_ROOT"
    fi
    
    export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"
    
    echo "Accepting Android SDK licenses..."
    yes | "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" --licenses >/dev/null 2>&1 || true
    
    echo "Installing Android SDK components..."
    "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" \
        "platform-tools" \
        "platforms;android-${ANDROID_API}" \
        "build-tools;${BUILD_TOOLS}" >/dev/null 2>&1
    
    echo "Android SDK installed successfully."
    
    if confirm "Add Android SDK to PATH in ~/.bashrc?"; then
        if ! grep -q 'ANDROID_SDK_ROOT' "$HOME/.bashrc" 2>/dev/null; then
            {
                echo ""
                echo "# Android SDK (added by GOZAR build script)"
                echo "export ANDROID_SDK_ROOT=\"$ANDROID_SDK_ROOT\""
                echo 'export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"'
            } >> "$HOME/.bashrc"
            echo "Android SDK path added to ~/.bashrc"
        fi
    fi
}

setup_gradle() {
    section "Setting up Gradle"
    
    cd "$ANDROID_DIR"
    
    if [[ ! -f gradlew ]]; then
        error "Gradle wrapper not found. Please ensure android/gradlew exists."
    fi
    
    chmod +x gradlew
    echo "Gradle wrapper is ready."
}

setup_signing_config() {
    section "Setting up signing configuration"
    
    KEYSTORE_FILE="$ANDROID_DIR/app/gozar-release.keystore"
    KEYSTORE_PROPS="$ANDROID_DIR/keystore.properties"
    
    if [[ -f "$KEYSTORE_PROPS" ]]; then
        echo "Signing configuration already exists at: $KEYSTORE_PROPS"
        return
    fi
    
    echo ""
    warning "No signing configuration found."
    echo "For release builds suitable for Play Store, you need a signing key."
    echo ""
    
    if ! confirm "Do you want to create a new keystore now?"; then
        warning "Skipping keystore creation. Release build will use debug signing."
        return
    fi
    
    echo ""
    echo "Creating new keystore..."
    echo "Please provide the following information:"
    
    read -r -p "Keystore password: " STORE_PASSWORD
    read -r -p "Key alias (default: gozar): " KEY_ALIAS
    KEY_ALIAS="${KEY_ALIAS:-gozar}"
    read -r -p "Key password (press Enter to use same as keystore): " KEY_PASSWORD
    KEY_PASSWORD="${KEY_PASSWORD:-$STORE_PASSWORD}"
    
    echo ""
    echo "Generating keystore..."
    
    keytool -genkeypair \
        -alias "$KEY_ALIAS" \
        -keyalg RSA \
        -keysize 2048 \
        -validity 10000 \
        -keystore "$KEYSTORE_FILE" \
        -storepass "$STORE_PASSWORD" \
        -keypass "$KEY_PASSWORD" \
        -dname "CN=Gozar VPN, OU=Development, O=Persian Games, L=Unknown, ST=Unknown, C=US"
    
    # Create keystore.properties
    cat > "$KEYSTORE_PROPS" <<EOF
storeFile=gozar-release.keystore
storePassword=$STORE_PASSWORD
keyAlias=$KEY_ALIAS
keyPassword=$KEY_PASSWORD
EOF
    
    chmod 600 "$KEYSTORE_PROPS"
    
    echo ""
    echo "${GREEN}Keystore created successfully!${NC}"
    echo "Location: $KEYSTORE_FILE"
    echo "Properties: $KEYSTORE_PROPS"
    echo ""
    warning "IMPORTANT: Keep these files secure and backed up!"
    warning "Add keystore.properties to .gitignore to prevent committing secrets."
}

build_debug() {
    section "Building Debug APK"
    
    cd "$ANDROID_DIR"
    
    export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$ANDROID_SDK_DEFAULT}"
    
    echo "Cleaning previous builds..."
    ./gradlew clean
    
    echo "Building debug APK..."
    ./gradlew assembleDebug
    
    mkdir -p "$DIST_DIR/android"
    
    APK_PATH="$ANDROID_DIR/app/build/outputs/apk/debug/app-debug.apk"
    if [[ -f "$APK_PATH" ]]; then
        cp -f "$APK_PATH" "$DIST_DIR/android/GOZAR-debug.apk"
        echo "${GREEN}Debug APK created:${NC} $DIST_DIR/android/GOZAR-debug.apk"
    else
        error "Debug APK not found at expected location: $APK_PATH"
    fi
}

build_release() {
    section "Building Release APK and AAB"
    
    cd "$ANDROID_DIR"
    
    export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$ANDROID_SDK_DEFAULT}"
    
    # Check for signing config
    KEYSTORE_PROPS="$ANDROID_DIR/keystore.properties"
    if [[ ! -f "$KEYSTORE_PROPS" ]]; then
        warning "No signing configuration found."
        warning "Release build will use debug signing (not suitable for Play Store)."
    fi
    
    echo "Cleaning previous builds..."
    ./gradlew clean
    
    echo "Building release APK..."
    ./gradlew assembleRelease
    
    echo "Building release AAB (Android App Bundle)..."
    ./gradlew bundleRelease
    
    mkdir -p "$DIST_DIR/android"
    
    # Copy APK
    APK_PATH="$ANDROID_DIR/app/build/outputs/apk/release/app-release.apk"
    if [[ -f "$APK_PATH" ]]; then
        cp -f "$APK_PATH" "$DIST_DIR/android/GOZAR-release.apk"
        
        # Get APK info
        APK_SIZE=$(du -h "$DIST_DIR/android/GOZAR-release.apk" | cut -f1)
        echo "${GREEN}Release APK created:${NC} $DIST_DIR/android/GOZAR-release.apk ($APK_SIZE)"
    else
        warning "Release APK not found at expected location: $APK_PATH"
    fi
    
    # Copy AAB
    AAB_PATH="$ANDROID_DIR/app/build/outputs/bundle/release/app-release.aab"
    if [[ -f "$AAB_PATH" ]]; then
        cp -f "$AAB_PATH" "$DIST_DIR/android/GOZAR-release.aab"
        
        # Get AAB info
        AAB_SIZE=$(du -h "$DIST_DIR/android/GOZAR-release.aab" | cut -f1)
        echo "${GREEN}Release AAB created:${NC} $DIST_DIR/android/GOZAR-release.aab ($AAB_SIZE)"
    else
        warning "Release AAB not found at expected location: $AAB_PATH"
    fi
    
    echo ""
    echo "${GREEN}Build completed successfully!${NC}"
    echo "Output directory: $DIST_DIR/android"
    ls -lh "$DIST_DIR/android/"
}

run_tests() {
    section "Running Unit Tests"
    
    cd "$ANDROID_DIR"
    
    export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$ANDROID_SDK_DEFAULT}"
    
    echo "Running unit tests..."
    ./gradlew test
    
    echo "${GREEN}Tests completed.${NC}"
}

install_all_prerequisites() {
    install_prereqs_debian
    setup_java
    install_android_sdk
    setup_gradle
}

show_menu() {
    echo ""
    echo "GOZAR Native Android Build Script"
    echo "=================================="
    echo ""
    echo "1) Install all prerequisites"
    echo "2) Setup signing configuration"
    echo "3) Build debug APK"
    echo "4) Build release APK + AAB"
    echo "5) Run unit tests"
    echo "6) Full build (install prereqs + build release)"
    echo "0) Exit"
    echo ""
}

main_menu() {
    while true; do
        show_menu
        read -r -p "Enter choice: " choice
        
        case "${choice:-}" in
            1) install_all_prerequisites ;;
            2) setup_signing_config ;;
            3) build_debug ;;
            4) build_release ;;
            5) run_tests ;;
            6) 
                install_all_prerequisites
                setup_signing_config
                build_release
                ;;
            0|q|Q) 
                echo "Exiting."
                exit 0 
                ;;
            *) 
                error "Invalid choice: $choice"
                ;;
        esac
    done
}

# Main execution
check_prerequisites
mkdir -p "$DIST_DIR"

# If arguments provided, run non-interactively
if [[ $# -gt 0 ]]; then
    case "$1" in
        install) install_all_prerequisites ;;
        debug) build_debug ;;
        release) build_release ;;
        test) run_tests ;;
        full) 
            install_all_prerequisites
            build_release
            ;;
        *)
            echo "Usage: $0 [install|debug|release|test|full]"
            echo "  install - Install prerequisites"
            echo "  debug   - Build debug APK"
            echo "  release - Build release APK and AAB"
            echo "  test    - Run unit tests"
            echo "  full    - Install prerequisites and build release"
            echo ""
            echo "Run without arguments for interactive menu."
            exit 1
            ;;
    esac
else
    main_menu
fi

echo ""
echo "${GREEN}Done.${NC}"
