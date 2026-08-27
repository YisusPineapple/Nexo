package io.github.yisus.nexo

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {

    companion object {
        private const val DIAGNOSTICS_CHANNEL =
            "io.github.yisus.nexo/notification_diagnostics"
        private const val AUDIO_CHANNEL_ID =
            "io.github.yisus.nexo.channel.audio.v5"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Nexo Music Playback"
            val descriptionText = "Media playback controls and lockscreen widget"
            val importance = NotificationManager.IMPORTANCE_DEFAULT
            val channel = NotificationChannel(AUDIO_CHANNEL_ID, name, importance).apply {
                description = descriptionText
                setShowBadge(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            val notificationManager: NotificationManager =
                getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DIAGNOSTICS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getNotificationDiagnostics" -> result.success(collectDiagnostics())
                    "openAutostartSettings" -> result.success(openAutostartSettings())
                    else -> result.notImplemented()
                }
            }
    }

    private fun openAutostartSettings(): Boolean {
        try {
            // Attempt 1: Explicit intent to Transsion's Phone Master
            val intent = Intent()
            intent.setClassName("com.transsion.phonemanager", "com.transsion.phonemanager.MainActivity")
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            return true
        } catch (e: Exception) {
            try {
                // Attempt 2: Let the system resolve the launcher intent for the package
                val intent = packageManager.getLaunchIntentForPackage("com.transsion.phonemanager")
                if (intent != null) {
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    return true
                }
            } catch (e2: Exception) {
                // Ignore and proceed to fallback
            }
            
            try {
                // Attempt 3: Fallback to standard Android App Details Settings
                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                intent.data = Uri.parse("package:$packageName")
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                return true
            } catch (e3: Exception) {
                return false
            }
        }
        return false
    }

    private fun collectDiagnostics(): Map<String, Any?> {
        val notificationManagerCompat = NotificationManagerCompat.from(this)
        val appLevelEnabled = notificationManagerCompat.areNotificationsEnabled()

        var channelExists = false
        var channelImportanceValue: Int? = null
        var channelImportanceLabel = "unknown"
        var activeCountTotal = 0
        var hasAudioChannelNotification = false

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            val channel = nm.getNotificationChannel(AUDIO_CHANNEL_ID)
            if (channel != null) {
                channelExists = true
                channelImportanceValue = channel.importance
                channelImportanceLabel = importanceToLabel(channel.importance)
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            val active = nm.activeNotifications
            activeCountTotal = active.size
            hasAudioChannelNotification =
                active.any { it.notification.channelId == AUDIO_CHANNEL_ID }
        }

        return mapOf(
            "sdkInt" to Build.VERSION.SDK_INT,
            "manufacturer" to Build.MANUFACTURER,
            "model" to Build.MODEL,
            "appLevelNotificationsEnabled" to appLevelEnabled,
            "channelId" to AUDIO_CHANNEL_ID,
            "channelExists" to channelExists,
            "channelImportanceValue" to channelImportanceValue,
            "channelImportanceLabel" to channelImportanceLabel,
            "activeNotificationCountTotal" to activeCountTotal,
            "hasActiveAudioChannelNotification" to hasAudioChannelNotification,
        )
    }

    private fun importanceToLabel(importance: Int): String {
        return when (importance) {
            NotificationManager.IMPORTANCE_NONE -> "NONE (blocked by system)"
            NotificationManager.IMPORTANCE_MIN -> "MIN"
            NotificationManager.IMPORTANCE_LOW -> "LOW"
            NotificationManager.IMPORTANCE_DEFAULT -> "DEFAULT"
            NotificationManager.IMPORTANCE_HIGH -> "HIGH"
            NotificationManager.IMPORTANCE_MAX -> "MAX"
            else -> "UNSPECIFIED ($importance)"
        }
    }
}
