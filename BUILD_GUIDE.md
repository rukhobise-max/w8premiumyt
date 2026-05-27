# W8PREMIUMYT - Build & Setup Guide

## 📋 Prasyarat

Sebelum memulai, pastikan Anda memiliki:

### 1. **Flutter SDK**
```bash
# Download dari https://flutter.dev/docs/get-started/install
# Atau gunakan manager favorit:
# macOS:
brew install flutter

# Linux:
sudo snap install flutter --classic

# Windows:
# Download installer dari flutter.dev
```

### 2. **Android SDK & Tools**
```bash
# Install Android Studio
# https://developer.android.com/studio

# Atau gunakan command line tools:
# https://developer.android.com/studio/command-line
```

### 3. **Verifikasi Setup**
```bash
flutter doctor

# Output harus:
# ✓ Flutter (Channel stable)
# ✓ Android toolchain
# ✓ Android SDK
# ✓ Connected device (atau emulator)
```

---

## 🔧 Konfigurasi Proyek

### 1. **Update .env File**

Edit file `/android_app/.env`:

```env
# Supabase Configuration
SUPABASE_URL=https://jgextdbcuomnqhcfpmfi.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_KEY=your-service-key-here

# Backend API Configuration
API_URL=http://your-backend-api.com
API_KEY=your-api-key

# Device Configuration
DEVICE_NAME=W8PREMIUMYT Gateway
```

**Dapatkan kredensial dari Supabase:**
1. Buka https://app.supabase.com
2. Login dengan akun Anda
3. Buka project Anda
4. Settings → API
5. Copy `Project URL` dan `anon public key`

### 2. **Update Tabel Supabase**

Buat 2 tabel di Supabase database:

#### a. Tabel `sms_inbox`
```sql
CREATE TABLE sms_inbox (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  sender TEXT NOT NULL,
  message TEXT NOT NULL,
  timestamp TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE sms_inbox ENABLE ROW LEVEL SECURITY;

-- Policy untuk read
CREATE POLICY "Allow public read" ON sms_inbox
FOR SELECT USING (true);

-- Policy untuk insert
CREATE POLICY "Allow public insert" ON sms_inbox
FOR INSERT WITH CHECK (true);
```

#### b. Tabel `device_status`
```sql
CREATE TABLE device_status (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  device_id TEXT NOT NULL UNIQUE,
  device_name TEXT,
  status TEXT DEFAULT 'ONLINE',
  battery_level INT,
  last_seen TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE device_status ENABLE ROW LEVEL SECURITY;

-- Policy
CREATE POLICY "Allow public read" ON device_status
FOR SELECT USING (true);

CREATE POLICY "Allow public update/insert" ON device_status
FOR UPDATE WITH CHECK (true);

CREATE POLICY "Allow public insert" ON device_status
FOR INSERT WITH CHECK (true);
```

---

## 🚀 Build APK

### Opsi 1: Menggunakan Build Script (Recommended)

```bash
# Navigate ke project root
cd w8premiumyt

# Buat script executable
chmod +x build_apk.sh

# Jalankan script
./build_apk.sh
```

### Opsi 2: Manual Build

```bash
# Navigate ke android_app
cd android_app

# Clean & get dependencies
flutter clean
flutter pub get

# Check setup
flutter doctor -v

# Build APK Release
flutter build apk --release

# Output file:
# build/app/outputs/apk/release/app-release.apk
```

### Opsi 3: Build AAB untuk Play Store

```bash
cd android_app

flutter build appbundle --release

# Output file:
# build/app/outputs/bundle/release/app-release.aab
```

---

## 📱 Install APK di Device

### Via USB Cable
```bash
# Pastikan device terhubung via USB
adb devices

# Install APK
adb install -r build/app/outputs/apk/release/app-release.apk

# Or reinstall jika sudah ada
adb install -r build/app/outputs/apk/release/app-release.apk
```

### Manual Install
1. Transfer file `.apk` ke device (via USB/Email/Cloud)
2. Buka file manager di device
3. Buka file APK
4. Install

