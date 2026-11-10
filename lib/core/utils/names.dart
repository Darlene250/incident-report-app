/// Initials for an avatar, e.g. `Elijah Laddie` -> `EL`.
///
/// Falls back to `?` when there is no name.
String initialsOf(String name) {
  final String trimmed = name.trim();
  if (trimmed.isEmpty) return '?';

  final List<String> parts = trimmed.split(RegExp(r'\s+'));
  final String first = parts.first.substring(0, 1).toUpperCase();
  if (parts.length == 1) return first;

  return '$first${parts[1].substring(0, 1).toUpperCase()}';
}

/// First word of a full name, e.g. `Elijah Laddie` -> `Elijah`.
String firstNameOf(String fullName) {
  final String trimmed = fullName.trim();
  if (trimmed.isEmpty) return '';

  return trimmed.split(RegExp(r'\s+')).first;
}
