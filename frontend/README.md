# W8PREMIUMYT Frontend Dashboard

SMS Gateway Real-Time Dashboard terhubung dengan Supabase

## 🚀 Quick Start

### 1. **Update Configuration**

Edit `index.html` - ganti Supabase credentials:

```javascript
const SUPABASE_URL = "https://your-project.supabase.co"
const SUPABASE_ANON_KEY = "your-anon-key"
```

### 2. **Run Local Server**

```bash
# Navigate ke folder ini
cd frontend

# Option A: Python 3
python3 -m http.server 8000

# Option B: Node.js (dengan http-server)
npx http-server

# Option C: Live Server (VS Code extension)
# Right click index.html → Open with Live Server
```

Akses: http://localhost:8000

### 3. **Deploy ke Cloud**

#### Vercel (Recommended - Gratis)
```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel

# Konfigurasi domain custom di Vercel dashboard
```

#### Netlify
1. Push folder ke GitHub
2. Buka https://app.netlify.com
3. New site from Git
4. Select repository & deploy

#### Nginx
```bash
sudo cp index.html /var/www/html/
sudo systemctl restart nginx
```

## 🌟 Features

✓ Real-time SMS display
✓ Device status indicator (ONLINE/OFFLINE)
✓ Auto-refresh pada SMS baru
✓ Battery level tracking
✓ Last seen timestamp
✓ Dark theme dashboard
✓ Responsive design

## 📊 Supabase Tables Required

### `sms_inbox`
- `id` (BIGINT PK)
- `sender` (TEXT)
- `message` (TEXT)
- `timestamp` (TIMESTAMP)
- `created_at` (TIMESTAMP)

### `device_status`
- `id` (BIGINT PK)
- `device_id` (TEXT UNIQUE)
- `device_name` (TEXT)
- `status` (TEXT) - ONLINE/OFFLINE
- `battery_level` (INT)
- `last_seen` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

## 🔐 Security

**RLS Policies (Row Level Security)**

```sql
-- sms_inbox - Allow all read
CREATE POLICY "Allow public read" ON sms_inbox
FOR SELECT USING (true);

-- sms_inbox - Allow insert
CREATE POLICY "Allow public insert" ON sms_inbox
FOR INSERT WITH CHECK (true);

-- device_status - Allow all operations
CREATE POLICY "Allow public select" ON device_status
FOR SELECT USING (true);

CREATE POLICY "Allow public insert/update" ON device_status
FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow update" ON device_status
FOR UPDATE USING (true);
```

## 📱 How It Works

1. **SMS Received** on Android device
   ↓
2. **SmsReceiver.kt** intercepts SMS
   ↓
3. **Sends to Supabase** via REST API
   ↓
4. **Data inserted** to `sms_inbox` table
   ↓
5. **Dashboard listener** gets notified
   ↓
6. **SMS appears** instantly in browser!

## 🎨 Customization

Edit CSS dalam `<style>` tag:

```css
body {
    background-color: #121212;  /* Dark background */
    color: #ffffff;             /* Text color */
}

.indicator.online {
    background-color: #33ff33;  /* Online indicator */
}
```

## 🔧 Troubleshooting

### Dashboard blank/no data?
- Check Supabase credentials
- Verify RLS policies enabled
- Check browser console (F12)
- Verify sms_inbox table has data

### Real-time not working?
- Ensure Supabase Realtime enabled
- Check Network tab in browser DevTools
- Verify WebSocket connection: wss://...

### Permission error?
- Verify anon key has SELECT/INSERT permissions
- Check RLS policies (should allow true)

## 📞 Support

Check `BUILD_GUIDE.md` for detailed setup & troubleshooting
