import 'dart:typed_data';

import 'package:campus_incident_app/models/app_user.dart';
import 'package:campus_incident_app/models/incident.dart';
import 'package:campus_incident_app/providers/incident_provider.dart';
import 'package:campus_incident_app/services/incident_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'helpers/fakes.dart';

void main() {
  late FakeIncidentService service;
  late IncidentProvider provider;

  setUp(() {
    service = FakeIncidentService();
    provider = IncidentProvider(incidentService: service);
    addTearDown(() async {
      provider.dispose();
      await service.dispose();
    });
  });

  group('live lists', () {
    test('exposes all incidents and my incidents from the streams', () async {
      provider.updateUser(makeUser());
      await pumpEventQueue();

      service.all.add(<Incident>[
        makeIncident(id: 'a', day: 3),
        makeIncident(id: 'b', day: 2),
      ]);
      service.mine.add(<Incident>[makeIncident(id: 'a', day: 3)]);
      await pumpEventQueue();

      expect(provider.allIncidents.map((Incident i) => i.id), <String>['a', 'b']);
      expect(provider.myIncidents, hasLength(1));
      expect(provider.isLoading, isFalse);
    });

    test('starts empty and not loading when nobody is signed in', () async {
      provider.updateUser(null);
      await pumpEventQueue();

      expect(provider.allIncidents, isEmpty);
      expect(provider.isLoading, isFalse);
    });

    test('surfaces stream errors', () async {
      provider.updateUser(makeUser());
      await pumpEventQueue();

      // A permission failure hits both streams.
      service.all.addError(StateError('The stream broke.'));
      service.mine.addError(StateError('The stream broke.'));
      await pumpEventQueue();

      expect(provider.errorMessage, 'The stream broke.');
      expect(provider.isLoading, isFalse);
    });
  });

  group('filters', () {
    setUp(() async {
      provider.updateUser(makeUser());
      await pumpEventQueue();
      service.all.add(<Incident>[
        makeIncident(
          id: 'a',
          day: 4,
          title: 'Leaking tap',
          category: IncidentCategory.water,
          status: IncidentStatus.submitted,
        ),
        makeIncident(
          id: 'b',
          day: 3,
          title: 'Broken projector',
          category: IncidentCategory.facilities,
          status: IncidentStatus.inProgress,
          location: 'Science Block',
        ),
        makeIncident(
          id: 'c',
          day: 2,
          title: 'Flickering light',
          category: IncidentCategory.electricity,
          status: IncidentStatus.resolved,
        ),
      ]);
      await pumpEventQueue();
    });

    test('returns everything by default', () {
      expect(provider.filteredIncidents, hasLength(3));
    });

    test('filters by search across title, location and category', () {
      provider.setSearchQuery('projector');
      expect(provider.filteredIncidents.single.id, 'b');

      provider.setSearchQuery('hostel');
      expect(provider.filteredIncidents.map((Incident i) => i.id), <String>['a', 'c']);

      provider.setSearchQuery('Electricity');
      expect(provider.filteredIncidents.single.id, 'c');

      provider.setSearchQuery('nothing here');
      expect(provider.filteredIncidents, isEmpty);
    });

    test('filters by status and category together', () {
      provider.setStatusFilter(IncidentStatus.submitted);
      expect(provider.filteredIncidents.single.id, 'a');

      provider.setStatusFilter(null);
      provider.setCategoryFilter(IncidentCategory.facilities);
      expect(provider.filteredIncidents.single.id, 'b');
    });

  });

  group('counters', () {
    test('count my reports by status', () async {
      provider.updateUser(makeUser());
      await pumpEventQueue();

      service.mine.add(<Incident>[
        makeIncident(id: 'a', status: IncidentStatus.submitted),
        makeIncident(id: 'b', status: IncidentStatus.submitted),
        makeIncident(id: 'c', status: IncidentStatus.inProgress),
        makeIncident(id: 'd', status: IncidentStatus.resolved),
        makeIncident(id: 'e', owner: 'someone-else', status: IncidentStatus.resolved),
      ]);
      await pumpEventQueue();

      expect(provider.myReportCount, 5);
      expect(provider.mySubmittedCount, 2);
      expect(provider.myInProgressCount, 1);
      expect(provider.myResolvedCount, 2);
    });
  });

  group('submitIncident', () {
    test('saves the photo bytes with a Submitted report', () async {
      provider.updateUser(makeUser());
      await pumpEventQueue();

      final XFile photo = XFile.fromData(
        Uint8List.fromList(<int>[1, 2, 3]),
        name: 'photo.jpg',
        mimeType: 'image/jpeg',
      );

      final Incident? created = await provider.submitIncident(
        title: '  Leaking tap ',
        description: 'Water everywhere',
        category: IncidentCategory.water,
        location: ' Hostel C ',
        photo: photo,
      );

      expect(created, isNotNull);
      expect(service.createdPhoto, <int>[1, 2, 3]);
      expect(created!.id, 'inc-test-1');
      expect(created.title, 'Leaking tap');
      expect(created.location, 'Hostel C');
      expect(created.hasPhoto, isTrue);
      expect(created.status, IncidentStatus.submitted);
      expect(created.reportedByUid, 'uid-1');
      expect(created.reportedByName, 'Elijah Laddie');
      expect(created.statusHistory.single.status, IncidentStatus.submitted);
      expect(service.created?.id, 'inc-test-1');
      expect(provider.errorMessage, isNull);
    });

    test('saves no photo when none was picked', () async {
      provider.updateUser(makeUser());
      await pumpEventQueue();

      final Incident? created = await provider.submitIncident(
        title: 'Broken chair',
        description: 'Leg snapped',
        category: IncidentCategory.facilities,
        location: 'Block C',
      );

      expect(created, isNotNull);
      expect(service.createdPhoto, isNull);
      expect(created!.hasPhoto, isFalse);
    });

    test('refuses a photo larger than a Firestore document allows', () async {
      provider.updateUser(makeUser());
      await pumpEventQueue();

      final XFile huge = XFile.fromData(
        Uint8List(IncidentService.maxPhotoBytes + 1),
        name: 'huge.jpg',
        mimeType: 'image/jpeg',
      );

      final Incident? created = await provider.submitIncident(
        title: 'Broken chair',
        description: 'Leg snapped off the chair',
        category: IncidentCategory.facilities,
        location: 'Block C',
        photo: huge,
      );

      expect(created, isNull);
      expect(service.createCount, 0);
      expect(provider.errorMessage, contains('too large'));
    });

    test('reports a failed write', () async {
      provider.updateUser(makeUser());
      await pumpEventQueue();
      service.failCreate = true;

      final Incident? created = await provider.submitIncident(
        title: 'Broken chair',
        description: 'Leg snapped',
        category: IncidentCategory.facilities,
        location: 'Block C',
      );

      expect(created, isNull);
      expect(provider.errorMessage, 'The write failed.');
      expect(provider.isSubmitting, isFalse);
    });
  });

  group('updateStatus', () {
    test('is refused for students', () async {
      provider.updateUser(makeUser());
      await pumpEventQueue();

      final bool updated = await provider.updateStatus('a', IncidentStatus.resolved);

      expect(updated, isFalse);
      expect(service.updatedStatus, isNull);
      expect(provider.errorMessage, contains('Only staff'));
    });

    test('is allowed for staff', () async {
      provider.updateUser(makeUser(role: UserRole.staff));
      await pumpEventQueue();

      final bool updated = await provider.updateStatus('a', IncidentStatus.resolved);

      expect(updated, isTrue);
      expect(service.updatedId, 'a');
      expect(service.updatedStatus, IncidentStatus.resolved);
    });
  });

  group('delete rules', () {
    test('a student can delete only their own submitted report', () async {
      provider.updateUser(makeUser());
      await pumpEventQueue();

      final Incident mine = makeIncident(id: 'a');
      final Incident mineInProgress = makeIncident(id: 'b', status: IncidentStatus.inProgress);
      final Incident someoneElse = makeIncident(id: 'c', owner: 'uid-2');

      expect(provider.canDelete(mine), isTrue);
      expect(provider.canDelete(mineInProgress), isFalse);
      expect(provider.canDelete(someoneElse), isFalse);

      expect(await provider.deleteIncident(mine), isTrue);
      expect(service.deletedId, 'a');
    });

    test('refuses to delete a report that moved past Submitted', () async {
      provider.updateUser(makeUser());
      await pumpEventQueue();

      final bool deleted =
          await provider.deleteIncident(makeIncident(id: 'b', status: IncidentStatus.inProgress));

      expect(deleted, isFalse);
      expect(service.deletedId, isNull);
      expect(provider.errorMessage, contains('only delete'));
    });

    test('also removes the photo document', () async {
      provider.updateUser(makeUser());
      await pumpEventQueue();

      expect(await provider.deleteIncident(makeIncident(id: 'p', hasPhoto: true)), isTrue);
      expect(service.deletedWithPhoto, isTrue);
    });
  });

  group('photos', () {
    test('are loaded once and shared between screens', () async {
      service.photos['p'] = Uint8List.fromList(<int>[9, 9]);
      final Incident withPhoto = makeIncident(id: 'p', hasPhoto: true);

      final Uint8List? first = await provider.photoFor(withPhoto);
      final Uint8List? second = await provider.photoFor(withPhoto);

      expect(first, <int>[9, 9]);
      expect(identical(first, second), isTrue);
      expect(service.photoLoads, 1);
    });

    test('are not requested for reports without one', () {
      expect(provider.photoFor(makeIncident(id: 'x')), isNull);
      expect(service.photoLoads, 0);
    });
  });

  group('edit rules', () {
    test('the reporter can edit their own submitted report', () async {
      provider.updateUser(makeUser());
      await pumpEventQueue();

      final bool saved = await provider.updateIncidentDetails(
        makeIncident(id: 'a'),
        title: '  Leaking tap in Block A  ',
        description: 'Water is pooling near the sinks.',
        category: IncidentCategory.water,
        location: 'Block A',
      );

      expect(saved, isTrue);
      expect(service.editedId, 'a');
      expect(service.editedFields!['title'], 'Leaking tap in Block A');
    });

    test('is refused once staff have started or for other users', () async {
      provider.updateUser(makeUser());
      await pumpEventQueue();

      expect(provider.canEdit(makeIncident(id: 'b', status: IncidentStatus.inProgress)), isFalse);
      expect(provider.canEdit(makeIncident(id: 'c', owner: 'uid-2')), isFalse);

      final bool saved = await provider.updateIncidentDetails(
        makeIncident(id: 'c', owner: 'uid-2'),
        title: 'Changed title',
        description: 'Changed description text.',
        category: IncidentCategory.safety,
        location: 'Library',
      );

      expect(saved, isFalse);
      expect(service.editedId, isNull);
      expect(provider.errorMessage, contains('only edit'));
    });
  });

  group('anonymous reports', () {
    test('hide the reporter name but keep the uid for the rules', () async {
      provider.updateUser(makeUser());
      await pumpEventQueue();

      final Incident? created = await provider.submitIncident(
        title: 'Unsafe stairwell',
        description: 'The stairwell light has been out for days.',
        category: IncidentCategory.safety,
        location: 'Block A',
        isAnonymous: true,
      );

      expect(created, isNotNull);
      expect(created!.isAnonymous, isTrue);
      expect(created.reportedByName, Incident.anonymousName);
      expect(created.reportedByUid, 'uid-1');
      expect(created.toMap()['isAnonymous'], isTrue);
    });
  });
}
