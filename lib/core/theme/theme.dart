import 'package:flutter/material.dart';

import 'motion.dart';

/// Material 3 Expressive, tuned: rounder shapes, bolder type, spring motion.
abstract final class AppTheme {
  static const latinFont = 'Figtree';
  static const persianFont = 'Vazirmatn';

  /// Shape scale (M3 Expressive extends the corner set up to 48dp).
  static const radiusSm = 12.0;
  static const radiusMd = 16.0;
  static const radiusLg = 28.0;
  static const radiusXl = 36.0;

  static ColorScheme schemeFromSeed(Color seed, Brightness b) =>
      ColorScheme.fromSeed(
        seedColor: seed,
        brightness: b,
        dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
      );

  /// [cursive] is true for scripts like Persian, whose joined letters break
  /// under the negative letter-spacing used for Latin display type.
  static ThemeData build(ColorScheme scheme, {bool cursive = false}) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: cursive ? persianFont : latinFont,
      // Titles in other scripts (a Persian video in an English UI) still
      // get a designed font instead of a random system fallback.
      fontFamilyFallback: cursive ? const [latinFont] : const [persianFont],
      brightness: scheme.brightness,
    );
    final text = base.textTheme;
    final latinTheme = text.copyWith(
      displayLarge: text.displayLarge?.copyWith(
          fontWeight: FontWeight.w800, letterSpacing: -1.5, height: 1.0),
      displayMedium: text.displayMedium?.copyWith(
          fontWeight: FontWeight.w800, letterSpacing: -1.2, height: 1.02),
      displaySmall: text.displaySmall
          ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.8),
      headlineLarge: text.headlineLarge
          ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.6),
      headlineMedium: text.headlineMedium
          ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.4),
      headlineSmall: text.headlineSmall
          ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      labelMedium: text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
    );
    final textTheme = cursive
        ? latinTheme.apply(fontFamily: persianFont).copyWith(
            displayLarge: latinTheme.displayLarge
                ?.copyWith(fontFamily: persianFont, letterSpacing: 0, height: 1.3),
            displayMedium: latinTheme.displayMedium
                ?.copyWith(fontFamily: persianFont, letterSpacing: 0, height: 1.3),
            displaySmall: latinTheme.displaySmall
                ?.copyWith(fontFamily: persianFont, letterSpacing: 0),
            headlineLarge: latinTheme.headlineLarge
                ?.copyWith(fontFamily: persianFont, letterSpacing: 0),
            headlineMedium: latinTheme.headlineMedium
                ?.copyWith(fontFamily: persianFont, letterSpacing: 0),
            headlineSmall: latinTheme.headlineSmall
                ?.copyWith(fontFamily: persianFont, letterSpacing: 0),
          )
        : latinTheme;

    final pill = WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)));
    const buttonPadding = WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 24, vertical: 16));

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
      }),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle:
            textTheme.headlineSmall?.copyWith(color: scheme.onSurface),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          shape: pill,
          padding: buttonPadding,
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(shape: pill, padding: buttonPadding),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          shape: pill,
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
          padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm)),
        labelStyle: textTheme.labelLarge,
        showCheckmark: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.secondaryContainer,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
        height: 72,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.secondaryContainer,
        selectedLabelTextStyle:
            textTheme.labelMedium?.copyWith(color: scheme.onSurface),
        unselectedLabelTextStyle:
            textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd)),
        titleTextStyle:
            textTheme.titleMedium?.copyWith(color: scheme.onSurface),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        linearTrackColor: scheme.secondaryContainer,
        linearMinHeight: 6,
        borderRadius: BorderRadius.circular(6),
      ),
      switchTheme: SwitchThemeData(
        thumbIcon: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? const Icon(Icons.check_rounded)
                : null),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle:
            textTheme.bodySmall?.copyWith(color: scheme.onInverseSurface),
      ),
      extensions: const [AppMotion()],
    );
  }
}

/// Exposes the spring curves through the theme for widgets that want them.
class AppMotion extends ThemeExtension<AppMotion> {
  const AppMotion();
  Curve get spatial => Motion.spatial;
  Curve get effects => Motion.effects;

  @override
  AppMotion copyWith() => this;

  @override
  AppMotion lerp(AppMotion? other, double t) => this;
}
