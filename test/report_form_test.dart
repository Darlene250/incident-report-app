import 'package:campus_incident_app/core/theme/app_theme.dart';
import 'package:campus_incident_app/core/widgets/category_tile.dart';
import 'package:campus_incident_app/models/incident.dart';
import 'package:campus_incident_app/providers/auth_provider.dart';
import 'package:campus_incident_app/providers/incident_provider.dart';
import 'package:campus_incident_app/screens/report_form/report_form_screen.dart';
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

  Future<void> pumpForm(WidgetTester tester, {Size size = const Size(390, 1400)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<IncidentProvider>.value(value: incidents),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const ReportFormScreen()),
      ),
    );
    await tester.pump();
  }

  Future<void> fillValidForm(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(CategoryTile, 'Water'));
    await tester.pump();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Leaking tap in the hostel',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'The tap in Hostel C floor two keeps running all night.',
    );
    await tester.tap(find.text('Select a campus location'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Library').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('shows all five categories in the required order',
      (WidgetTester tester) async {
    await pumpForm(tester);

    expect(find.text('Report an Incident'), findsOneWidget);
    final List<CategoryTile> tiles =
        tester.widgetList<CategoryTile>(find.byType(CategoryTile)).toList();
    expect(tiles.map((CategoryTile t) => t.label), <String>[
      'Facilities',
      'Water',
      'Electricity',
      'Safety',
      'Sanitation',
    ]);
    expect(find.text('Select a category'), findsOneWidget);
    expect(find.text('Add a photo (optional)'), findsOneWidget);
    expect(find.text('Tap to add photos'), findsOneWidget);
    expect(find.text('Submit Report'), findsOneWidget);
  });

  testWidgets('validates every required field inline', (WidgetTester tester) async {
    await pumpForm(tester);

    await tester.tap(find.text('Submit Report'));
    await tester.pump();

    expect(find.text('Select a category'), findsNWidgets(2)); // label + error
    expect(find.text('Enter a title'), findsOneWidget);
    expect(find.text('Enter a description'), findsOneWidget);
    expect(find.text('Select a location'), findsOneWidget);
    expect(service.created, isNull);
  });

  testWidgets('enforces minimum lengths', (WidgetTester tester) async {
    await pumpForm(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'Tap');
    await tester.enterText(find.byType(TextFormField).at(1), 'Too short');
    await tester.tap(find.text('Submit Report'));
    await tester.pump();

    expect(find.text('Use at least 5 characters'), findsOneWidget);
    expect(find.text('Use at least 15 characters'), findsOneWidget);
    expect(service.created, isNull);
  });

  testWidgets('submits a valid report, pops and shows success',
      (WidgetTester tester) async {
    await pumpForm(tester);
    await fillValidForm(tester);

    await tester.tap(find.text('Submit Report'));
    await tester.pump();
    await tester.pump();

    expect(service.created, isNotNull);
    expect(service.created!.title, 'Leaking tap in the hostel');
    expect(service.created!.category, IncidentCategory.water);
    expect(service.created!.location, 'Library');
    expect(service.created!.status, IncidentStatus.submitted);
    expect(service.created!.reportedByUid, 'uid-1');
    expect(service.created!.reportedByName, 'Elijah Laddie');
    expect(service.createdPhoto, isNull);
    expect(find.text('Report submitted successfully.'), findsOneWidget);
  });

  testWidgets('keeps the entered data when submitting fails',
      (WidgetTester tester) async {
    service.failCreate = true;
    await pumpForm(tester);
    await fillValidForm(tester);

    await tester.tap(find.text('Submit Report'));
    await tester.pump();
    await tester.pump();

    expect(find.text('The write failed.'), findsOneWidget);
    // Still on the form, with everything the user typed intact.
    expect(find.byType(ReportFormScreen), findsOneWidget);
    expect(find.text('Leaking tap in the hostel'), findsOneWidget);
    // The dropdown keeps the selected item plus a hidden copy of every item.
    expect(find.text('Library'), findsWidgets);
  });

  testWidgets('does not overflow on a 360 x 640 screen', (WidgetTester tester) async {
    await pumpForm(tester, size: const Size(360, 640));

    // Scroll the whole form to force layout of every section.
    final Finder scrollable = find.byType(SingleChildScrollView);
    await tester.drag(scrollable, const Offset(0, -400));
    await tester.pump();
    await tester.drag(scrollable, const Offset(0, -400));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Submit Report'), findsOneWidget);
  });

  testWidgets('ignores double taps while submitting', (WidgetTester tester) async {
    service.createDelay = const Duration(milliseconds: 300);
    await pumpForm(tester);
    await fillValidForm(tester);

    await tester.tap(find.text('Submit Report'));
    await tester.pump(const Duration(milliseconds: 50));

    // While busy the label is replaced by a spinner and the button is disabled.
    expect(find.text('Submit Report'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 400));

    expect(service.createCount, 1);
  });

  testWidgets('category tiles are single select', (WidgetTester tester) async {
    await pumpForm(tester);

    await tester.tap(find.widgetWithText(CategoryTile, 'Safety'));
    await tester.pump();

    final List<CategoryTile> tiles =
        tester.widgetList<CategoryTile>(find.byType(CategoryTile)).toList();
    expect(tiles.where((CategoryTile t) => t.isSelected).length, 1);
    expect(tiles.firstWhere((CategoryTile t) => t.isSelected).label, 'Safety');
  });
}
