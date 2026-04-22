package com.meepaw.smarthome.smart_home_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.meepaw.smarthome/notifications"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Ensure channels are created as soon as the app process starts
        createNotificationChannels()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "showNotification") {
                val title = call.argument<String>("title") ?: "Smart Home"
                val body = call.argument<String>("body") ?: ""
                showNativeNotification(title, body)
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            
            // Channel for alerts
            val alertChannel = NotificationChannel(
                "smarthome_alerts",
                "Smart Home Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for device status and security"
            }
            notificationManager.createNotificationChannel(alertChannel)

            // Channel for background service (required by flutter_background_service)
            val serviceChannel = NotificationChannel(
                "smarthome_background",
                "Smart Home Background Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Handles background monitoring"
            }
            notificationManager.createNotificationChannel(serviceChannel)
        }
    }

    private fun showNativeNotification(title: String, body: String) {
        val context = applicationContext
        val channelId = "smarthome_alerts"
        val notificationId = 101

        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)

        try {
            val notificationManager = NotificationManagerCompat.from(context)
            notificationManager.notify(notificationId, builder.build())
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
