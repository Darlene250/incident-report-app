import 'package:campus_incident_app/core/theme/app_theme.dart';
import 'package:campus_incident_app/core/widgets/filter_chip_row.dart';
import 'package:campus_incident_app/core/widgets/incident_card.dart';
import 'package:campus_incident_app/core/widgets/loading_view.dart';
import 'package:campus_incident_app/core/widgets/summary_tile.dart';
import 'package:campus_incident_app/models/app_user.dart';
import 'package:campus_incident_app/models/incident.dart';
import 'package:campus_incident_app/providers/auth_provider.dart';
import 'package:campus_incident_app/providers/incident_provider.dart';
import 'package:campus_incident_app/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers/fakes.dart';

void main() {
  late FakeIncidentService service;
  late IncidentProvider incidents;
  late FakeAuthProvider auth;
  late FakeAuthService authService;

  void configure({UserRole role = UserRole.student}) {
    service = FakeIncidentService();
    incidents = IncidentProvider(incidentService: service);
    authService = FakeAuthService();
    auth = FakeAuthProvider(
      user: makeUser(role: role, department: 'Computer Science', location: 'Hostel A'),
      authService: authService,
    );
    incidents.updateUser(auth.currentUser);
  }

  tearDown(() async {
    incidents.dispose();
    auth.dispose();
    await service.dispose();
  });

  Future<void> pumpProfile(
    WidgetTester tester, {
    List<Incident>? mine,
    Size size = const Size(390, 1400),
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
        child: MaterialApp(theme: AppTheme.light, home: const ProfileScreen()),
      ),
    );
    await tester.pump();

    if (mine != null) {
      service.all.add(mine);
      service.mine.add(mine);
      await tester.pump();
      await tester.pump();
    }
  }

  List<Incident> sampleMine() => <Incident>[
        makeIncident(id: 'a', title: 'Leaking tap', status: IncidentStatus.submitted, day: 4),
        makeIncident(id: 'b', title: 'Broken projector', status: IncidentStatus.inProgress, day: 3),
        makeIncident(id: 'c', title: 'Flickering light', status: IncidentStatus.resolved, day: 2),
      ];

  testWidgets('shows the profile card, role chip and stat tiles',
      (WidgetTester tester) async {
    configure();
    await pumpProfile(tester, mine: sampleMine());

    expect(find.text('My Reports'), findsOneWidget);
    expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
    expect(find.text('Elijah Laddie'), findsOneWidget);
    expect(find.text('EL'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Computer Science'), findsOneWidget);
    expect(find.text('Hostel A'), findsOneWidget);

    final Finder tiles = find.byType(SummaryTile);
    expect(tiles, findsNWidgets(3));
    expect(tester.widget<SummaryTile>(tiles.at(0)).count, 3); // Total
    expect(tester.widget<SummaryTile>(tiles.at(1)).count, 1); // In Progress
    expect(tester.widget<SummaryTile>(tiles.at(2)).count, 1); // Resolved
    expect(find.text('Total Reports'), findsOneWidget);
  });

  testWidgets('marks staff accounts and hides empty profile fields',
      (WidgetTester tester) async {
    service = FakeIncidentService();
    incidents = IncidentProvider(incidentService: service);
    authService = FakeAuthService();
    auth = FakeAuthProvider(
      user: makeUser(
        role: UserRole.staff,
        fullName: 'Mary Staff',
        department: '',
        location: '',
      ),
      authService: authService,
    );
    incidents.updateUser(auth.currentUser);

    await pumpProfile(tester, mine: <Incident>[]);

    expect(find.text('Mary Staff'), findsOneWidget);
    expect(find.text('Staff'), findsOneWidget);
    // No department or location stored, so neither line is rendered.
    expect(find.byIcon(Icons.menu_book_outlined), findsNothing);
    expect(find.byIcon(Icons.location_on_outlined), findsNothing);
  });

  testWidgets('status chips filter my reports', (WidgetTester tester) async {
    configure();
    await pumpProfile(tester, mine: sampleMine());

    expect(find.byType(IncidentCard), findsNWidgets(3));

    final Finder statusRow = find.byType(FilterChipRow<IncidentStatus>);

    await tester.tap(find.descendant(of: statusRow, matching: find.text('In Progress')));
    await tester.pump();

    expect(find.byType(IncidentCard), findsOneWidget);
    expect(find.text('Broken projector'), findsOneWidget);

    await tester.tap(find.descendant(of: statusRow, matching: find.text('All')));
    await tester.pump();
    expect(find.byType(IncidentCard), findsNWidgets(3));

    // The filter is local to this tab, not the shared provider filter.
    expect(incidents.statusFilter, isNull);
  });

  testWidgets('shows loading and empty states', (WidgetTester tester) async {
    configure();
    await pumpProfile(tester);
    expect(find.byType(LoadingView), findsOneWidget);

    service.all.add(<Incident>[]);
    service.mine.add(<Incident>[]);
    await tester.pump();
    await tester.pump();

    expect(find.text('You have not reported anything yet'), findsOneWidget);
  });

  testWidgets('logout asks for confirmation before signing out',
      (WidgetTester tester) async {
    configure();
    await pumpProfile(tester, mine: <Incident>[]);

    await tester.tap(find.byIcon(Icons.logout_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Sign out?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(authService.signedOut, isFalse);

    await tester.tap(find.byIcon(Icons.logout_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
    await tester.pump();
    await tester.pump();

    expect(authService.signedOut, isTrue);
  });
}
