# Docker Build Instructions

Build APK menggunakan Docker (tanpa perlu install Flutter/Android SDK lokal)

## Prerequisites
- Docker installed
- 5GB+ disk space
- Internet connection

## Build APK dengan Docker

### 1. Build Docker Image
```bash
cd w8premiumyt

docker build -t w8premiumyt-builder .
```

### 2. Run Build
```bash
docker run --rm \
  -v "$(pwd)/output:/output" \
  w8premiumyt-builder
```

### 3. Get APK
APK akan tersimpan di: `./output/app-release.apk`

---

## Quick One-Liner

```bash
docker build -t w8premiumyt-builder . && \
docker run --rm -v "$(pwd)/output:/output" w8premiumyt-builder && \
echo "✅ APK ready at: ./output/app-release.apk"
```

---

## Docker Compose (Alternative)

Buat `docker-compose.yml`:

```yaml
version: '3'
services:
  build:
    build: .
    volumes:
      - ./output:/output
    environment:
      - GRADLE_USER_HOME=/app/.gradle
```

Run:
```bash
docker-compose up
```

---

## Troubleshooting

### Build Timeout
Tambah timeout:
```bash
docker run --rm -v "$(pwd)/output:/output" -e GRADLE_OPTS="-Dorg.gradle.jvmargs=-Xmx4096m" w8premiumyt-builder
```

### Permission Denied
```bash
sudo docker run --rm -v "$(pwd)/output:/output" w8premiumyt-builder
```

### No APK Output
Check build logs:
```bash
docker build -t w8premiumyt-builder . -v
```
