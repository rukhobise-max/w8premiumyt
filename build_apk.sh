#!/bin/bash
# Build Script untuk W8PREMIUMYT APK
# Jalankan script ini di machine lokal dengan Flutter dan Android SDK terinstall

set -e

echo "================================"
echo "W8PREMIUMYT APK BUILD SCRIPT"
echo "================================"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check Flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter tidak terinstall!${NC}"
    echo "Install Flutter dari: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo -e "${GREEN}✓ Flutter found:$(flutter --version | head -n 1)${NC}"

# Navigate ke android_app
cd android_app

# Clean previous builds
echo -e "${BLUE}🧹 Cleaning previous builds...${NC}"
flutter clean

# Get dependencies
echo -e "${BLUE}📦 Getting dependencies...${NC}"
flutter pub get

# Check Android setup
echo -e "${BLUE}🤖 Checking Android setup...${NC}"
flutter doctor -v

# Check .env file
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️  .env file tidak ditemukan!${NC}"
    echo "Membuat .env dari template..."
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo -e "${YELLOW}⚠️  Edit .env dengan Supabase credentials Anda${NC}"
    fi
fi

# Build APK
echo -e "${BLUE}🔨 Building APK (Release Mode)...${NC}"
flutter build apk --release

APK_PATH="build/app/outputs/apk/release/app-release.apk"

if [ -f "$APK_PATH" ]; then
    echo -e "${GREEN}✅ APK berhasil dibuild!${NC}"
    echo -e "${GREEN}📱 Output: $APK_PATH${NC}"
    echo ""
    echo "File size: $(du -h $APK_PATH | cut -f1)"
    echo ""
    echo "Instruksi instalasi:"
    echo "1. Hubungkan Android device via USB"
    echo "2. Enable USB Debugging di device"
    echo "3. Jalankan: adb install -r $APK_PATH"
    echo ""
    echo "Atau transfer file APK ke device dan install manual"
else
    echo -e "${RED}❌ Build gagal!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build selesai!${NC}"
