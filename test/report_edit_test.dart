import 'package:campus_incident_app/core/theme/app_theme.dart';
import 'package:campus_incident_app/models/incident.dart';
import 'package:campus_incident_app/providers/auth_provider.dart';
import 'package:campus_incident_app/providers/incident_provider.dart';
import 'package:campus_incident_app/screens/report_form/report_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers/fakes.dart';

/// Edit mode of the report form (reporter corrections while Submitted).
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

  Future<void> pumpEdit(WidgetTester tester, Incident incident) async {
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
              body: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ReportFormScreen(initial: incident),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('prefills the report and saves the changes', (WidgetTester tester) async {
    final Incident incident = makeIncident(
      id: 'e1',
      title: 'Leaking tap',
      description: 'Water everywhere in the bathroom.',
      location: 'Library',
    );
    await pumpEdit(tester, incident);

    expect(find.text('Edit Report'), findsOneWidget);
    expect(find.text('Leaking tap'), findsOneWidget);
    // The photo and anonymity choices are fixed once a report is filed.
    expect(find.text('Add a photo (optional)'), findsNothing);
    expect(find.text('Report anonymously'), findsNothing);

    await tester.enterText(find.byType(TextFormField).at(0), 'Leaking tap in library');
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(service.editedId, 'e1');
    expect(service.editedFields!['title'], 'Leaking tap in library');
    expect(service.editedFields!['location'], 'Library');
    expect(find.text('Report updated.'), findsOneWidget);
  });
}
