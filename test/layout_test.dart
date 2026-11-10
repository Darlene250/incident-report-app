import 'package:campus_incident_app/core/theme/app_theme.dart';
import 'package:campus_incident_app/core/widgets/responsive_shell.dart';
import 'package:campus_incident_app/models/incident.dart';
import 'package:campus_incident_app/providers/auth_provider.dart';
import 'package:campus_incident_app/providers/incident_provider.dart';
import 'package:campus_incident_app/screens/auth/login_screen.dart';
import 'package:campus_incident_app/screens/auth/register_screen.dart';
import 'package:campus_incident_app/screens/details/incident_details_screen.dart';
import 'package:campus_incident_app/screens/home/main_shell.dart';
import 'package:campus_incident_app/screens/report_form/report_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers/fakes.dart';

/// Layout checks: no overflow on the three target widths and the web column is
/// capped at 430.
void main() {
  late FakeIncidentService service;
  late IncidentProvider incidents;
  late FakeAuthProvider auth;

  const List<Size> widths = <Size>[
    Size(360, 640),
    Size(390, 844),
    Size(1200, 900),
  ];

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

  List<Incident> reports() => <Incident>[
        makeIncident(
          id: 'a',
          title: 'Broken streetlight near the library',
          location: 'Main Library, Block B',
          status: IncidentStatus.inProgress,
        ),
        makeIncident(
          id: 'b',
          title: 'Leaking tap in hostel washroom',
          location: 'Hostel C, Floor 2',
          category: IncidentCategory.sanitation,
        ),
      ];

  Widget host(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<IncidentProvider>.value(value: incidents),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        builder: (BuildContext context, Widget? widget) =>
            ResponsiveShell(child: widget ?? const SizedBox.shrink()),
        home: child,
      ),
    );
  }

  for (final Size size in widths) {
    testWidgets('shell tabs fit ${size.width} wide', (WidgetTester tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(host(const MainShell()));
      await tester.pump();
      service.all.add(reports());
      service.mine.add(reports());
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Reports'));
      await tester.pump();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Profile'));
      await tester.pump();
      expect(tester.takeException(), isNull);

      // Wide screens are centred in a 430px column.
      final double shellWidth = tester.getSize(find.byType(Scaffold).first).width;
      expect(shellWidth, size.width > 430 ? 430 : size.width);
    });
  }

  for (final Size size in widths) {
    testWidgets('report form fits ${size.width} wide', (WidgetTester tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(host(const ReportFormScreen()));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  }

  for (final Size size in widths) {
    testWidgets('details fit ${size.width} wide', (WidgetTester tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(host(const IncidentDetailsScreen(incidentId: 'a')));
      await tester.pump();
      service.single.add(
        makeIncident(
          id: 'a',
          title: 'Broken streetlight near the library',
          status: IncidentStatus.inProgress,
        ).copyWith(
          statusHistory: <StatusChange>[
            StatusChange(
              status: IncidentStatus.submitted,
              changedAt: DateTime.utc(2026, 2, 3, 9, 5),
              changedByUid: 'uid-1',
            ),
            StatusChange(
              status: IncidentStatus.inProgress,
              changedAt: DateTime.utc(2026, 2, 4, 11, 30),
              changedByUid: 'staff-1',
            ),
          ],
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Status Timeline'), findsOneWidget);
    });
  }

  for (final Size size in widths) {
    testWidgets('auth screens fit ${size.width} wide', (WidgetTester tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(host(const LoginScreen()));
      await tester.pump();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(host(const RegisterScreen()));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
}
