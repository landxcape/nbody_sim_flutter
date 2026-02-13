import 'package:flutter/material.dart';

/// Theme extension containing visual tokens used by simulation widgets.
@immutable
class SimulatorVisualTheme extends ThemeExtension<SimulatorVisualTheme> {
  /// Creates simulation visual tokens.
  const SimulatorVisualTheme({
    required this.canvasGradientStart,
    required this.canvasGradientMid,
    required this.canvasGradientEnd,
    required this.hudSurface,
    required this.hudBorder,
    required this.hudChipSurface,
    required this.hudChipBorder,
    required this.hudOnChip,
    required this.gridColor,
    required this.vectorColor,
    required this.selectionColor,
    required this.fieldOverlayColor,
    required this.lensingColor,
  });

  /// Start color of the canvas background gradient.
  final Color canvasGradientStart;

  /// Mid color of the canvas background gradient.
  final Color canvasGradientMid;

  /// End color of the canvas background gradient.
  final Color canvasGradientEnd;

  /// Surface color for overlay panels/HUD containers.
  final Color hudSurface;

  /// Border color for overlay panels/HUD containers.
  final Color hudBorder;

  /// Surface color for chip-like UI elements.
  final Color hudChipSurface;

  /// Border color for chip-like UI elements.
  final Color hudChipBorder;

  /// Foreground color for content placed on HUD chips.
  final Color hudOnChip;

  /// Grid line color used by the simulation canvas.
  final Color gridColor;

  /// Vector color used for velocity arrows.
  final Color vectorColor;

  /// Selection highlight color.
  final Color selectionColor;

  /// Field overlay base color.
  final Color fieldOverlayColor;

  /// Lensing overlay color.
  final Color lensingColor;

  /// Derives simulation visuals from a Material [ColorScheme].
  factory SimulatorVisualTheme.fromColorScheme(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    return SimulatorVisualTheme(
      canvasGradientStart: Color.lerp(
        colorScheme.surface,
        colorScheme.primaryContainer,
        0.28,
      )!,
      canvasGradientMid: Color.lerp(
        colorScheme.surfaceContainerLow,
        colorScheme.secondaryContainer,
        0.18,
      )!,
      canvasGradientEnd: Color.lerp(
        colorScheme.surface,
        colorScheme.tertiaryContainer,
        0.2,
      )!,
      hudSurface: colorScheme.surface.withValues(alpha: isDark ? 0.86 : 0.9),
      hudBorder: colorScheme.outlineVariant.withValues(alpha: 0.7),
      hudChipSurface: colorScheme.primaryContainer.withValues(
        alpha: isDark ? 0.4 : 0.65,
      ),
      hudChipBorder: colorScheme.outlineVariant.withValues(alpha: 0.6),
      hudOnChip: colorScheme.onSurfaceVariant,
      gridColor: colorScheme.outlineVariant.withValues(alpha: 0.26),
      vectorColor: colorScheme.onSurface.withValues(alpha: 0.38),
      selectionColor: colorScheme.onSurface,
      fieldOverlayColor: colorScheme.primary.withValues(alpha: 0.24),
      lensingColor: colorScheme.onSurface.withValues(alpha: 0.16),
    );
  }

  @override
  SimulatorVisualTheme copyWith({
    Color? canvasGradientStart,
    Color? canvasGradientMid,
    Color? canvasGradientEnd,
    Color? hudSurface,
    Color? hudBorder,
    Color? hudChipSurface,
    Color? hudChipBorder,
    Color? hudOnChip,
    Color? gridColor,
    Color? vectorColor,
    Color? selectionColor,
    Color? fieldOverlayColor,
    Color? lensingColor,
  }) {
    return SimulatorVisualTheme(
      canvasGradientStart: canvasGradientStart ?? this.canvasGradientStart,
      canvasGradientMid: canvasGradientMid ?? this.canvasGradientMid,
      canvasGradientEnd: canvasGradientEnd ?? this.canvasGradientEnd,
      hudSurface: hudSurface ?? this.hudSurface,
      hudBorder: hudBorder ?? this.hudBorder,
      hudChipSurface: hudChipSurface ?? this.hudChipSurface,
      hudChipBorder: hudChipBorder ?? this.hudChipBorder,
      hudOnChip: hudOnChip ?? this.hudOnChip,
      gridColor: gridColor ?? this.gridColor,
      vectorColor: vectorColor ?? this.vectorColor,
      selectionColor: selectionColor ?? this.selectionColor,
      fieldOverlayColor: fieldOverlayColor ?? this.fieldOverlayColor,
      lensingColor: lensingColor ?? this.lensingColor,
    );
  }

  @override
  SimulatorVisualTheme lerp(
    covariant ThemeExtension<SimulatorVisualTheme>? other,
    double t,
  ) {
    if (other is! SimulatorVisualTheme) {
      return this;
    }

    return SimulatorVisualTheme(
      canvasGradientStart: Color.lerp(
        canvasGradientStart,
        other.canvasGradientStart,
        t,
      )!,
      canvasGradientMid: Color.lerp(
        canvasGradientMid,
        other.canvasGradientMid,
        t,
      )!,
      canvasGradientEnd: Color.lerp(
        canvasGradientEnd,
        other.canvasGradientEnd,
        t,
      )!,
      hudSurface: Color.lerp(hudSurface, other.hudSurface, t)!,
      hudBorder: Color.lerp(hudBorder, other.hudBorder, t)!,
      hudChipSurface: Color.lerp(hudChipSurface, other.hudChipSurface, t)!,
      hudChipBorder: Color.lerp(hudChipBorder, other.hudChipBorder, t)!,
      hudOnChip: Color.lerp(hudOnChip, other.hudOnChip, t)!,
      gridColor: Color.lerp(gridColor, other.gridColor, t)!,
      vectorColor: Color.lerp(vectorColor, other.vectorColor, t)!,
      selectionColor: Color.lerp(selectionColor, other.selectionColor, t)!,
      fieldOverlayColor: Color.lerp(
        fieldOverlayColor,
        other.fieldOverlayColor,
        t,
      )!,
      lensingColor: Color.lerp(lensingColor, other.lensingColor, t)!,
    );
  }
}

/// Builds a Material 3 theme configured for simulation-focused UIs.
ThemeData buildSimulatorTheme(Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF1D3557),
    brightness: brightness,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    cardTheme: CardThemeData(
      color: colorScheme.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: colorScheme.surfaceContainerLow,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    extensions: <ThemeExtension<dynamic>>[
      SimulatorVisualTheme.fromColorScheme(colorScheme),
    ],
  );
}
