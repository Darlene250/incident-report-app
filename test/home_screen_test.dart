import 'package:campus_incident_app/core/theme/app_theme.dart';
import 'package:campus_incident_app/core/widgets/incident_card.dart';
import 'package:campus_incident_app/core/widgets/summary_tile.dart';
import 'package:campus_incident_app/models/app_user.dart';
import 'package:campus_incident_app/models/incident.dart';
import 'package:campus_incident_app/providers/auth_provider.dart';
import 'package:campus_incident_app/providers/incident_provider.dart';
import 'package:campus_incident_app/screens/home/main_shell.dart';
import 'package:campus_incident_app/screens/report_form/report_form_screen.dart';
import 'package:campus_incident_app/screens/home/widgets/app_bottom_bar.dart';
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
  });

  tearDown(() async {
    incidents.dispose();
    auth.dispose();
    await service.dispose();
  });

  Future<void> pumpShell(
    WidgetTester tester, {
    required AppUser user,
    Size size = const Size(390, 1200),
    List<Incident> all = const <Incident>[],
    List<Incident> mine = const <Incident>[],
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    auth = FakeAuthProvider(user: user);
    incidents.updateUser(user);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<IncidentProvider>.value(value: incidents),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const MainShell()),
      ),
    );
    await tester.pump();

    // Deliver the Firestore snapshots and rebuild.
    service.all.add(all);
    service.mine.add(mine);
    await tester.pump();
    await tester.pump();
  }

  testWidgets('renders greeting, subtitle, hero and four tiles at 360 wide',
      (WidgetTester tester) async {
    await pumpShell(tester, user: makeUser(), size: const Size(360, 800));

    expect(tester.takeException(), isNull);
    expect(find.text('Hello, Elijah 👋'), findsOneWidget);
    expect(find.text('Help make our campus safer.'), findsOneWidget);
    expect(find.text('Report issues and track their resolution.'), findsOneWidget);
    expect(find.text('See an issue on campus?'), findsOneWidget);
    expect(find.text('Report an Issue'), findsOneWidget);
    expect(find.byType(SummaryTile), findsNWidgets(4));
    expect(find.text('Report Summary'), findsOneWidget);
    expect(find.text('Recent Reports'), findsOneWidget);
    // No notification bell on this screen.
    expect(find.byIcon(Icons.notifications_outlined), findsNothing);
    expect(find.byIcon(Icons.notifications_none), findsNothing);
  });

  testWidgets('shows the three most recent of my reports for a student',
      (WidgetTester tester) async {
    await pumpShell(
      tester,
      user: makeUser(),
      all: <Incident>[
        makeIncident(id: 'a', title: 'Mine newest', day: 5),
        makeIncident(id: 'b', owner: 'uid-2', title: 'Someone else', day: 4),
        makeIncident(id: 'c', title: 'Mine second', day: 3),
        makeIncident(id: 'd', title: 'Mine third', day: 2),
        makeIncident(id: 'e', title: 'Mine fourth', day: 1),
      ],
      mine: <Incident>[
        makeIncident(id: 'a', title: 'Mine newest', status: IncidentStatus.resolved, day: 5),
        makeIncident(id: 'c', title: 'Mine second', status: IncidentStatus.inProgress, day: 3),
        makeIncident(id: 'd', title: 'Mine third', day: 2),
        makeIncident(id: 'e', title: 'Mine fourth', day: 1),
      ],
    );

    expect(find.byType(IncidentCard), findsNWidgets(3));
    expect(find.text('Mine newest'), findsOneWidget);
    expect(find.text('Mine third'), findsOneWidget);
    expect(find.text('Mine fourth'), findsNothing);
    expect(find.text('Someone else'), findsNothing);

    final Finder tiles = find.byType(SummaryTile);
    expect(tester.widget<SummaryTile>(tiles.at(0)).count, 4); // My Reports
    expect(tester.widget<SummaryTile>(tiles.at(1)).count, 1); // In Progress
    expect(tester.widget<SummaryTile>(tiles.at(2)).count, 1); // Resolved
    expect(tester.widget<SummaryTile>(tiles.at(3)).count, 2); // Submitted
  });

  testWidgets('staff see the newest reports from everyone', (WidgetTester tester) async {
    await pumpShell(
      tester,
      user: makeUser(role: UserRole.staff),
      all: <Incident>[
        makeIncident(id: 'a', owner: 'uid-7', title: 'From a student', day: 5),
        makeIncident(id: 'b', owner: 'uid-8', title: 'From another', day: 4),
        makeIncident(id: 'c', owner: 'uid-9', title: 'Third one', day: 3),
        makeIncident(id: 'd', owner: 'uid-9', title: 'Fourth one', day: 2),
      ],
    );

    expect(find.byType(IncidentCard), findsNWidgets(3));
    expect(find.text('From a student'), findsOneWidget);
    expect(find.text('Fourth one'), findsNothing);
  });

  testWidgets('shows the empty state when nothing has been reported',
      (WidgetTester tester) async {
    await pumpShell(tester, user: makeUser());

    expect(find.byType(IncidentCard), findsNothing);
    expect(find.text('You have not reported anything yet'), findsOneWidget);
  });

  testWidgets('bottom bar switches between the tabs', (WidgetTester tester) async {
    await pumpShell(tester, user: makeUser(), size: const Size(390, 900));

    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 0);

    await tester.tap(find.text('Reports'));
    await tester.pump();
    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 1);

    await tester.tap(find.text('Profile'));
    await tester.pump();
    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 2);

    await tester.tap(find.text('Home'));
    await tester.pump();
    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 0);
  });

  testWidgets('the raised + button is wired to the report form',
      (WidgetTester tester) async {
    await pumpShell(tester, user: makeUser(), size: const Size(390, 900));

    await tester.tap(
      find.descendant(
        of: find.byType(AppBottomBar),
        matching: find.byIcon(Icons.add_rounded),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(ReportFormScreen), findsOneWidget);
  });

  testWidgets('the hero button is wired to the report form',
      (WidgetTester tester) async {
    await pumpShell(tester, user: makeUser(), size: const Size(390, 900));

    await tester.tap(find.text('Report an Issue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(ReportFormScreen), findsOneWidget);
  });
}
