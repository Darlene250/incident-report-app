import 'package:campus_incident_app/core/constants/incident_status.dart';
import 'package:campus_incident_app/core/theme/app_theme.dart';
import 'package:campus_incident_app/core/widgets/incident_card.dart';
import 'package:campus_incident_app/core/widgets/primary_button.dart';
import 'package:campus_incident_app/core/widgets/responsive_shell.dart';
import 'package:campus_incident_app/core/widgets/status_chip.dart';
import 'package:campus_incident_app/core/widgets/summary_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The app shell only; the real app root needs an initialized Firebase.
Widget _shellHost() {
  return MaterialApp(
    theme: AppTheme.light,
    builder: (BuildContext context, Widget? child) =>
        ResponsiveShell(child: child ?? const SizedBox.shrink()),
    home: const Scaffold(
      body: Center(child: Text('Campus Incident Reporting')),
    ),
  );
}

Widget _host(Widget child, {double width = 390}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: SizedBox(width: width, child: Center(child: child)),
    ),
  );
}

void main() {
  testWidgets('app renders inside the responsive shell', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_shellHost());
    await tester.pump();

    expect(find.byType(ResponsiveShell), findsOneWidget);
    expect(find.text('Campus Incident Reporting'), findsOneWidget);
  });

  testWidgets('wide screens clamp the app column to 430', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_shellHost());
    await tester.pump();

    expect(tester.getSize(find.byType(ResponsiveShell)).width, 1440);
    expect(tester.getSize(find.byType(Scaffold).first).width, 430);
  });

  testWidgets('incident card fits a 360 wide screen without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _host(
        Padding(
          padding: const EdgeInsets.all(20),
          child: IncidentCard(
            title: 'Broken streetlight outside the library',
            location: 'Main Library, Block B',
            time: DateTime.now().subtract(const Duration(hours: 2)),
            status: IncidentStatus.inProgress,
            onTap: () {},
          ),
        ),
        width: 360,
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(StatusChip), findsOneWidget);
  });

  testWidgets('primary button shows a spinner while loading',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _host(const PrimaryButton(label: 'Submit report', isLoading: true)),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Submit report'), findsNothing);

    // A busy button keeps the primary fill instead of the disabled tint.
    final FilledButton button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(
      button.style?.backgroundColor?.resolve(<WidgetState>{WidgetState.disabled}),
      AppColors.primary,
    );
  });

  testWidgets('summary tile shows its count', (WidgetTester tester) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 160,
          child: SummaryTile(
            label: 'My Reports',
            count: 7,
            icon: Icons.description_outlined,
            backgroundColor: AppColors.myReportsTile,
            iconColor: AppColors.myReportsIcon,
          ),
        ),
      ),
    );

    expect(find.text('7'), findsOneWidget);
    expect(find.text('My Reports'), findsOneWidget);
  });
}
