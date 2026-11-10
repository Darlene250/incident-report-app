import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/incident_category.dart';
import '../core/constants/incident_status.dart';
import '../core/utils/firestore_date.dart';

export '../core/constants/incident_category.dart';
export '../core/constants/incident_status.dart';

/// One entry in an incident's status timeline.
@immutable
class StatusChange {
  const StatusChange({
    required this.status,
    required this.changedAt,
    required this.changedByUid,
  });

  final IncidentStatus status;
  final DateTime changedAt;
  final String changedByUid;

  factory StatusChange.fromMap(Map<String, dynamic> map) {
    return StatusChange(
      status: IncidentStatus.fromValue(map['status'] as String?),
      changedAt: dateFromMap(map['changedAt']),
      changedByUid: (map['changedByUid'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'status': status.label,
      'changedAt': Timestamp.fromDate(changedAt),
      'changedByUid': changedByUid,
    };
  }
}

/// A document in the `incidents/{incidentId}` collection.
@immutable
class Incident {
  const Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.status,
    required this.reportedByUid,
    required this.reportedByName,
    required this.createdAt,
    required this.updatedAt,
    this.hasPhoto = false,
    this.isAnonymous = false,
    this.statusHistory = const <StatusChange>[],
  });

  /// Name stored in place of the reporter when [isAnonymous] is true.
  static const String anonymousName = 'Anonymous';

  final String id;
  final String title;
  final String description;
  final IncidentCategory category;
  final String location;

  /// True when a photo is stored in `incident_photos/{id}`. The bytes live in
  /// their own document so lists never download every photo.
  final bool hasPhoto;
  final IncidentStatus status;
  final String reportedByUid;
  final String reportedByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// When true, [reportedByName] is stored as [anonymousName] so other users
  /// (staff included) never see who filed the report. [reportedByUid] is still
  /// kept so the security rules can enforce ownership and misuse can be traced.
  final bool isAnonymous;

  /// Oldest first; the last entry matches [status].
  final List<StatusChange> statusHistory;

  /// [id] is passed separately so it can be taken from the document id when the
  /// stored field is missing.
  factory Incident.fromMap(String id, Map<String, dynamic> map) {
    final List<dynamic> rawHistory =
        (map['statusHistory'] as List<dynamic>?) ?? const <dynamic>[];

    return Incident(
      id: (map['id'] as String?) ?? id,
      title: (map['title'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      category: IncidentCategory.fromValue(map['category'] as String?),
      location: (map['location'] as String?) ?? '',
      hasPhoto: map['hasPhoto'] == true,
      status: IncidentStatus.fromValue(map['status'] as String?),
      reportedByUid: (map['reportedByUid'] as String?) ?? '',
      reportedByName: (map['reportedByName'] as String?) ?? '',
      createdAt: dateFromMap(map['createdAt']),
      updatedAt: dateFromMap(map['updatedAt']),
      isAnonymous: (map['isAnonymous'] as bool?) ?? false,
      statusHistory: rawHistory
          .whereType<Map<String, dynamic>>()
          .map(StatusChange.fromMap)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'category': category.label,
      'location': location,
      'hasPhoto': hasPhoto,
      'status': status.label,
      'reportedByUid': reportedByUid,
      'reportedByName': reportedByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isAnonymous': isAnonymous,
      'statusHistory':
          statusHistory.map((StatusChange change) => change.toMap()).toList(growable: false),
    };
  }

  /// Creates a new report with a `Submitted` entry as the first timeline item.
  factory Incident.newReport({
    required String id,
    required String title,
    required String description,
    required IncidentCategory category,
    required String location,
    required String reportedByUid,
    required String reportedByName,
    DateTime? createdAt,
    bool hasPhoto = false,
    bool isAnonymous = false,
  }) {
    final DateTime timestamp = createdAt ?? DateTime.now();

    return Incident(
      id: id,
      title: title,
      description: description,
      category: category,
      location: location,
      hasPhoto: hasPhoto,
      status: IncidentStatus.submitted,
      reportedByUid: reportedByUid,
      reportedByName: isAnonymous ? anonymousName : reportedByName,
      createdAt: timestamp,
      updatedAt: timestamp,
      isAnonymous: isAnonymous,
      statusHistory: <StatusChange>[
        StatusChange(
          status: IncidentStatus.submitted,
          changedAt: timestamp,
          changedByUid: reportedByUid,
        ),
      ],
    );
  }

  Incident copyWith({
    String? title,
    String? description,
    IncidentCategory? category,
    String? location,
    bool? hasPhoto,
    IncidentStatus? status,
    DateTime? updatedAt,
    List<StatusChange>? statusHistory,
  }) {
    return Incident(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      hasPhoto: hasPhoto ?? this.hasPhoto,
      status: status ?? this.status,
      reportedByUid: reportedByUid,
      reportedByName: reportedByName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isAnonymous: isAnonymous,
      statusHistory: statusHistory ?? this.statusHistory,
    );
  }
}
