/// Lifecycle state of a reported incident.
///
/// Lives in `core/constants` so UI widgets can render a status without
/// depending on the `Incident` model.
enum IncidentStatus {
  submitted('Submitted'),
  inProgress('In Progress'),
  resolved('Resolved');

  const IncidentStatus(this.label);

  /// Human readable text shown in status chips. This is also the exact value
  /// stored in Firestore (`status` field and `statusHistory` entries).
  final String label;

  /// Parses a Firestore value, falling back to [IncidentStatus.submitted].
  static IncidentStatus fromValue(String? value) {
    return values.firstWhere(
      (IncidentStatus status) => status.label == value,
      orElse: () => IncidentStatus.submitted,
    );
  }
}
