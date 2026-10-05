import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// Material 3 Expressive leans on springs instead of fixed easing curves.
/// This adapts an underdamped spring into a [Curve] so it works
/// anywhere Flutter accepts one (AnimatedFoo widgets, page transitions...).
class SpringCurve extends Curve {
  const SpringCurve({this.damping = 0.62, this.stiffness = 380});

  /// 0 = wobbles forever, 1 = no overshoot.
  final double damping;
  final double stiffness;

  @override
  double transformInternal(double t) {
    const mass = 1.0;
    final critical = 2 * math.sqrt(stiffness * mass);
    final sim = SpringSimulation(
      SpringDescription(
          mass: mass, stiffness: stiffness, damping: critical * damping),
      0,
      1,
      0,
    );
    // Normalize so the curve still ends exactly at 1.
    const settle = 0.9;
    return t >= 1 ? 1 : sim.x(t * settle);
  }
}

abstract final class Motion {
  /// Spatial springs: things that move or change size.
  static const spatial = SpringCurve(damping: 0.62, stiffness: 380);
  static const spatialFast = SpringCurve(damping: 0.7, stiffness: 700);

  /// Effects: color and opacity should not bounce.
  static const effects = Curves.easeOutCubic;

  static const short = Duration(milliseconds: 220);
  static const medium = Duration(milliseconds: 420);
  static const long = Duration(milliseconds: 650);

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  static Duration of(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;
}
