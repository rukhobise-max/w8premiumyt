-- W8PREMIUMYT Supabase Setup Script
-- Copy & paste ini ke Supabase SQL Editor untuk setup otomatis

-- ========================================
-- 1. CREATE SMS_INBOX TABLE
-- ========================================
CREATE TABLE IF NOT EXISTS sms_inbox (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  device_id TEXT NOT NULL DEFAULT 'unknown',
  sender TEXT NOT NULL,
  message TEXT NOT NULL,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE sms_inbox ENABLE ROW LEVEL SECURITY;

-- Create index untuk faster queries
CREATE INDEX IF NOT EXISTS idx_sms_timestamp ON sms_inbox(timestamp DESC);

-- ========================================
-- 2. CREATE DEVICE_STATUS TABLE
-- ========================================
CREATE TABLE IF NOT EXISTS device_status (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  device_id TEXT NOT NULL UNIQUE,
  device_name TEXT,
  status TEXT DEFAULT 'ONLINE' CHECK (status IN ('ONLINE', 'OFFLINE')),
  battery_level INT CHECK (battery_level >= 0 AND battery_level <= 100),
  last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE device_status ENABLE ROW LEVEL SECURITY;

-- Create index
CREATE INDEX IF NOT EXISTS idx_device_status ON device_status(device_id);

-- ========================================
-- 3. SMS_INBOX ROW LEVEL SECURITY POLICIES
-- ========================================

-- Public read access
CREATE POLICY "Allow public read on sms_inbox" 
ON sms_inbox 
FOR SELECT 
USING (true);

-- Public insert access
CREATE POLICY "Allow public insert on sms_inbox" 
ON sms_inbox 
FOR INSERT 
WITH CHECK (true);

-- Optional: Allow update (for marking as read, etc)
CREATE POLICY "Allow public update on sms_inbox" 
ON sms_inbox 
FOR UPDATE 
USING (true)
WITH CHECK (true);

-- ========================================
-- 4. DEVICE_STATUS ROW LEVEL SECURITY POLICIES
-- ========================================

-- Public read access
CREATE POLICY "Allow public read on device_status" 
ON device_status 
FOR SELECT 
USING (true);

-- Public insert access (for new devices)
CREATE POLICY "Allow public insert on device_status" 
ON device_status 
FOR INSERT 
WITH CHECK (true);

-- Public update access (for status updates)
CREATE POLICY "Allow public update on device_status" 
ON device_status 
FOR UPDATE 
USING (true)
WITH CHECK (true);

-- ========================================
-- 5. OPTIONAL: TRIGGER FOR AUTO UPDATE TIMESTAMP
-- ========================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_device_status_timestamp
BEFORE UPDATE ON device_status
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

-- ========================================
-- 6. OPTIONAL: VIEW UNTUK MONITORING
-- ========================================

CREATE OR REPLACE VIEW sms_last_24h AS
SELECT 
  COUNT(*) as total_sms,
  COUNT(DISTINCT sender) as unique_senders,
  MAX(timestamp) as last_sms,
  device_id
FROM sms_inbox
WHERE timestamp > NOW() - INTERVAL '24 hours'
GROUP BY device_id;

-- ========================================
-- 7. CHECK RLS STATUS
-- ========================================
-- Run this to verify RLS is enabled:
-- SELECT tablename, rowsecurity FROM pg_tables WHERE tablename IN ('sms_inbox', 'device_status');

-- ========================================
-- 8. INSERT TEST DATA (Optional)
-- ========================================

-- Test SMS
INSERT INTO sms_inbox (sender, message) VALUES
('+6281234567890', 'Test SMS 1 - OTP: 123456'),
('+6282345678901', 'Test SMS 2 - Welcome!'),
('+6283456789012', 'Test SMS 3 - Verification code: 654321');

-- Test Device Status
INSERT INTO device_status (device_id, device_name, status, battery_level) VALUES
('device_001', 'Samsung Galaxy A12', 'ONLINE', 85),
('device_002', 'Xiaomi Redmi Note 10', 'OFFLINE', 0)
ON CONFLICT (device_id) DO UPDATE SET
status = EXCLUDED.status,
battery_level = EXCLUDED.battery_level,
updated_at = NOW();

-- ========================================
-- Setup Complete!
-- ========================================
-- Verifikasi dengan queries:
-- SELECT COUNT(*) FROM sms_inbox;
-- SELECT * FROM device_status;
-- SELECT * FROM sms_inbox ORDER BY created_at DESC LIMIT 5;
