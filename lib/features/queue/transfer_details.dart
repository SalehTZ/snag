import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../engine/aria2.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';

/// Live numbers for an aria2 download in its details sheet: speeds, the
/// piece map, its connections or peers and, for a torrent, what it is.
/// Shows nothing once aria2 has let go of the download.
class TransferDetails extends ConsumerStatefulWidget {
  const TransferDetails({super.key, required this.taskId, this.path});
  final String taskId;
  final String? path;

  @override
  ConsumerState<TransferDetails> createState() => _TransferDetailsState();
}

class _TransferDetailsState extends ConsumerState<TransferDetails> {
  TransferStats? _stats;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    final stats = await ref
        .read(aria2Provider)
        .stats(taskId: widget.taskId, path: widget.path);
    if (mounted) setState(() => _stats = stats);
  }

  @override
  Widget build(BuildContext context) {
    final s = _stats;
    if (s == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final l = context.l10n;
    final fmt = context.fmt;
    final have = s.pieces.where((b) => b).length;
    final shown = s.links.take(8).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _Strip(cells: s.isTorrent
          ? [
              (l.detailsDownload, fmt.speed(s.down)),
              (l.detailsUpload, fmt.speed(s.up)),
              (l.detailsRatio,
                  s.ratio == null ? '-' : fmt.number(s.ratio!, decimals: 2)),
            ]
          : [
              (l.detailsSpeed, fmt.speed(s.down)),
              (l.detailsConnections, fmt.number(s.connections)),
              (l.detailsDownloaded, fmt.bytes(s.done)),
            ]),
      if (s.pieces.isNotEmpty) ...[
        const SizedBox(height: 24),
        _Heading(l.detailsPieces,
            trailing: l.detailsPiecesOf(fmt.number(have),
                fmt.number(s.pieces.length), fmt.bytes(s.pieceLength))),
        const SizedBox(height: 10),
        _PieceMap(pieces: s.pieces),
      ],
      const SizedBox(height: 24),
      _Heading(s.isTorrent ? l.detailsPeers : l.detailsConnections,
          trailing: s.isTorrent
              ? l.detailsPeersOf(fmt.number(s.connections), s.seeders ?? 0)
              : null),
      const SizedBox(height: 6),
      if (shown.isEmpty)
        Text(s.isTorrent ? l.detailsNoPeers : l.detailsNoConnections,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant))
      else
        for (final link in shown)
          _LinkRow(
            link: link,
            fastest: shown.first.down + shown.first.up,
            torrent: s.isTorrent,
          ),
      if (s.isTorrent) ...[
        const SizedBox(height: 24),
        _Heading(l.detailsTorrent),
        const SizedBox(height: 4),
        _Row(l.detailsInfoHash,
            Row(children: [
              Expanded(
                child: SelectableText(s.infoHash!,
                    textDirection: TextDirection.ltr,
                    style: monoStyle.copyWith(fontSize: 12)),
              ),
              IconButton(
                tooltip: l.detailsCopyHash,
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: s.infoHash!));
                  showSnack(context, l.detailsHashCopied);
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
              ),
            ])),
        _Row(l.detailsUploaded, Text(fmt.bytes(s.uploaded))),
        if (s.created != null)
          _Row(l.detailsCreated, Text(fmt.date(s.created!))),
        if (s.comment != null)
          _Row(l.detailsComment,
              SelectableText(s.comment!,
                  textDirection: contentDirection(s.comment!))),
        if (s.files.length > 1) ...[
          const SizedBox(height: 20),
          _Heading(l.detailsFiles,
              trailing: fmt.number(s.files.length)),
          const SizedBox(height: 4),
          for (final f in s.files)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Expanded(
                  child: Text(f.path,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: contentDirection(f.path),
                      style: theme.textTheme.bodyMedium),
                ),
                const SizedBox(width: 12),
                Text(
                    '${fmt.percent(f.length == 0 ? 1 : f.done / f.length)}'
                    ' · ${fmt.bytes(f.length)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()])),
              ]),
            ),
        ],
      ],
      const SizedBox(height: 24),
    ]);
  }
}

