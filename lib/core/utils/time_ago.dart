import 'package:intl/intl.dart';

/// Relative time in words, used by details screens and timeline entries:
/// `Just now`, `2 hours ago`, `1 day ago`, `3 days ago`.
///
/// [now] is injectable so the output can be tested deterministically.
String formatTimeAgo(DateTime time, {DateTime? now}) {
  final Duration difference = (now ?? DateTime.now()).difference(time);
  if (difference.inMinutes < 1) return 'Just now';

  if (difference.inDays < 365) {
    final ({int value, String unit}) ago = _agoParts(difference);
    return '${ago.value} ${ago.unit}${ago.value == 1 ? '' : 's'} ago';
  }

  return DateFormat.yMMMd().format(time);
}

/// Compact relative timestamp for cards: `Just now`, `5m ago`, `3h ago`,
/// `Yesterday`, `3d ago`, then an absolute date such as `12 Oct 2026`.
///
/// [now] is injectable so the output can be tested deterministically.
String formatRelativeTime(DateTime time, {DateTime? now}) {
  final DateTime reference = now ?? DateTime.now();
  final Duration difference = reference.difference(time);

  if (difference.inSeconds < 60) return 'Just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  if (difference.inDays == 1) return 'Yesterday';
  if (difference.inDays < 7) return '${difference.inDays}d ago';

  return DateFormat('d MMM yyyy').format(time);
}

/// Largest sensible unit for [difference], so 90 minutes reads as `1 hour`
/// rather than `90 minutes`.
({int value, String unit}) _agoParts(Duration difference) {
  if (difference.inMinutes < 60) {
    return (value: difference.inMinutes, unit: 'minute');
  }
  if (difference.inHours < 24) {
    return (value: difference.inHours, unit: 'hour');
  }
  if (difference.inDays < 7) {
    return (value: difference.inDays, unit: 'day');
  }
  if (difference.inDays < 30) {
    return (value: difference.inDays ~/ 7, unit: 'week');
  }
  return (value: difference.inDays ~/ 30, unit: 'month');
}
