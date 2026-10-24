import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:path/path.dart' as p;

import 'ytdlp_engine.dart';

/// A plain file on a web server, as far as its headers tell.
class RemoteFile {
  const RemoteFile({required this.url, required this.name, this.size});
  final String url;
  final String name;
  final int? size;

  String get host => isMagnet(url) ? '' : Uri.tryParse(url)?.host ?? '';
}

/// Extensions that name a file, not a page, so Snag can skip asking yt-dlp.
const _fileExtensions = {
  // Archives and disk images.
  'zip', '7z', 'rar', 'tar', 'gz', 'tgz', 'xz', 'bz2', 'zst', 'iso', 'img',
  // Installers and packages.
  'apk', 'apks', 'xapk', 'exe', 'msi', 'msix', 'dmg', 'pkg', 'deb', 'rpm',
  'appimage', 'flatpak', 'jar',
  // Documents and data.
  'pdf', 'epub', 'mobi', 'djvu', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
  'csv', 'json', 'txt', 'bin', 'torrent',
};

bool isMagnet(String url) => url.toLowerCase().startsWith('magnet:');

/// What a magnet link says about itself: its display name and, sometimes,
/// its size. Nothing to ask a server.
RemoteFile magnetFile(String url) {
  final params = Uri.tryParse(url)?.queryParameters ?? const {};
  final hash = params['xt']?.split(':').last;
  return RemoteFile(
    url: url,
    name: _safe(params['dn'] ?? '') ?? hash ?? 'magnet',
    size: int.tryParse(params['xl'] ?? ''),
  );
}

bool isTorrent(String url) =>
    isMagnet(url) ||
    (Uri.tryParse(url)?.path.toLowerCase().endsWith('.torrent') ?? false);

bool looksLikeFile(String url) {
  final path = Uri.tryParse(url)?.path ?? '';
  final ext = p.extension(path).replaceFirst('.', '').toLowerCase();
  return _fileExtensions.contains(ext);
}

/// Asks the server what is behind [url]. Returns null for a web page.
/// Throws [EngineException] when the server can't be reached or says no.
Future<RemoteFile?> probeFile(String url, {String? proxy}) async {
  final io = HttpClient()
    ..connectionTimeout = const Duration(seconds: 15)
    ..userAgent = 'Mozilla/5.0';
  // shortcut: only HTTP proxies are honoured here (and by aria2); SOCKS
  // users get a direct probe. Upgrade if people ask for SOCKS files.
  final proxyUri = proxy == null ? null : Uri.tryParse(proxy.trim());
  if (proxyUri != null && proxyUri.scheme.startsWith('http')) {
    io.findProxy = (_) => 'PROXY ${proxyUri.host}:${proxyUri.port}';
  }
  final client = IOClient(io);
  try {
    var res = await client.send(http.Request('HEAD', Uri.parse(url)));
    // Plenty of servers refuse HEAD; a one-byte GET says the same.
    if (res.statusCode >= 400) {
      await res.stream.drain<void>();
      res = await client.send(http.Request('GET', Uri.parse(url))
        ..headers['range'] = 'bytes=0-0');
    }
    await res.stream.listen(null).cancel();
    if (res.statusCode >= 400) {
      throw EngineException(EngineErrorKind.fileGone,
          raw: 'HTTP ${res.statusCode}');
    }
    return fileFromHeaders(url, res.headers);
  } on SocketException catch (e) {
    throw EngineException(EngineErrorKind.network, details: '$e');
  } on http.ClientException catch (e) {
    throw EngineException(EngineErrorKind.network, details: '$e');
  } on HandshakeException catch (e) {
    throw EngineException(EngineErrorKind.network, details: '$e');
  } finally {
    client.close();
  }
}

/// What lower-cased response [headers] say about the file at [url].
RemoteFile? fileFromHeaders(String url, Map<String, String> headers) {
  final type = headers['content-type'] ?? '';
  final disposition = headers['content-disposition'];
  final attachment = disposition?.contains('attachment') ?? false;
  if (!attachment && type.contains('text/html')) return null;

  // "bytes 0-0/12345" from a range request; content-length otherwise.
  final range = headers['content-range'];
  final size = range != null
      ? int.tryParse(range.split('/').last)
      : int.tryParse(headers['content-length'] ?? '');

  return RemoteFile(
    url: url,
    name: fileNameFrom(disposition) ?? _nameFromUrl(url),
    size: size,
  );
}

/// The file name in a Content-Disposition header, if any.
String? fileNameFrom(String? disposition) {
  if (disposition == null) return null;
  // RFC 5987 first: filename*=UTF-8''na%C3%AFve.pdf
  final star = RegExp(r"filename\*\s*=\s*[^']*'[^']*'([^;]+)", caseSensitive: false)
      .firstMatch(disposition);
  if (star != null) {
    try {
      return _safe(Uri.decodeComponent(star.group(1)!.trim()));
    } on ArgumentError {
      // Bad escapes: fall through to the plain name.
    }
  }
  final plain = RegExp(r'filename\s*=\s*"?([^";]+)"?', caseSensitive: false)
      .firstMatch(disposition);
  return plain == null ? null : _safe(plain.group(1)!.trim());
}

String _nameFromUrl(String url) {
  final uri = Uri.tryParse(url);
  final last = uri?.pathSegments.where((s) => s.isNotEmpty).lastOrNull;
  return _safe(last ?? '') ?? uri?.host ?? 'download';
}

/// Never let a server-chosen name climb out of the download folder.
String? _safe(String name) {
  final base = name.split(RegExp(r'[/\\]')).last.trim();
  return base.isEmpty || base == '.' || base == '..' ? null : base;
}
