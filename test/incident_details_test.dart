import 'package:campus_incident_app/core/theme/app_theme.dart';
import 'package:campus_incident_app/core/widgets/status_chip.dart';
import 'package:campus_incident_app/models/app_user.dart';
import 'package:campus_incident_app/models/incident.dart';
import 'package:campus_incident_app/providers/auth_provider.dart';
import 'package:campus_incident_app/providers/incident_provider.dart';
import 'package:campus_incident_app/screens/details/incident_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers/fakes.dart';

void main() {
  late FakeIncidentService service;
  late IncidentProvider incidents;
  late FakeAuthProvider auth;

  void configure({UserRole role = UserRole.student, String uid = 'uid-1'}) {
    service = FakeIncidentService();
    incidents = IncidentProvider(incidentService: service);
    auth = FakeAuthProvider(user: makeUser(role: role, uid: uid));
    incidents.updateUser(auth.currentUser);
  }

  tearDown(() async {
    incidents.dispose();
    auth.dispose();
    await service.dispose();
  });

  Future<void> openDetails(WidgetTester tester, Incident incident) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<IncidentProvider>.value(value: incidents),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (BuildContext context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          IncidentDetailsScreen(incidentId: incident.id),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    service.single.add(incident);
    await tester.pump();
  }

  Incident submittedIncident() => makeIncident(
        id: 'inc-1',
        owner: 'uid-1',
        title: 'Leaking tap in Hall C',
        description: 'The tap has been running for two days and floods the corridor.',
        location: 'Hostel C',
        category: IncidentCategory.water,
        status: IncidentStatus.submitted,
      ).copyWith(
        statusHistory: <StatusChange>[
          StatusChange(
            status: IncidentStatus.submitted,
            changedAt: DateTime.utc(2026, 2, 3, 9, 5),
            changedByUid: 'uid-1',
          ),
        ],
      );

  testWidgets('shows the summary, timeline and description', (WidgetTester tester) async {
    configure();
    final Incident incident = submittedIncident();
    await openDetails(tester, incident);

    expect(find.text('Incident Details'), findsOneWidget);
    expect(find.text('Leaking tap in Hall C'), findsOneWidget);
    expect(find.text('Hostel C'), findsOneWidget);
    expect(find.byType(StatusChip), findsOneWidget);
    expect(find.textContaining('Reported by Elijah Laddie'), findsOneWidget);
    expect(find.textContaining('Submitted on'), findsOneWidget);
    expect(find.text('Status Timeline'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(
      find.text('The tap has been running for two days and floods the corridor.'),
      findsOneWidget,
    );
  });

  testWidgets('timeline marks reached steps and dashes the rest',
      (WidgetTester tester) async {
    configure();
    await openDetails(tester, submittedIncident());

    // Submitted is the current step, so nothing is ticked and two steps show a dash.
    expect(find.byIcon(Icons.check_rounded), findsNothing);
    expect(find.text('—'), findsNWidgets(2));
    expect(find.text('Submitted'), findsWidgets);
    expect(find.text('In Progress'), findsWidgets);
    expect(find.text('Resolved'), findsWidgets);
  });

  testWidgets('owner sees the delete menu only while Submitted',
      (WidgetTester tester) async {
    configure();
    await openDetails(tester, submittedIncident());

    expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);

    // Staff move it on, so the owner can no longer withdraw it.
    service.single.add(
      makeIncident(id: 'inc-1', owner: 'uid-1', status: IncidentStatus.inProgress),
    );
    await tester.pump();

    expect(find.byIcon(Icons.more_vert_rounded), findsNothing);
  });

  testWidgets('deleting asks for confirmation and removes the report',
      (WidgetTester tester) async {
    configure();
    await openDetails(tester, submittedIncident());

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Delete report'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Delete report?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pump();
    await tester.pump();

    expect(service.deletedId, 'inc-1');
    expect(find.text('Report deleted.'), findsOneWidget);
  });

  testWidgets('students never see the update section', (WidgetTester tester) async {
    configure();
    await openDetails(tester, submittedIncident());

    expect(find.text('Update Status'), findsNothing);
    expect(find.text('Update'), findsNothing);
  });

  testWidgets('staff can change the status', (WidgetTester tester) async {
    configure(role: UserRole.staff, uid: 'staff-1');
    await openDetails(tester, submittedIncident());

    expect(find.text('Update Status'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<IncidentStatus>));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Resolved').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Update'));
    await tester.pump();
    await tester.pump();

    expect(service.updatedId, 'inc-1');
    expect(service.updatedStatus, IncidentStatus.resolved);
    expect(find.text('Status updated to Resolved.'), findsOneWidget);
  });
}
