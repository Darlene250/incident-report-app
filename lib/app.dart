import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/responsive_shell.dart';
import 'providers/auth_provider.dart';
import 'providers/incident_provider.dart';
import 'screens/auth/auth_gate.dart';

class CampusIncidentApp extends StatelessWidget {
  const CampusIncidentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        // Re-points the incident streams at whoever is signed in.
        ChangeNotifierProxyProvider<AuthProvider, IncidentProvider>(
          create: (_) => IncidentProvider(),
          update: (_, AuthProvider auth, IncidentProvider? incidents) =>
              (incidents ?? IncidentProvider())..updateUser(auth.currentUser),
        ),
      ],
      child: MaterialApp(
        title: 'Campus Incident Reporting',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        // Keeps the app at phone width and centres it on wide (web) screens.
        builder: (BuildContext context, Widget? child) =>
            ResponsiveShell(child: child ?? const SizedBox.shrink()),
        home: const AuthGate(),
      ),
    );
  }
}
