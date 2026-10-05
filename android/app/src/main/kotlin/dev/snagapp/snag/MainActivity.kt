package dev.snagapp.snag

import android.Manifest
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.webkit.MimeTypeMap
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private var platform: MethodChannel? = null
    private var pendingShare: String? = null
    private var pendingPermission: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        YtDlpBridge.attach(this)
        MethodChannel(messenger, YtDlpBridge.METHOD_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "start") requestRuntimePermissions()
            YtDlpBridge.onMethodCall(call, result)
        }
        EventChannel(messenger, YtDlpBridge.EVENT_CHANNEL).setStreamHandler(YtDlpBridge)

        platform = MethodChannel(messenger, "snag/platform").apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "initialShare" -> {
                        result.success(pendingShare)
                        pendingShare = null
                    }
                    "openFile" -> result.success(openFile(call.argument<String>("path")!!))
                    "notificationsAllowed" -> result.success(notificationsAllowed())
                    "requestNotifications" -> requestNotifications(result)
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        pendingShare = sharedText(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val text = sharedText(intent) ?: return
        platform?.invokeMethod("shared", text)
    }

    private fun sharedText(intent: Intent?): String? = when (intent?.action) {
        Intent.ACTION_SEND -> intent.getStringExtra(Intent.EXTRA_TEXT)
        Intent.ACTION_VIEW -> intent.dataString
        else -> null
    }

    private fun openFile(path: String): Boolean {
        val file = File(path)
        if (!file.exists()) return false
        val uri = FileProvider.getUriForFile(this, "$packageName.files", file)
        val mime = MimeTypeMap.getSingleton()
            .getMimeTypeFromExtension(file.extension.lowercase()) ?: "*/*"
        val view = Intent(Intent.ACTION_VIEW)
            .setDataAndType(uri, mime)
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            startActivity(view)
            true
        } catch (_: ActivityNotFoundException) {
            false
        }
    }

    private fun notificationsAllowed(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED

    private fun requestNotifications(result: MethodChannel.Result) {
        if (notificationsAllowed()) return result.success(true)
        pendingPermission?.success(false)
        pendingPermission = result
        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), NOTIFY_REQUEST)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == NOTIFY_REQUEST) {
            pendingPermission?.success(notificationsAllowed())
            pendingPermission = null
        }
    }

    /**
     * Android 9 and older need storage permission to write to Download/.
     * Notifications are asked once during onboarding instead.
     */
    private fun requestRuntimePermissions() {
        if (Build.VERSION.SDK_INT > Build.VERSION_CODES.P) return
        val storage = Manifest.permission.WRITE_EXTERNAL_STORAGE
        if (ContextCompat.checkSelfPermission(this, storage) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(arrayOf(storage), 7)
        }
    }

    companion object {
        private const val NOTIFY_REQUEST = 8
    }
}
