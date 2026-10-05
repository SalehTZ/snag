import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/motion.dart';

/// The scalloped "cookie" from the M3 Expressive shape library:
/// r(θ) = R · (1 − depth · (1 − cos(lobes · θ)) / 2).
class CookieBorder extends OutlinedBorder {
  const CookieBorder({
    this.lobes = 9,
    this.depth = 0.12,
    this.rotation = 0,
    super.side,
  });

  final int lobes;
  final double depth;
  final double rotation;

  Path _path(Rect rect) {
    final c = rect.center;
    final radius = rect.shortestSide / 2;
    final path = Path();
    const steps = 180;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps * 2 * math.pi;
      final r = radius * (1 - depth * (1 - math.cos(lobes * t)) / 2);
      final pt = Offset(c.dx + r * math.cos(t + rotation),
          c.dy + r * math.sin(t + rotation));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    return path..close();
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _path(rect.deflate(side.strokeInset));

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.strokeInset);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawPath(_path(rect), side.toPaint());
  }

  @override
  ShapeBorder scale(double t) =>
      CookieBorder(lobes: lobes, depth: depth, rotation: rotation, side: side.scale(t));

  @override
  CookieBorder copyWith({BorderSide? side}) => CookieBorder(
      lobes: lobes, depth: depth, rotation: rotation, side: side ?? this.side);

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is CookieBorder && a.lobes == lobes) {
      return CookieBorder(
        lobes: lobes,
        depth: a.depth + (depth - a.depth) * t,
        rotation: a.rotation + (rotation - a.rotation) * t,
        side: BorderSide.lerp(a.side, side, t),
      );
    }
    return super.lerpFrom(a, t);
  }
}

/// A big friendly icon sitting on a slowly turning cookie.
class ShapeIcon extends StatefulWidget {
  const ShapeIcon({
    super.key,
    required this.icon,
    this.size = 112,
    this.color,
    this.iconColor,
    this.lobes = 9,
    this.spin = true,
  });

  final IconData icon;
  final double size;
  final Color? color;
  final Color? iconColor;
  final int lobes;
  final bool spin;

  @override
  State<ShapeIcon> createState() => _ShapeIconState();
}

class _ShapeIconState extends State<ShapeIcon>
    with SingleTickerProviderStateMixin {
  late final _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 24));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.spin && !Motion.reduced(context)) {
      _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: widget.size,
      child: Stack(alignment: Alignment.center, children: [
        AnimatedBuilder(
          animation: _c,
          builder: (context, _) => DecoratedBox(
            decoration: ShapeDecoration(
              color: widget.color ?? scheme.primaryContainer,
              shape: CookieBorder(
                  lobes: widget.lobes, rotation: _c.value * 2 * math.pi),
            ),
            child: SizedBox.square(dimension: widget.size),
          ),
        ),
        Icon(widget.icon,
            size: widget.size * 0.42,
            color: widget.iconColor ?? scheme.onPrimaryContainer),
      ]),
    );
  }
}

/// M3 Expressive-style loading indicator: a shape that spins and breathes
/// between a soft circle and a scalloped cookie.
class MorphingLoader extends StatefulWidget {
  const MorphingLoader({super.key, this.size = 40, this.color});
  final double size;
  final Color? color;

  @override
  State<MorphingLoader> createState() => _MorphingLoaderState();
}

class _MorphingLoaderState extends State<MorphingLoader>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return Semantics(
      label: 'Loading',
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final breathe = (math.sin(t * 2 * math.pi) + 1) / 2;
          return SizedBox.square(
            dimension: widget.size,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: color,
                shape: CookieBorder(
                  lobes: 7,
                  depth: 0.04 + 0.16 * breathe,
                  rotation: Curves.easeInOutCubic.transform(t) * 2 * math.pi,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
