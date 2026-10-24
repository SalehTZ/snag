# Changelog

What's new in each Snag release. When a version is tagged, the release workflow puts its section at the top of the GitHub release notes, followed by the download table and checksums. Write for people using Snag: what they can do now, in plain words, one line per paragraph or item (GitHub shows line breaks as they are).

## 0.2.0 - 2026-10-24

Snag now downloads more than videos: plain files, torrents and magnet links, with pause and resume.

### New

- **Any file link.** Links to a .zip, .apk, .iso or any other file now download, instead of stopping at "unsupported". Snag uses several connections at once, and you can pause and resume.
- **Torrents and magnet links.** Paste a magnet link or a .torrent URL, or open a magnet link from your browser on Android. Snag stops sharing once the download is done.
- **Connections per download.** Choose 1 to 16 in Settings, and run up to 8 downloads at once.
- **Translate Snag on Weblate.** New languages can arrive from translators without waiting on a code change.

### Fixed

- Your half-typed link is still there when you come back to Home from another tab.
- Sharing a link to Snag on Android no longer opens a second copy inside the other app, whose queue disappeared when you went back.
- Messages at the bottom of the screen go away on their own again.

### Good to know

- On Windows and Linux, Snag installs aria2 for you (Settings > Components). On macOS, install it with `brew install aria2` and Snag finds it.
- After 5, 50 and 250 downloads, Home asks once whether you'd like to support Snag. Close it and it stays away until the next one.

## 0.1.0 - 2026-10-05

The first release of Snag: paste a link, get the file. Free and open source on Android, Windows, macOS and Linux, with no ads and no tracking.

### Highlights

- **One box, one button.** Paste a link or drop it on the window. Snag spots links you've already copied.
- **Video or audio.** Pick a quality up to 4K, or save MP3, M4A, Opus or FLAC. By default you get H.264 + AAC in MP4, so files just play.
- **Over a thousand sites.** YouTube, Instagram, TikTok, X, SoundCloud, Vimeo and everything else yt-dlp supports.
- **Whole playlists and a real queue.** Pick the items you want; follow live speed, ETA and size; cancel, retry and run several downloads at once.
- **Library.** Search everything you've downloaded, open it, show it in its folder or grab it again.
- **Power tools when you want them.** Exact format picker, command templates, cookies, proxy, speed limit, SponsorBlock, subtitles and chapters.
- **English and فارسی.** Full right-to-left layout, Persian digits and the Solar Hijri calendar.
- **Stays current.** Update yt-dlp from Settings > Components with one tap when a site changes.
