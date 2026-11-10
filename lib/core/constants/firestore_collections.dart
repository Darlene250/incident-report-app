/// Firestore collection names used by the services.
abstract final class FirestoreCollections {
  static const String users = 'users';
  static const String incidents = 'incidents';

  /// One document per photo, keyed by the incident id.
  static const String incidentPhotos = 'incident_photos';
}
