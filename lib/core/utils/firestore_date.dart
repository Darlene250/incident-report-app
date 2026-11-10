import 'package:cloud_firestore/cloud_firestore.dart';

/// Reads a date field coming from Firestore.
///
/// Firestore returns [Timestamp], but cached or hand-written data may carry a
/// [DateTime] or an ISO-8601 [String]. Missing values fall back to "now" so a
/// partially written document still renders instead of crashing.
DateTime dateFromMap(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);

  return DateTime.now();
}
