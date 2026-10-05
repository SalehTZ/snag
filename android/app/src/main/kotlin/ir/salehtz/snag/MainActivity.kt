package ir.salehtz.snag

import android.Manifest
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.Environment
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

    /** Results waiting for a permission dialog, keyed by request code. */
    private val pending = mutableMapOf<Int, MethodChannel.Result>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        YtDlpBridge.attach(this)
        MethodChannel(messenger, YtDlpBridge.METHOD_CHANNEL)
            .setMethodCallHandler(YtDlpBridge)
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
                    "storageStatus" -> result.success(storageStatus())
                    "requestLegacyStorage" -> requestLegacyStorage(result)
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

    private fun granted(permission: String) =
        ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED

    private fun ask(permission: String, code: Int, result: MethodChannel.Result) {
        pending.remove(code)?.success(false)
        pending[code] = result
        requestPermissions(arrayOf(permission), code)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        val result = pending.remove(requestCode) ?: return
        result.success(
            when (requestCode) {
                NOTIFY_REQUEST -> notificationsAllowed()
                STORAGE_REQUEST -> legacyStorageGranted()
                else -> false
            }
        )
    }

    // ------------------------------------------------------------ notifications

    private fun notificationsAllowed(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            granted(Manifest.permission.POST_NOTIFICATIONS)

    private fun requestNotifications(result: MethodChannel.Result) {
        if (notificationsAllowed()) return result.success(true)
        ask(Manifest.permission.POST_NOTIFICATIONS, NOTIFY_REQUEST, result)
    }

    // ------------------------------------------------------------ storage
    //
    // Android 9 and older: WRITE_EXTERNAL_STORAGE is needed for Download/.
    // Android 10: the app opts into legacy storage, which also needs it.
    // Android 11+: apps may create files in Download/ and Documents/ freely.
    // Snag deliberately does not ask for "All files access", so custom
    // folders must live inside one of those two.

    private val needsLegacyPermission = Build.VERSION.SDK_INT <= Build.VERSION_CODES.Q

    private fun legacyStorageGranted() =
        !needsLegacyPermission || granted(Manifest.permission.WRITE_EXTERNAL_STORAGE)

    private fun storageStatus(): Map<String, Any> = mapOf(
        "sdk" to Build.VERSION.SDK_INT,
        "needsLegacyPermission" to needsLegacyPermission,
        "legacyGranted" to legacyStorageGranted(),
        "externalRoot" to Environment.getExternalStorageDirectory().absolutePath,
    )

    private fun requestLegacyStorage(result: MethodChannel.Result) {
        if (legacyStorageGranted()) return result.success(true)
        ask(Manifest.permission.WRITE_EXTERNAL_STORAGE, STORAGE_REQUEST, result)
    }

    companion object {
        private const val NOTIFY_REQUEST = 8
        private const val STORAGE_REQUEST = 9
    }
}
