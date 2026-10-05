package ir.salehtz.snag

import org.json.JSONObject

/**
 * What the foreground notification knows about one running download.
 *
 * youtubedl-android's own progress callback parses yt-dlp's default
 * "[download]  42.0%" lines, which Snag replaces with machine-readable
 * SNAG_* lines (see lib/engine/args_builder.dart). So the notification
 * reads those lines itself, mirroring lib/engine/output_parser.dart.
 */
class TaskProgress {
    @Volatile var percent = 0f
    @Volatile var title: String? = null
    @Volatile var processing = false

    /** Updates from one output line. Returns true if anything changed. */
    fun update(line: String): Boolean = when {
        // Order matters: SNAG_PP also starts with SNAG_P.
        line.startsWith("SNAG_PP") -> {
            processing = true
            true
        }
        line.startsWith("SNAG_P{") -> json(line, 6)?.let { onProgress(it) } ?: false
        line.startsWith("SNAG_I{") -> json(line, 6)?.let { meta ->
            meta.optString("title").takeIf { it.isNotBlank() }?.let { title = it }
            true
        } ?: false
        else -> false
    }

    private fun onProgress(p: JSONObject): Boolean {
        val done = p.optDouble("downloaded_bytes")
        var total = p.optDouble("total_bytes")
        if (total.isNaN() || total <= 0) total = p.optDouble("total_bytes_estimate")
        val fraction = when {
            !done.isNaN() && !total.isNaN() && total > 0 -> done / total
            else -> {
                // HLS/DASH: fragments are the only measure.
                val index = p.optDouble("fragment_index")
                val count = p.optDouble("fragment_count")
                if (!index.isNaN() && !count.isNaN() && count > 0) index / count else return false
            }
        }
        // A new stream (video, then audio) starts over; that is not processing.
        processing = false
        percent = (fraction * 100).toFloat().coerceIn(0f, 100f)
        return true
    }

    private fun json(line: String, prefix: Int): JSONObject? =
        try { JSONObject(line.substring(prefix)) } catch (_: Exception) { null }
}
