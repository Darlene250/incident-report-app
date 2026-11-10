import 'package:campus_incident_app/core/theme/app_theme.dart';
import 'package:campus_incident_app/core/widgets/error_view.dart';
import 'package:campus_incident_app/core/widgets/incident_card.dart';
import 'package:campus_incident_app/core/widgets/loading_view.dart';
import 'package:campus_incident_app/models/incident.dart';
import 'package:campus_incident_app/providers/auth_provider.dart';
import 'package:campus_incident_app/providers/incident_provider.dart';
import 'package:campus_incident_app/screens/reports/reports_screen.dart';
import 'package:campus_incident_app/core/widgets/filter_chip_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers/fakes.dart';

void main() {
  late FakeIncidentService service;
  late IncidentProvider incidents;
  late FakeAuthProvider auth;

  setUp(() {
    service = FakeIncidentService();
    incidents = IncidentProvider(incidentService: service);
    auth = FakeAuthProvider(user: makeUser());
    incidents.updateUser(auth.currentUser);
  });

  tearDown(() async {
    incidents.dispose();
    auth.dispose();
    await service.dispose();
  });

  Future<void> pumpReports(
    WidgetTester tester, {
    Size size = const Size(390, 1000),
    List<Incident>? reports,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<IncidentProvider>.value(value: incidents),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const ReportsScreen()),
      ),
    );
    await tester.pump();

    if (reports != null) {
      service.all.add(reports);
      service.mine.add(reports);
      await tester.pump();
      await tester.pump();
    }
  }

  List<Incident> sampleReports() => <Incident>[
        makeIncident(
          id: 'a',
          owner: 'uid-1',
          title: 'Leaking tap',
          description: 'Water everywhere in the washroom',
          location: 'Hostel C',
          category: IncidentCategory.water,
          status: IncidentStatus.submitted,
          day: 4,
        ),
        makeIncident(
          id: 'b',
          owner: 'uid-2',
          title: 'Broken projector',
          description: 'No display in the lab',
          location: 'Science Block',
          category: IncidentCategory.facilities,
          status: IncidentStatus.inProgress,
          day: 3,
        ),
        makeIncident(
          id: 'c',
          owner: 'uid-3',
          title: 'Flickering light',
          description: 'Corridor light keeps flickering',
          location: 'Library',
          category: IncidentCategory.electricity,
          status: IncidentStatus.resolved,
          day: 2,
        ),
      ];

  testWidgets('shows every report for a student, newest first',
      (WidgetTester tester) async {
    await pumpReports(tester, reports: sampleReports());

    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('Search reports'), findsOneWidget);
    expect(find.byType(IncidentCard), findsNWidgets(3));
    expect(find.text('Leaking tap'), findsOneWidget);
    expect(find.text('Broken projector'), findsOneWidget);
    expect(find.text('Flickering light'), findsOneWidget);

    // Both chip rows start on "All".
    expect(find.text('All'), findsNWidgets(2));
    expect(find.text('Submitted'), findsWidgets);
    expect(find.text('In Progress'), findsWidgets);
    expect(find.text('Resolved'), findsWidgets);
    expect(find.text('Facilities'), findsOneWidget);
    expect(find.text('Water'), findsOneWidget);
    expect(find.text('Electricity'), findsOneWidget);

    // The category row scrolls horizontally to reach the last chips.
    await tester.drag(
      find.byType(FilterChipRow<IncidentCategory>),
      const Offset(-300, 0),
    );
    await tester.pump();
    expect(find.text('Safety'), findsOneWidget);
    expect(find.text('Sanitation'), findsOneWidget);
  });

  testWidgets('search filters by title, description and location',
      (WidgetTester tester) async {
    await pumpReports(tester, reports: sampleReports());

    await tester.enterText(find.byType(TextFormField), 'projector');
    await tester.pump();
    expect(find.byType(IncidentCard), findsOneWidget);
    expect(find.text('Broken projector'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'washroom');
    await tester.pump();
    expect(find.byType(IncidentCard), findsOneWidget);
    expect(find.text('Leaking tap'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'library');
    await tester.pump();
    expect(find.byType(IncidentCard), findsOneWidget);
    expect(find.text('Flickering light'), findsOneWidget);
  });

  testWidgets('status chips filter the list', (WidgetTester tester) async {
    await pumpReports(tester, reports: sampleReports());

    // The chip label also exists on the cards, so tap the chip in the row.
    await tester.tap(find.widgetWithText(InkWell, 'In Progress').first);
    await tester.pump();

    expect(find.byType(IncidentCard), findsOneWidget);
    expect(find.text('Broken projector'), findsOneWidget);
    expect(incidents.statusFilter, IncidentStatus.inProgress);

    await tester.tap(find.widgetWithText(InkWell, 'All').first);
    await tester.pump();
    expect(find.byType(IncidentCard), findsNWidgets(3));
    expect(incidents.statusFilter, isNull);
  });

  testWidgets('category chips filter the list', (WidgetTester tester) async {
    await pumpReports(tester, reports: sampleReports());

    await tester.tap(find.widgetWithText(InkWell, 'Water').first);
    await tester.pump();

    expect(find.byType(IncidentCard), findsOneWidget);
    expect(find.text('Leaking tap'), findsOneWidget);
    expect(incidents.categoryFilter, IncidentCategory.water);
  });

  testWidgets('search and filters combine', (WidgetTester tester) async {
    await pumpReports(tester, reports: sampleReports());

    await tester.tap(find.widgetWithText(InkWell, 'In Progress').first);
    await tester.pump();
    await tester.enterText(find.byType(TextFormField), 'library');
    await tester.pump();

    expect(find.byType(IncidentCard), findsNothing);
    expect(find.text('No reports found'), findsOneWidget);
  });

  testWidgets('shows the empty state', (WidgetTester tester) async {
    await pumpReports(tester, reports: <Incident>[]);

    expect(find.byType(IncidentCard), findsNothing);
    expect(find.text('No reports found'), findsOneWidget);
  });

  testWidgets('shows the loading state while the streams have not emitted',
      (WidgetTester tester) async {
    await pumpReports(tester);

    expect(find.byType(LoadingView), findsOneWidget);
  });

  testWidgets('shows an error state with a retry', (WidgetTester tester) async {
    await pumpReports(tester);

    service.all.addError(StateError('The stream broke.'));
    service.mine.addError(StateError('The stream broke.'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('The stream broke.'), findsOneWidget);

    // Retrying re-subscribes and can recover.
    await tester.tap(find.text('Try again'));
    await tester.pump();
    service.all.add(sampleReports());
    service.mine.add(sampleReports());
    await tester.pump();
    await tester.pump();

    expect(find.byType(IncidentCard), findsNWidgets(3));
  });

  testWidgets('does not overflow at 360 wide', (WidgetTester tester) async {
    await pumpReports(tester, size: const Size(360, 640), reports: sampleReports());

    expect(tester.takeException(), isNull);
    expect(find.byType(IncidentCard), findsWidgets);
  });
}
