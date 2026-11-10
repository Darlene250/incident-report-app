import 'package:flutter/material.dart';

/// Shared spacing, radius and size scale for the whole app.
abstract final class AppSizes {
  // Layout
  static const double screenPadding = 20;
  static const double maxContentWidth = 430;

  // Cards
  static const double cardRadius = 22;
  static const double heroRadius = 22;
  static const double cardShadowBlur = 16;

  // Buttons
  static const double buttonHeight = 52;
  static const double buttonRadius = 22;

  // Inputs
  static const double inputRadius = 20;

  // Category tiles
  static const double categoryTileWidth = 76;
  static const double categoryTileHeight = 64;
  static const double categoryTileRadius = 14;

  // Status chips
  static const double chipRadius = 20;
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(horizontal: 10, vertical: 4);

  // Incident card thumbnail
  static const double thumbnailSize = 56;
  static const double thumbnailRadius = 12;

  // Bottom navigation bar and its raised add button
  static const double bottomBarHeight = 70;
  static const double addButtonSize = 56;
}
