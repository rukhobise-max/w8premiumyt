# W8PREMIUMYT - SMS Gateway + Web Dashboard

**Automatic SMS Gateway with Real-Time Web Dashboard**

Aplikasi Android + Web Dashboard untuk menerima SMS otomatis dan menampilkannya secara real-time di web dashboard yang terhubung ke Supabase.

## 🎯 Fitur Utama

✅ **Android SMS Gateway**
- Intercept SMS otomatis
- Send ke Supabase secara real-time
- Offline queue (jika koneksi putus, akan retry)
- Background service berjalan terus
- Battery & device monitoring
- Device status tracking

✅ **Web Dashboard**
- Real-time SMS display
- Device status indicator (ONLINE/OFFLINE)
- Dark theme responsive
- Live updates tanpa refresh
- SMS history

✅ **Integration**
- Fully integrated dengan Supabase
- Rest API untuk SMS
- PostgreSQL Realtime untuk live updates
- Row Level Security (RLS) untuk safety

## 📦 Project Structure

```
w8premiumyt/
├── android_app/              # Flutter + Native Android
│   ├── lib/main.dart        # Flutter app
│   ├── android/
│   │   └── app/src/main/
│   │       ├── kotlin/
│   │       │   └── SmsReceiver.kt  # SMS receiver native
│   │       └── AndroidManifest.xml
│   ├── pubspec.yaml         # Flutter dependencies
│   ├── .env                 # Configuration
│   └── build_apk.sh         # Build script
│
├── frontend/                 # Web Dashboard
│   └── index.html           # HTML + JavaScript
│
├── BUILD_GUIDE.md           # Detailed build guide
├── supabase_setup.sql       # Database setup script
└── README.md                # This file
```

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.0+
- Android SDK & Tools
- Java 11+
- Supabase Account (free)

### 1. Clone & Setup
```bash
git clone https://github.com/rukhobise-max/w8premiumyt.git
cd w8premiumyt
```

### 2. Setup Supabase

1. Buat project baru di https://app.supabase.com
2. Copy Supabase URL & anon key
3. Update `.env` di folder `android_app/`:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```
4. Update frontend `index.html` dengan credentials yang sama
5. Run SQL setup script (`supabase_setup.sql`) di Supabase SQL Editor

### 3. Build APK
```bash
chmod +x build_apk.sh
./build_apk.sh
```

Atau manual:
```bash
cd android_app
flutter clean && flutter pub get
flutter build apk --release
```

APK output: `build/app/outputs/apk/release/app-release.apk`

### 4. Install APK
```bash
adb install -r build/app/outputs/apk/release/app-release.apk
```

### 5. Run Web Dashboard
```bash
cd frontend
python3 -m http.server 8000
# Akses: http://localhost:8000
```

## 🔐 Security

- Row Level Security (RLS) enabled di semua tables
- Anonymous key hanya untuk read/insert
- Service key untuk backend operations
- HTTPS recommended untuk production

## 📱 How It Works

```
Android Device
  ↓
[SMS Received]
  ↓
SmsReceiver.kt
  ↓
[HTTP POST → Supabase REST API]
  ↓
Supabase Database
(sms_inbox table)
  ↓
Web Dashboard
  ↓
[Realtime listener detects INSERT]
  ↓
Display SMS instantly!
```

## 🛠️ Configuration Files

### Android App (.env)
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
API_URL=https://your-project.supabase.co
API_KEY=your-anon-key
DEVICE_NAME=W8PREMIUMYT Gateway
```

### Web Dashboard (index.html)
```javascript
const SUPABASE_URL = "https://your-project.supabase.co"
const SUPABASE_ANON_KEY = "your-anon-key"
```

### Kotlin (SmsReceiver.kt)
```kotlin
private val supabaseUrl = "https://your-project.supabase.co"
private val supabaseAnonKey = "your-anon-key"
```

## 📊 Supabase Database Schema

### sms_inbox table
| Column | Type | Notes |
|--------|------|-------|
| id | BIGINT | PK |
| sender | TEXT | Phone number |
| message | TEXT | SMS content |
| timestamp | TIMESTAMP | SMS time |
| created_at | TIMESTAMP | Insert time |

### device_status table
| Column | Type | Notes |
|--------|------|-------|
| id | BIGINT | PK |
| device_id | TEXT | UNIQUE |
| device_name | TEXT | Brand + Model |
| status | TEXT | ONLINE/OFFLINE |
| battery_level | INT | % |
| last_seen | TIMESTAMP | - |
| updated_at | TIMESTAMP | - |

## 🔧 Troubleshooting

### Build Fails
```bash
cd android_app
flutter clean
flutter pub get
flutter doctor -v
flutter build apk --release -v
```

### Device not recognized
```bash
adb kill-server
adb start-server
adb devices
```

### Dashboard no data
- Verify Supabase credentials
- Check RLS policies
- Verify sms_inbox table has data
- Check browser console (F12)

### SMS not appearing
- Ensure SMS permissions granted
- Check device internet connection
- Verify .env configuration
- Check Supabase project status

## 📚 Documentation

- **[BUILD_GUIDE.md](BUILD_GUIDE.md)** - Detailed build instructions
- **[frontend/README.md](frontend/README.md)** - Web dashboard guide
- **[supabase_setup.sql](supabase_setup.sql)** - Database setup

## 🎓 Learning Resources

- Flutter: https://flutter.dev/docs
- Supabase: https://supabase.com/docs
- Android: https://developer.android.com
- Kotlin: https://kotlinlang.org/docs

## 📄 License

MIT License - feel free to use for personal/commercial projects

## 👨‍💻 Author

Developed for automated SMS gateway + real-time dashboard

## 🤝 Contributing

Pull requests welcome! 

1. Fork repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

## 🚀 Next Steps

After setup:
1. ✅ Build APK
2. ✅ Install on device
3. ✅ Run web dashboard
4. ✅ Test SMS reception
5. ✅ Deploy dashboard to cloud (Vercel/Netlify)
6. ✅ Monitor in production

## 💬 Support

Untuk bantuan atau pertanyaan:
- Check BUILD_GUIDE.md section Troubleshooting
- Review Supabase documentation
- Check Flutter doctor output
- View APK logs: `adb logcat`

---

**Happy SMS Gateway! 🎉**
