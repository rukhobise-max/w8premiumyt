import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

// ============================================
// GLOBAL VARIABLES
// ============================================
final Battery battery = Battery();
Database? _database;

const String apiUrl = 'https://oycyuxxqmeqvyaipknkr.supabase.co';
const String apiKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im95Y3l1eHhxbWVxdnlhaXBrbmtyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk4MTc4MzMsImV4cCI6MjA5NTM5MzgzM30.LAECvRwsBvEPOz19l8cy8Hct2F4j0Lta9I-GPmIFcHI';
String deviceId = '';
String deviceName = '';

// ============================================
// MAIN FUNCTION
// ============================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init database
  await initDatabase();

  // Init device info
  await initDeviceInfo();

  runApp(MyApp());
}

// ============================================
// INIT DATABASE (SQFLITE - OFFLINE QUEUE)
// ============================================
Future<void> initDatabase() async {
  final databasePath = await getDatabasesPath();
  final dbPath = path.join(databasePath, 'sms_queue.db');
  
  _database = await openDatabase(
    dbPath,
    version: 1,
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE sms_queue(id INTEGER PRIMARY KEY AUTOINCREMENT, sender TEXT, message TEXT, timestamp TEXT, synced INTEGER DEFAULT 0)',
      );
    },
  );
  
  print("✅ Database initialized");
}

// ============================================
// INIT DEVICE INFO
// ============================================
Future<void> initDeviceInfo() async {
  final prefs = await SharedPreferences.getInstance();
  
  // Ambil atau generate device ID
  deviceId = prefs.getString('device_id') ?? '';
  
  if (deviceId.isEmpty) {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    deviceId = androidInfo.id;
    await prefs.setString('device_id', deviceId);
  }
  
  // Device name
  final deviceInfo = DeviceInfoPlugin();
  final androidInfo = await deviceInfo.androidInfo;
  deviceName = '${androidInfo.brand} ${androidInfo.model}';
  
  print("📱 Device ID: $deviceId");
  print("📱 Device Name: $deviceName");
}

// ============================================
// ============================================
// SEND SMS TO BACKEND
// ============================================
Future<void> sendSmsToBackend({
  required String sender,
  required String messageBody,
  required String timestamp,
}) async {
  final url = '$apiUrl/rest/v1/sms_inbox';
  
  final payload = {
    'device_id': deviceId,
    'sender': sender,
    'message': messageBody,
    'timestamp': timestamp,
  };
  
  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'apikey': apiKey,
        'Authorization': 'Bearer $apiKey',
        'Prefer': 'return=representation',
      },
      body: json.encode(payload),
    ).timeout(Duration(seconds: 10));
    
    if (response.statusCode == 201 || response.statusCode == 204) {
      print("✅ SMS berhasil dikirim ke Supabase");
    } else {
      print("❌ Gagal kirim SMS: ${response.statusCode}");
      // Simpan ke offline queue
      await saveToOfflineQueue(sender, messageBody, timestamp);
    }
  } catch (e) {
    print("❌ Error kirim SMS: $e");
    // Simpan ke offline queue
    await saveToOfflineQueue(sender, messageBody, timestamp);
  }
}

// ============================================
// SAVE TO OFFLINE QUEUE
// ============================================
Future<void> saveToOfflineQueue(String sender, String message, String timestamp) async {
  if (_database == null) await initDatabase();
  
  await _database!.insert('sms_queue', {
    'sender': sender,
    'message': message,
    'timestamp': timestamp,
    'synced': 0,
  });
  
  print("💾 SMS disimpan ke offline queue");
}

// ============================================
// SYNC OFFLINE QUEUE
// ============================================
Future<void> syncOfflineQueue() async {
  if (_database == null) return;
  
  final unsynced = await _database!.query(
    'sms_queue',
    where: 'synced = ?',
    whereArgs: [0],
  );
  
  if (unsynced.isEmpty) return;
  
  print("🔄 Syncing ${unsynced.length} SMS dari offline queue...");
  
  for (var sms in unsynced) {
    try {
      await sendSmsToBackend(
        sender: sms['sender'] as String,
        messageBody: sms['message'] as String,
        timestamp: sms['timestamp'] as String,
      );
      
      // Tandai sebagai synced
      await _database!.update(
        'sms_queue',
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [sms['id']],
      );
    } catch (e) {
      print("❌ Gagal sync SMS ID ${sms['id']}: $e");
    }
  }
  
  print("✅ Offline queue sync selesai");
}

