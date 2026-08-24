package io.github.yisus.nexo

import android.app.NotificationManager
import android.os.Build
import androidx.core.app.NotificationManagerCompat
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {

    companion object {
        private const val DIAGNOSTICS_CHANNEL =
            "io.github.yisus.nexo/notification_diagnostics"
        private const val AUDIO_CHANNEL_ID =
            "io.github.yisus.nexo.channel.audio.v3"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DIAGNOSTICS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getNotificationDiagnostics" -> result.success(collectDiagnostics())
                    else -> result.notImplemented()
                }
            }
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