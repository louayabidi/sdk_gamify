import 'package:flutter/material.dart';

/// Display mode of the widget.
enum GamifDisplay {
  /// Small pill/chip — ideal for AppBar or floating overlays.
  pill,

  /// Compact card — good for dashboards or profile pages.
  card,

  /// Full panel — shows points header + badge list.
  full,
}

/// What content to display inside the widget.
enum GamifContent {
  /// Show points balance only.
  points,

  /// Show earned badges only.
  badges,

  /// Show both points and badges.
  both,
}

/// Configuration object for [GamifWidget].
/// All fields are optional — sensible defaults are provided.
class GamifWidgetConfig {
  /// Background color of the widget.
  final Color backgroundColor;

  /// Primary text color.
  final Color textColor;

  /// Accent color used for level badges, earned indicators, etc.
  final Color accentColor;

  /// Label shown next to the points value.
  final String label;

  /// Whether to show lifetime earned points below the balance.
  final bool showLifetime;

  /// Whether to show the user's current level.
  final bool showLevel;

  /// Whether to animate points when they update.
  final bool animate;

  /// Border radius for card and full modes.
  final double borderRadius;

  const GamifWidgetConfig({
    this.backgroundColor = const Color(0xFF6C63FF),
    this.textColor = Colors.white,
    this.accentColor = const Color(0xFF34D399),
    this.label = 'Points',
    this.showLifetime = false,
    this.showLevel = true,
    this.animate = true,
    this.borderRadius = 12.0,
  });
}