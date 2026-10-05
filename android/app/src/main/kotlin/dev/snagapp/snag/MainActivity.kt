package dev.snagapp.snag

import android.Manifest
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.Settings
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

    /** Waiting for the user to come back from the "All files access" screen. */
    private var pendingAllFiles: MethodChannel.Result? = null

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
                    "requestAllFilesAccess" -> requestAllFilesAccess(result)
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        pendingShare = sharedText(intent)
    }

    override fun onResume() {
        super.onResume()
        pendingAllFiles?.success(hasAllFilesAccess())
        pendingAllFiles = null
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
    // Android 11+: apps may create files in Download/ and Documents/ freely;
    // any other folder needs "All files access" (MANAGE_EXTERNAL_STORAGE).

    private val needsLegacyPermission = Build.VERSION.SDK_INT <= Build.VERSION_CODES.Q

    private fun legacyStorageGranted() =
        !needsLegacyPermission || granted(Manifest.permission.WRITE_EXTERNAL_STORAGE)

    private fun hasAllFilesAccess(): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Environment.isExternalStorageManager()
        } else {
            legacyStorageGranted()
        }

    private fun storageStatus(): Map<String, Any> = mapOf(
        "sdk" to Build.VERSION.SDK_INT,
        "needsLegacyPermission" to needsLegacyPermission,
        "legacyGranted" to legacyStorageGranted(),
        "allFilesAccess" to hasAllFilesAccess(),
        "externalRoot" to Environment.getExternalStorageDirectory().absolutePath,
    )

    private fun requestLegacyStorage(result: MethodChannel.Result) {
        if (legacyStorageGranted()) return result.success(true)
        ask(Manifest.permission.WRITE_EXTERNAL_STORAGE, STORAGE_REQUEST, result)
    }

    private fun requestAllFilesAccess(result: MethodChannel.Result) {
        if (hasAllFilesAccess()) return result.success(true)
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return requestLegacyStorage(result)
        pendingAllFiles?.success(false)
        pendingAllFiles = result
        val app = Intent(
            Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
            Uri.parse("package:$packageName"),
        )
        try {
            startActivity(app)
        } catch (_: ActivityNotFoundException) {
            // Some ROMs only offer the global list.
            startActivity(Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION))
        }
    }

    companion object {
        private const val NOTIFY_REQUEST = 8
        private const val STORAGE_REQUEST = 9
    }
}