// ============================================
// SEND HEARTBEAT
// ============================================
Future<void> sendHeartbeat() async {
  if (_database == null) await initDatabase();
  await initDeviceInfo();
  
  final url = '$apiUrl/rest/v1/device_status?on_conflict=device_id';
  
  int batteryLevel = 0;
  try {
    batteryLevel = await battery.batteryLevel;
  } catch (e) {
    batteryLevel = 0;
  }
  
  final payload = {
    'device_id': deviceId,
    'device_name': deviceName,
    'status': 'ONLINE',
    'battery_level': batteryLevel,
    'last_seen': DateTime.now().toUtc().toIso8601String(),
  };
  
  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'apikey': apiKey,
        'Authorization': 'Bearer $apiKey',
        'Prefer': 'resolution=merge-duplicates,return=representation',
      },
      body: json.encode([payload]),
    ).timeout(Duration(seconds: 10));
    
    if (response.statusCode == 201 || response.statusCode == 204) {
      print("💓 Heartbeat berhasil dikirim ke Supabase");
    } else {
      print("❌ Gagal kirim heartbeat: ${response.statusCode}");
    }
  } catch (e) {
    print("❌ Error kirim heartbeat: $e");
  }
}

// ============================================
// APP WIDGET
// ============================================
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'W8PREMIUMYT SMS Gateway',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: HomePage(),
    );
  }
}

// ============================================
// HOME PAGE
// ============================================
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int pendingQueue = 0;
  
  @override
  void initState() {
    super.initState();
    checkPermissions();
    loadPendingQueue();
  }
  
  // Check permissions
  Future<void> checkPermissions() async {
    final smsPermission = await Permission.sms.status;
    final phonePermission = await Permission.phone.status;
    
    if (!smsPermission.isGranted) {
      await Permission.sms.request();
    }
    
    if (!phonePermission.isGranted) {
      await Permission.phone.request();
    }
    
    // Request ignore battery optimization
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
    }
    
    // SMS akan ditangani oleh native BroadcastReceiver Android.
    // Pastikan pengguna memberikan izin SMS dan telepon.
  }
  
  
  // Load pending queue count
  Future<void> loadPendingQueue() async {
    if (_database == null) await initDatabase();
    
    final result = await _database!.query(
      'sms_queue',
      where: 'synced = ?',
      whereArgs: [0],
    );
    
    setState(() {
      pendingQueue = result.length;
    });
  }
  
  // Manual sync
  Future<void> manualSync() async {
    await syncOfflineQueue();
    await loadPendingQueue();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ Sinkronisasi selesai')),
    );
  }
  
  // Manual heartbeat
  Future<void> manualHeartbeat() async {
    await sendHeartbeat();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('💓 Heartbeat dikirim')),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('W8PREMIUMYT SMS Gateway'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
// Device Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Device: $deviceName',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Realtime SMS gateway aktif via native Android receiver.',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Pending Queue
            Card(
              child: ListTile(
                leading: Icon(Icons.queue, color: Colors.orange),
                title: Text('SMS Pending'),
                trailing: Text(
                  '$pendingQueue',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Buttons
            ElevatedButton.icon(
              onPressed: manualSync,
              icon: Icon(Icons.sync),
              label: Text('Sync Manual'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(16),
              ),
            ),
            
            SizedBox(height: 10),
            
            ElevatedButton.icon(
              onPressed: manualHeartbeat,
              icon: Icon(Icons.favorite),
              label: Text('Kirim Heartbeat'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(16),
              ),
            ),
            
            Spacer(),
            
            // Info
            Text(
              'Aplikasi berjalan otomatis di latar belakang.\nSemua SMS masuk akan dikirim ke server secara real-time.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}