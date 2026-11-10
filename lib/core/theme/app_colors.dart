import 'package:flutter/material.dart';

import '../constants/incident_status.dart';

/// Colour palette sampled from the assignment reference UI.
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF2FA05A);
  static const Color gradientStart = Color(0xFF2FA05A);
  static const Color gradientEnd = Color(0xFF6CBF84);

  /// Hero gradient used by the home header card (top-left -> bottom-right).
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[gradientStart, gradientEnd],
  );

  // Surfaces
  static const Color page = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFDDF1E3);

  /// Neutral backdrop shown around the app column on wide screens.
  static const Color shell = Color(0xFFE7E3D8);

  // Text
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF8A8A8A);
  static const Color textHint = Color(0xFF8A8A8A);

  // Lines
  static const Color border = Color(0xFFDDF1E3);

  static const Color error = Color(0xFFE0674A);

  /// Unselected filter chip fill.
  static const Color filterChip = Color(0xFFDDF1E3);

  // Summary tiles
  static const Color myReportsTile = Color(0xFFDDF1E3);
  static const Color inProgressTile = Color(0xFFDDF1E3);
  static const Color resolvedTile = Color(0xFFDDF1E3);
  static const Color submittedTile = Color(0xFFFBE4DD);

  static const Color myReportsIcon = primary;
  static const Color inProgressIcon = Color(0xFF6CBF84);
  static const Color resolvedIcon = primary;
  static const Color submittedIcon = error;

  // Status chips
  static const Color submittedChipBackground = Color(0xFFFBE4DD);
  static const Color submittedChipText = error;
  static const Color inProgressChipBackground = Color(0xFFDDF1E3);
  static const Color inProgressChipText = Color(0xFF6CBF84);
  static const Color resolvedChipBackground = Color(0xFFDDF1E3);
  static const Color resolvedChipText = primary;

  static Color statusColor(IncidentStatus status) {
    return switch (status) {
      IncidentStatus.submitted => error,
      IncidentStatus.inProgress => const Color(0xFF6CBF84),
      IncidentStatus.resolved => primary,
    };
  }
}
