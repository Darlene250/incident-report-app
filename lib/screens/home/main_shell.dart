import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../report_form/report_form_screen.dart';
import '../profile/profile_screen.dart';
import '../reports/reports_screen.dart';
import 'home_screen.dart';
import 'widgets/app_bottom_bar.dart';

/// Signed-in shell: Home, Reports and Profile tabs plus the raised "+" action.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tabIndex = 0;

  void _selectTab(int index) {
    if (_tabIndex == index) return;
    setState(() => _tabIndex = index);
  }

  void _openReportForm() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const ReportFormScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: IndexedStack(
        index: _tabIndex,
        children: <Widget>[
          HomeScreen(
            onOpenReports: () => _selectTab(1),
            onOpenProfile: () => _selectTab(2),
            onReportPressed: _openReportForm,
          ),
          const ReportsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomBar(
        currentIndex: _tabIndex,
        onDestinationSelected: _selectTab,
        onAddPressed: _openReportForm,
      ),
    );
  }
}
