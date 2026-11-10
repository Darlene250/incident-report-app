import 'package:flutter/material.dart';

/// Categories an incident can be filed under.
///
/// Damaged furniture and broken equipment belong to [IncidentCategory.facilities].
enum IncidentCategory {
  facilities('Facilities', Icons.account_balance),
  water('Water', Icons.water_drop),
  electricity('Electricity', Icons.bolt),
  safety('Safety', Icons.shield),
  sanitation('Sanitation', Icons.delete);

  const IncidentCategory(this.label, this.icon);

  /// Human readable text, also the exact value stored in Firestore.
  final String label;

  /// Icon used by category tiles and incident cards.
  final IconData icon;

  /// Parses a Firestore value, falling back to [IncidentCategory.facilities].
  static IncidentCategory fromValue(String? value) {
    return values.firstWhere(
      (IncidentCategory category) => category.label == value,
      orElse: () => IncidentCategory.facilities,
    );
  }
}