/// Headline numbers as type in one outlined strip split by hairlines.
class _Strip extends StatelessWidget {
  const _Strip({required this.cells});
  final List<(String, String)> cells;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final line = theme.colorScheme.outlineVariant;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: IntrinsicHeight(
        child: Row(children: [
          for (final (i, (label, value)) in cells.indexed) ...[
            if (i > 0) VerticalDivider(width: 1, thickness: 1, color: line),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  // Fixed height: FittedBox would break the strip's
                  // IntrinsicHeight. Long units (Persian) shrink to fit.
                  SizedBox(
                    height: 24,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(value,
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ])),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.title, {this.trailing});
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(children: [
      Text(title, style: theme.textTheme.titleSmall),
      const Spacer(),
      if (trailing != null)
        Text(trailing!,
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()])),
    ]);
  }
}

/// Every piece of the file as a cell, darker as more of it is here. With
/// more pieces than cells, each cell stands for a run of pieces.
class _PieceMap extends StatelessWidget {
  const _PieceMap({required this.pieces});
  final List<bool> pieces;

  static const _cell = 10.0, _gap = 2.0, _maxRows = 8;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, box) {
      final cols = ((box.maxWidth + _gap) / (_cell + _gap)).floor();
      final cells = pieceRuns(pieces, cols * _maxRows);
      final rows = (cells.length / cols).ceil();
      return CustomPaint(
        size: Size(box.maxWidth, rows * (_cell + _gap) - _gap),
        painter: _PiecePainter(
          cells: cells,
          cols: cols,
          empty: scheme.surfaceContainerHighest,
          full: scheme.primary,
          rtl: Directionality.of(context) == TextDirection.rtl,
        ),
      );
    });
  }
}

/// How much of each of at most [cells] equal runs of [pieces] is here.
List<double> pieceRuns(List<bool> pieces, int cells) {
  if (pieces.length <= cells) return [for (final p in pieces) p ? 1.0 : 0.0];
  return List.generate(cells, (i) {
    final from = i * pieces.length ~/ cells;
    final to = (i + 1) * pieces.length ~/ cells;
    return pieces.sublist(from, to).where((p) => p).length / (to - from);
  });
}

class _PiecePainter extends CustomPainter {
  _PiecePainter({
    required this.cells,
    required this.cols,
    required this.empty,
    required this.full,
    required this.rtl,
  });

  final List<double> cells;
  final int cols;
  final Color empty, full;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    const step = _PieceMap._cell + _PieceMap._gap;
    final paint = Paint();
    for (final (i, f) in cells.indexed) {
      final col = i % cols;
      final x = rtl ? size.width - (col + 1) * step + _PieceMap._gap : col * step;
      paint.color = Color.lerp(empty, full, f)!;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, i ~/ cols * step, _PieceMap._cell, _PieceMap._cell),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_PiecePainter old) =>
      old.cells != cells || old.empty != empty || old.full != full;
}

/// One peer or connection, its speed drawn as the row's fill against the
/// fastest one.
class _LinkRow extends StatelessWidget {
  const _LinkRow(
      {required this.link, required this.fastest, required this.torrent});
  final TransferLink link;
  final int fastest;
  final bool torrent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = context.fmt;
    final small = theme.textTheme.bodySmall?.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()]);
    final share = fastest == 0 ? 0.0 : (link.down + link.up) / fastest;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(children: [
          Positioned.fill(
            child: FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: share.clamp(0.0, 1.0),
              child: ColoredBox(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(link.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.ltr,
                      style: monoStyle.copyWith(fontSize: 12)),
                  // A peer's two speeds don't fit beside its address in
                  // every language: they get their own line.
                  if (torrent)
                    Text(
                        '↓ ${fmt.speed(link.down)}   ↑ ${fmt.speed(link.up)}',
                        style: small?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                ]),
              ),
              const SizedBox(width: 12),
              Text(
                  link.progress != null
                      ? fmt.percent(link.progress!)
                      : fmt.speed(link.down),
                  style: small),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(
          width: 104,
          child: Text(label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
        Expanded(
          child: DefaultTextStyle.merge(
              style: theme.textTheme.bodyMedium, child: value),
        ),
      ]),
    );
  }
}
