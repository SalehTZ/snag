package ir.salehtz.snag

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import java.text.NumberFormat
import java.util.Locale

/**
 * Keeps the process alive while downloads run in the background, with one
 * calm progress notification. The work itself happens in [YtDlpBridge].
 */
class DownloadService : Service() {

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val count = YtDlpBridge.active.size
        if (count == 0) {
            ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
            stopSelf()
            return START_NOT_STICKY
        }
        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
        } else 0
        ServiceCompat.startForeground(this, NOTIFICATION_ID, build(count), type)
        return START_NOT_STICKY
    }

    private fun build(count: Int): Notification {
        ensureChannel(this)
        val tasks = YtDlpBridge.active.values.toList()
        val locale = Locale.forLanguageTag(YtDlpBridge.localeTag)
        val label = YtDlpBridge.downloadingLabel
        val processing = tasks.isNotEmpty() && tasks.all { it.processing }
        val percent = tasks
            .map { if (it.processing) 100f else it.percent }
            .average()
            .takeUnless { it.isNaN() } ?: 0.0
        // No numbers yet (or only ffmpeg work left): show an indeterminate bar.
        val indeterminate = processing || percent <= 0.0

        val title = if (count == 1) {
            tasks.firstOrNull()?.title ?: label
        } else {
            "$label (${NumberFormat.getIntegerInstance(locale).format(count)})"
        }
        val text = when {
            count == 1 && tasks.firstOrNull()?.title != null && indeterminate -> label
            indeterminate -> null
            else -> NumberFormat.getPercentInstance(locale).format(percent / 100)
        }

        val open = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE,
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.stat_sys_download)
            .setContentTitle(title)
            .setContentText(text)
            .setProgress(100, percent.toInt(), indeterminate)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setContentIntent(open)
            .build()
    }

    companion object {
        private const val CHANNEL_ID = "downloads"
        private const val NOTIFICATION_ID = 42

        /** Start, update or stop the service to match [YtDlpBridge.active]. */
        fun refresh(context: Context) {
            val intent = Intent(context, DownloadService::class.java)
            try {
                if (YtDlpBridge.active.isEmpty()) {
                    context.stopService(intent)
                } else {
                    ContextCompat.startForegroundService(context, intent)
                }
            } catch (_: Exception) {
                // Background start restrictions: downloads still run while the
                // app is visible, we just lose the notification.
            }
        }

        private fun ensureChannel(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
            val nm = context.getSystemService(NotificationManager::class.java)
            if (nm.getNotificationChannel(CHANNEL_ID) != null) return
            nm.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, "Downloads", NotificationManager.IMPORTANCE_LOW)
            )
        }
    }
}