**Pastikan enable "Install from Unknown Sources" di Settings!**

---

## 🌐 Setup Web Dashboard

### 1. **Pilih Web Server**

Opsi A: **Simple HTTP Server** (untuk testing lokal)
```bash
cd frontend
python3 -m http.server 8000
# Akses: http://localhost:8000
```

Opsi B: **Nginx** (untuk production)
```bash
# Install Nginx
sudo apt-get install nginx

# Copy frontend folder ke /var/www/html/
sudo cp -r frontend/* /var/www/html/

# Restart Nginx
sudo systemctl restart nginx

# Akses: http://localhost atau domain Anda
```

Opsi C: **Vercel/Netlify** (Cloud hosting - Recommended)
1. Push code ke GitHub
2. Connect repo di Vercel/Netlify
3. Deploy otomatis

### 2. **Update Frontend Configuration**

Edit `/frontend/index.html`:
```javascript
// Ganti dengan Supabase credentials Anda
const SUPABASE_URL = "https://your-project.supabase.co"
const SUPABASE_ANON_KEY = "your-anon-key"
```

---

## ✅ Testing

### 1. **Test SMS Gateway**
```bash
# Di Android device, settings izin:
# - Permissions → SMS, Phone, Contacts
# - Enable "W8PREMIUMYT" di app permissions

# Terima SMS test
# Seharusnya langsung muncul di dashboard web
```

### 2. **Real-time Testing**
1. Buka dashboard web di browser: http://localhost:8000
2. Buka app di Android device
3. Kirim SMS ke device
4. Lihat SMS langsung muncul di dashboard tanpa refresh!

### 3. **Check Status**
- Green indicator = Device ONLINE
- Red indicator = Device OFFLINE
- SMS counter menampilkan pending SMS

---

## 🔧 Troubleshooting

### Build Error: `FAILURE: Build failed`
```bash
# Solution
cd android_app
flutter clean
flutter pub get
flutter pub upgrade
flutter build apk --release
```

### Permission Error saat Build
```bash
# Buka android/build.gradle
# Pastikan compileSdk dan targetSdk = 34
# Rebuild
```

### Device tidak terdeteksi
```bash
# Check device
adb devices

# Jika tidak terlihat:
adb kill-server
adb start-server
adb devices
```

### APK Crash di Device
- Check logcat: `adb logcat`
- Cek .env configuration
- Ensure Supabase project aktif
- Check table RLS policies

### Dashboard tidak terima SMS
- Verify Supabase Real-time enabled
- Check RLS policies di table `sms_inbox`
- Verify app permissions di Android
- Check network connectivity

---

## 📊 Architecture

```
APK (Android Device)
  ├─ SMS Receiver (BroadcastReceiver)
  ├─ SmsReceiver.kt (Kirim ke Supabase REST API)
  └─ Flutter App (UI Status)
        └─ Supabase REST API
              
                    ↓
              
              Supabase Database
                ├─ sms_inbox table
                ├─ device_status table
                └─ Real-time Subscriptions
                    
                    ↓
              
        Web Dashboard (Browser)
              ├─ HTML/JavaScript
              ├─ Supabase Client JS
              └─ Real-time Listener
                    ↓
              Display SMS & Status
```

---

## 📞 Support

Jika ada masalah:

1. **Check Flutter Version**
   ```bash
   flutter --version
   # Harus >= 3.0.0
   ```

2. **Check Dependencies**
   ```bash
   cd android_app
   flutter pub get
   flutter pub upgrade
   ```

3. **View Build Logs**
   ```bash
   flutter build apk --release -v
   ```

4. **Check Supabase Status**
   - Buka https://app.supabase.com
   - Check project status
   - Verify table permissions

---

## 🎉 Sukses!

Setelah semuanya setup:
✓ APK terinstall di device
✓ SMS masuk di dashboard real-time
✓ Device status ter-track (ONLINE/OFFLINE)
✓ Offline queue sync otomatis

Nikmati SMS Gateway otomatis! 🚀
