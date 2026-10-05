package dev.snagapp.snag

import android.content.Context
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.yausername.ffmpeg.FFmpeg
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLRequest
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors

/**
 * Runs yt-dlp through youtubedl-android (embedded Python + ffmpeg).
 *
 * Arguments are built in Dart and passed through untouched; every output line
 * is streamed back so parsing lives in one place (lib/engine/output_parser.dart).
 */
object YtDlpBridge : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    const val METHOD_CHANNEL = "snag/ytdlp"
    const val EVENT_CHANNEL = "snag/ytdlp/events"
    private const val TAG = "Snag"

    private val main = Handler(Looper.getMainLooper())
    private val pool = Executors.newCachedThreadPool()
    private var sink: EventChannel.EventSink? = null
    private lateinit var appContext: Context
    @Volatile private var initialized = false
    @Volatile private var lastNotify = 0L

    /** taskId -> last known percent, for the foreground notification. */
    val active = ConcurrentHashMap<String, Float>()
    private val cancelled = ConcurrentHashMap.newKeySet<String>()

    fun attach(context: Context) {
        appContext = context.applicationContext
    }

    // ------------------------------------------------------------- events

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    private fun emit(event: Map<String, Any?>) = main.post { sink?.success(event) }

    // ------------------------------------------------------------- methods

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "init" -> background(result) { ensureInit(); null }
            "downloadsDir" -> result.success(downloadsDir().absolutePath)
            "run" -> background(result) {
                ensureInit()
                val args = call.argument<List<String>>("args")!!
                YoutubeDL.getInstance().execute(request(args)).out
            }
            "start" -> {
                val taskId = call.argument<String>("taskId")!!
                val args = call.argument<List<String>>("args")!!
                start(taskId, args)
                result.success(null)
            }
            "cancel" -> {
                val taskId = call.argument<String>("taskId")!!
                if (active.containsKey(taskId)) {
                    cancelled.add(taskId)
                    YoutubeDL.getInstance().destroyProcessById(taskId)
                }
                result.success(null)
            }
            "version" -> background(result) { ensureInit(); version() }
            "update" -> background(result) {
                ensureInit()
                val channel = when (call.argument<String>("channel")) {
                    "nightly" -> YoutubeDL.UpdateChannel.NIGHTLY
                    else -> YoutubeDL.UpdateChannel.STABLE
                }
                when (YoutubeDL.getInstance().updateYoutubeDL(appContext, channel)) {
                    YoutubeDL.UpdateStatus.ALREADY_UP_TO_DATE -> "Already up to date (${version()})"
                    else -> "Updated to ${version()}"
                }
            }
            else -> result.notImplemented()
        }
    }

    @Synchronized
    private fun ensureInit() {
        if (initialized) return
        val start = System.currentTimeMillis()
        Log.i(TAG, "init: yt-dlp runtime")
        YoutubeDL.getInstance().init(appContext)
        Log.i(TAG, "init: ffmpeg (${System.currentTimeMillis() - start} ms)")
        FFmpeg.getInstance().init(appContext)
        Log.i(TAG, "init: done in ${System.currentTimeMillis() - start} ms")
        initialized = true
    }

    /**
     * The library only records a version after an update; for the bundled
     * copy, ask yt-dlp itself.
     */
    private fun version(): String =
        YoutubeDL.getInstance().version(appContext)
            ?: YoutubeDL.getInstance().execute(request(listOf("--version"))).out.trim()

    private fun request(args: List<String>) =
        YoutubeDLRequest(emptyList<String>()).addCommands(args)

    private fun start(taskId: String, args: List<String>) {
        cancelled.remove(taskId)
        active[taskId] = 0f
        DownloadService.refresh(appContext)
        pool.execute {
            val tail = ArrayDeque<String>()
            try {
                ensureInit()
                YoutubeDL.getInstance().execute(
                    request(args),
                    taskId,
                    true, // merge stderr: post-processing + errors arrive as lines
                ) { progress, _, line ->
                    if (progress > 0) {
                        active[taskId] = progress
                        val now = System.currentTimeMillis()
                        if (now - lastNotify > 1000) {
                            lastNotify = now
                            DownloadService.refresh(appContext)
                        }
                    }
                    if (line.isNotBlank()) {
                        if (tail.size >= 40) tail.removeFirst()
                        tail.addLast(line)
                        emit(mapOf("taskId" to taskId, "type" to "line", "line" to line))
                    }
                }
                emit(mapOf("taskId" to taskId, "type" to "done"))
            } catch (e: Throwable) {
                if (cancelled.remove(taskId)) {
                    emit(mapOf("taskId" to taskId, "type" to "cancelled"))
                } else {
                    Log.e(TAG, "download $taskId failed", e)
                    val message = (tail.joinToString("\n") + "\n" + describe(e)).trim()
                    emit(mapOf("taskId" to taskId, "type" to "error", "message" to message))
                }
            } finally {
                active.remove(taskId)
                DownloadService.refresh(appContext)
            }
        }
    }

    private fun <T> background(result: MethodChannel.Result, work: () -> T) {
        pool.execute {
            try {
                val value = work()
                main.post { result.success(value) }
            } catch (e: Throwable) {
                Log.e(TAG, "yt-dlp call failed", e)
                main.post { result.error("ytdlp", describe(e), Log.getStackTraceString(e)) }
            }
        }
    }

    /** "IOException: disk full (caused by ...)", never a bare class name. */
    private fun describe(e: Throwable): String {
        val parts = mutableListOf<String>()
        var t: Throwable? = e
        while (t != null && parts.size < 4) {
            parts += "${t.javaClass.simpleName}: ${t.message ?: "no message"}"
            t = t.cause
        }
        return parts.joinToString("\ncaused by ")
    }

    @Suppress("DEPRECATION")
    fun downloadsDir(): File =
        File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), "Snag")
}
