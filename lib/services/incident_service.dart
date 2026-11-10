import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_collections.dart';
import '../models/incident.dart';

/// The only class that reads and writes the `incidents` and `incident_photos`
/// collections.
///
/// Photos are stored as compressed JPEG bytes in Firestore (a `Blob` field)
/// instead of Firebase Storage, so the project runs on the free Spark plan.
class IncidentService {
  IncidentService({FirebaseFirestore? firestore}) : _injectedFirestore = firestore;

  final FirebaseFirestore? _injectedFirestore;

  /// Firestore documents are capped at 1 MiB; this leaves room for the other
  /// fields. Mirrored in `firestore.rules`.
  static const int maxPhotoBytes = 700 * 1024;

  FirebaseFirestore get _firestore => _injectedFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _incidents =>
      _firestore.collection(FirestoreCollections.incidents);

  CollectionReference<Map<String, dynamic>> get _photos =>
      _firestore.collection(FirestoreCollections.incidentPhotos);

  /// Pre-generates a document id so the report and its photo share one id.
  String newIncidentId() => _incidents.doc().id;

  /// Writes a new report and, when given, its photo in a single atomic batch:
  /// either both documents are saved or neither is. `createdAt`/`updatedAt` are
  /// server timestamps and the timeline always starts with a `Submitted` entry.
  Future<String> createIncident(Incident incident, {Uint8List? photoBytes}) async {
    final DocumentReference<Map<String, dynamic>> reference =
        incident.id.isEmpty ? _incidents.doc() : _incidents.doc(incident.id);

    final Map<String, dynamic> data = incident.toMap()
      ..['id'] = reference.id
      ..['status'] = IncidentStatus.submitted.label
      ..['createdAt'] = FieldValue.serverTimestamp()
      ..['updatedAt'] = FieldValue.serverTimestamp()
      ..['statusHistory'] = <Map<String, dynamic>>[
        StatusChange(
          status: IncidentStatus.submitted,
          changedAt: DateTime.now(),
          changedByUid: incident.reportedByUid,
        ).toMap(),
      ]
      ..['hasPhoto'] = photoBytes != null;

    final WriteBatch batch = _firestore.batch()..set(reference, data);
    if (photoBytes != null) {
      batch.set(_photos.doc(reference.id), <String, Object>{
        'ownerUid': incident.reportedByUid,
        'data': Blob(photoBytes),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();

    return reference.id;
  }

  /// The photo bytes for report [id], or null when there is no photo.
  Future<Uint8List?> loadPhoto(String id) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await _photos.doc(id).get();
    final Object? data = snapshot.data()?['data'];

    return data is Blob ? data.bytes : null;
  }

  /// Every report, newest first.
  Stream<List<Incident>> streamAllIncidents() {
    return _incidents
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapQuery);
  }

  /// Reports created by [uid]. Filtered on the server and ordered in Dart so no
  /// composite index is required.
  Stream<List<Incident>> streamIncidentsByUser(String uid) {
    return _incidents.where('reportedByUid', isEqualTo: uid).snapshots().map(_mapQuery);
  }

  Stream<Incident?> streamIncident(String id) {
    return _incidents.doc(id).snapshots().map((DocumentSnapshot<Map<String, dynamic>> snapshot) {
      final Map<String, dynamic>? data = snapshot.data();
      if (!snapshot.exists || data == null) return null;

      return Incident.fromMap(snapshot.id, data);
    });
  }

  /// Updates the status, `updatedAt` and appends to the timeline.
  Future<void> updateStatus(String id, IncidentStatus newStatus, String staffUid) async {
    await _incidents.doc(id).update(<String, Object>{
      'status': newStatus.label,
      'updatedAt': FieldValue.serverTimestamp(),
      'statusHistory': FieldValue.arrayUnion(<Map<String, dynamic>>[
        StatusChange(
          status: newStatus,
          changedAt: DateTime.now(),
          changedByUid: staffUid,
        ).toMap(),
      ]),
    });
  }

  /// Reporter edit of the content fields. The rules only allow this while the
  /// report is still `Submitted`, and reject any other field.
  Future<void> updateIncidentDetails(
    String id, {
    required String title,
    required String description,
    required IncidentCategory category,
    required String location,
  }) async {
    await _incidents.doc(id).update(<String, Object>{
      'title': title,
      'description': description,
      'category': category.label,
      'location': location,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes the report and its photo together in one batch.
  Future<void> deleteIncident(String id, {bool hasPhoto = false}) async {
    final WriteBatch batch = _firestore.batch()..delete(_incidents.doc(id));
    if (hasPhoto) batch.delete(_photos.doc(id));
    await batch.commit();
  }

  List<Incident> _mapQuery(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final List<Incident> incidents = snapshot.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => Incident.fromMap(doc.id, doc.data()))
        .toList();
    incidents.sort((Incident a, Incident b) => b.createdAt.compareTo(a.createdAt));

    return List<Incident>.unmodifiable(incidents);
  }
}
