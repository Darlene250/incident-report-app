import 'package:campus_incident_app/core/utils/time_ago.dart';
import 'package:campus_incident_app/models/app_user.dart';
import 'package:campus_incident_app/models/incident.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime created = DateTime.utc(2026, 3, 14, 9, 30);

  group('AppUser', () {
    test('round trips through toMap/fromMap', () {
      final AppUser user = AppUser(
        uid: 'uid-1',
        fullName: 'Elijah Laddie',
        email: 'elijah@university.edu',
        role: UserRole.staff,
        department: 'ICT',
        location: 'Block C',
        createdAt: created,
      );

      final AppUser parsed = AppUser.fromMap('uid-1', user.toMap());

      expect(parsed.uid, 'uid-1');
      expect(parsed.fullName, 'Elijah Laddie');
      expect(parsed.email, 'elijah@university.edu');
      expect(parsed.role, UserRole.staff);
      expect(parsed.department, 'ICT');
      expect(parsed.location, 'Block C');
      expect(parsed.createdAt.isAtSameMomentAs(created), isTrue);
    });

    test('stores the role as a lowercase string', () {
      final AppUser user = AppUser(
        uid: 'uid-1',
        fullName: 'A',
        email: 'a@b.c',
        role: UserRole.student,
        department: 'CS',
        location: 'Hostel A',
        createdAt: created,
      );

      expect(user.toMap()['role'], 'student');
      expect(user.toMap()['createdAt'], Timestamp.fromDate(created));
    });

    test('falls back to the document id and defaults when fields are missing', () {
      final AppUser parsed = AppUser.fromMap('doc-id', <String, dynamic>{});

      expect(parsed.uid, 'doc-id');
      expect(parsed.fullName, '');
      expect(parsed.role, UserRole.student);
    });

    test('parses roles from Firestore values', () {
      expect(UserRole.fromValue('staff'), UserRole.staff);
      expect(UserRole.fromValue('student'), UserRole.student);
      expect(UserRole.fromValue('admin'), UserRole.student);
      expect(UserRole.fromValue(null), UserRole.student);
    });
  });

  group('Incident', () {
    Incident buildIncident() => Incident(
          id: 'inc-1',
          title: 'Broken streetlight',
          description: 'The light outside Block B has been out for two days.',
          category: IncidentCategory.electricity,
          location: 'Main Library, Block B',
          hasPhoto: true,
          status: IncidentStatus.inProgress,
          reportedByUid: 'uid-1',
          reportedByName: 'Elijah Laddie',
          createdAt: created,
          updatedAt: created.add(const Duration(hours: 2)),
          statusHistory: <StatusChange>[
            StatusChange(
              status: IncidentStatus.submitted,
              changedAt: created,
              changedByUid: 'uid-1',
            ),
            StatusChange(
              status: IncidentStatus.inProgress,
              changedAt: created.add(const Duration(hours: 2)),
              changedByUid: 'staff-1',
            ),
          ],
        );

    test('round trips through toMap/fromMap', () {
      final Incident incident = buildIncident();
      final Incident parsed = Incident.fromMap('inc-1', incident.toMap());

      expect(parsed.id, 'inc-1');
      expect(parsed.title, 'Broken streetlight');
      expect(parsed.category, IncidentCategory.electricity);
      expect(parsed.status, IncidentStatus.inProgress);
      expect(parsed.hasPhoto, isTrue);
      expect(parsed.createdAt.isAtSameMomentAs(created), isTrue);
      expect(parsed.updatedAt.isAtSameMomentAs(created.add(const Duration(hours: 2))), isTrue);
      expect(parsed.statusHistory, hasLength(2));
      expect(parsed.statusHistory.last.status, IncidentStatus.inProgress);
      expect(parsed.statusHistory.last.changedByUid, 'staff-1');
    });

    test('stores status and category labels verbatim', () {
      final Map<String, dynamic> map = buildIncident().toMap();

      expect(map['status'], 'In Progress');
      expect(map['category'], 'Electricity');
      expect(map['hasPhoto'], isTrue);
    });

    test('tolerates missing or unknown values', () {
      final Incident parsed = Incident.fromMap('doc-9', <String, dynamic>{
        'hasPhoto': 'yes',
        'category': 'Nonsense',
        'status': 'Nonsense',
      });

      expect(parsed.id, 'doc-9');
      expect(parsed.hasPhoto, isFalse);
      expect(parsed.category, IncidentCategory.facilities);
      expect(parsed.status, IncidentStatus.submitted);
      expect(parsed.statusHistory, isEmpty);
    });

    test('newReport starts with a Submitted status history entry', () {
      final Incident incident = Incident.newReport(
        id: 'inc-2',
        title: 'Leaking tap',
        description: 'Tap in Hostel C keeps running.',
        category: IncidentCategory.water,
        location: 'Hostel C',
        reportedByUid: 'uid-2',
        reportedByName: 'Mary',
        createdAt: created,
      );

      expect(incident.status, IncidentStatus.submitted);
      expect(incident.statusHistory, hasLength(1));
      expect(incident.statusHistory.single.status, IncidentStatus.submitted);
      expect(incident.statusHistory.single.changedByUid, 'uid-2');
      expect(incident.createdAt, incident.updatedAt);
    });

    test('copyWith keeps the id and reporter', () {
      final Incident updated = buildIncident().copyWith(status: IncidentStatus.resolved);

      expect(updated.id, 'inc-1');
      expect(updated.reportedByUid, 'uid-1');
      expect(updated.status, IncidentStatus.resolved);
    });
  });

  group('IncidentCategory', () {
    test('maps every category to the required icon', () {
      expect(IncidentCategory.facilities.icon, Icons.account_balance);
      expect(IncidentCategory.water.icon, Icons.water_drop);
      expect(IncidentCategory.electricity.icon, Icons.bolt);
      expect(IncidentCategory.safety.icon, Icons.shield);
      expect(IncidentCategory.sanitation.icon, Icons.delete);
    });

    test('exposes the five allowed labels', () {
      expect(
        IncidentCategory.values.map((IncidentCategory c) => c.label),
        <String>['Facilities', 'Water', 'Electricity', 'Safety', 'Sanitation'],
      );
      expect(IncidentCategory.fromValue('Sanitation'), IncidentCategory.sanitation);
    });
  });

  group('IncidentStatus', () {
    test('parses the three allowed values', () {
      expect(IncidentStatus.fromValue('Submitted'), IncidentStatus.submitted);
      expect(IncidentStatus.fromValue('In Progress'), IncidentStatus.inProgress);
      expect(IncidentStatus.fromValue('Resolved'), IncidentStatus.resolved);
      expect(IncidentStatus.fromValue('Closed'), IncidentStatus.submitted);
    });
  });

  group('formatTimeAgo', () {
    final DateTime now = DateTime.utc(2026, 3, 14, 12, 0);

    test('formats hours, days and pluralisation', () {
      expect(formatTimeAgo(now.subtract(const Duration(hours: 2)), now: now), '2 hours ago');
      expect(formatTimeAgo(now.subtract(const Duration(hours: 1)), now: now), '1 hour ago');
      expect(formatTimeAgo(now.subtract(const Duration(days: 1)), now: now), '1 day ago');
      expect(formatTimeAgo(now.subtract(const Duration(days: 3)), now: now), '3 days ago');
      expect(formatTimeAgo(now.subtract(const Duration(minutes: 45)), now: now), '45 minutes ago');
      expect(formatTimeAgo(now.subtract(const Duration(minutes: 1)), now: now), '1 minute ago');
    });

    test('uses weeks and months for older entries', () {
      expect(formatTimeAgo(now.subtract(const Duration(days: 14)), now: now), '2 weeks ago');
      expect(formatTimeAgo(now.subtract(const Duration(days: 90)), now: now), '3 months ago');
    });

    test('handles the first seconds', () {
      expect(formatTimeAgo(now.subtract(const Duration(seconds: 10)), now: now), 'Just now');
    });
  });

  group('formatRelativeTime', () {
    final DateTime now = DateTime.utc(2026, 3, 14, 12, 0);

    test('keeps the compact card format', () {
      expect(formatRelativeTime(now.subtract(const Duration(hours: 2)), now: now), '2h ago');
      expect(formatRelativeTime(now.subtract(const Duration(days: 1)), now: now), 'Yesterday');
      expect(formatRelativeTime(now.subtract(const Duration(days: 3)), now: now), '3d ago');
    });
  });
}
