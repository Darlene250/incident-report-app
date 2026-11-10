import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/names.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/incident_card.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/summary_tile.dart';
import '../../core/widgets/user_avatar.dart';
import '../../models/app_user.dart';
import '../../models/incident.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../details/incident_details_screen.dart';
import 'widgets/home_hero_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onOpenReports,
    required this.onOpenProfile,
    required this.onReportPressed,
  });

  /// Switches to the Reports tab.
  final VoidCallback onOpenReports;

  /// Switches to the Profile tab (My Reports).
  final VoidCallback onOpenProfile;

  /// Opens the report form.
  final VoidCallback onReportPressed;

  static const int _recentCount = 3;

  @override
  Widget build(BuildContext context) {
    final AppUser? user = context.watch<AuthProvider>().currentUser;
    final IncidentProvider incidents = context.watch<IncidentProvider>();
    final bool isStaff = context.select<AuthProvider, bool>((AuthProvider auth) => auth.isStaff);

    // Staff see the newest reports from everyone; students see their own.
    final List<Incident> source =
        isStaff ? incidents.allIncidents : incidents.myIncidents;
    final List<Incident> recent = source.take(_recentCount).toList(growable: false);

    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.screenPadding,
            16,
            AppSizes.screenPadding,
            24,
          ),
          children: <Widget>[
            _GreetingRow(user: user),
            const SizedBox(height: 10),
            Text('Help make our campus safer.', style: AppTextStyles.cardTitle),
            const SizedBox(height: 4),
            Text(
              'Report issues and track their resolution.',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            HomeHeroCard(onReportPressed: onReportPressed),
            const SizedBox(height: 22),
            SectionHeader(title: 'Report Summary', onSeeAll: onOpenProfile),
            const SizedBox(height: 12),
            _SummaryRow(incidents: incidents),
            const SizedBox(height: 22),
            SectionHeader(title: 'Recent Reports', onSeeAll: onOpenReports),
            const SizedBox(height: 12),
            _RecentReports(
              incidents: incidents,
              recent: recent,
              isStaff: isStaff,
            ),
          ],
        ),
      ),
    );
  }
}

class _GreetingRow extends StatelessWidget {
  const _GreetingRow({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            'Hello, ${_firstName(user)} 👋',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.greeting,
          ),
        ),
        const SizedBox(width: 12),
        UserAvatar(name: user?.fullName ?? ''),
      ],
    );
  }

  static String _firstName(AppUser? user) {
    final String name = firstNameOf(user?.fullName ?? '');
    if (name.isNotEmpty) return name;

    final String email = user?.email ?? '';
    if (email.contains('@')) return email.split('@').first;

    return 'there';
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.incidents});

  final IncidentProvider incidents;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: SummaryTile(
              label: 'My Reports',
              count: incidents.myReportCount,
              icon: Icons.description_outlined,
              backgroundColor: AppColors.myReportsTile,
              iconColor: AppColors.myReportsIcon,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SummaryTile(
              label: 'In Progress',
              count: incidents.myInProgressCount,
              icon: Icons.hourglass_bottom_rounded,
              backgroundColor: AppColors.inProgressTile,
              iconColor: AppColors.inProgressIcon,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SummaryTile(
              label: 'Resolved',
              count: incidents.myResolvedCount,
              icon: Icons.check_circle_outline_rounded,
              backgroundColor: AppColors.resolvedTile,
              iconColor: AppColors.resolvedIcon,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SummaryTile(
              label: 'Submitted',
              count: incidents.mySubmittedCount,
              icon: Icons.send_outlined,
              backgroundColor: AppColors.submittedTile,
              iconColor: AppColors.submittedIcon,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentReports extends StatelessWidget {
  const _RecentReports({
    required this.incidents,
    required this.recent,
    required this.isStaff,
  });

  final IncidentProvider incidents;
  final List<Incident> recent;
  final bool isStaff;

  @override
  Widget build(BuildContext context) {
    if (incidents.isLoading) {
      return const SizedBox(height: 160, child: LoadingView(message: 'Loading reports…'));
    }

    final String? error = incidents.errorMessage;
    if (error != null && recent.isEmpty) {
      return SizedBox(
        height: 220,
        child: ErrorView(message: error, onRetry: incidents.refresh),
      );
    }

    if (recent.isEmpty) {
      return EmptyView(
        title: isStaff
            ? 'No reports have been submitted yet'
            : 'You have not reported anything yet',
        message: isStaff
            ? 'New student reports will appear here.'
            : 'Tap "Report an Issue" to create your first report.',
      );
    }

    return Column(
      children: <Widget>[
        for (final Incident incident in recent) ...<Widget>[
          IncidentCard(
            title: incident.title,
            location: incident.location,
            time: incident.createdAt,
            status: incident.status,
            imageFuture: incidents.photoFor(incident),
            thumbnailIcon: incident.category.icon,
            onTap: () => IncidentDetailsScreen.open(context, incident.id),
          ),
          if (incident != recent.last) const SizedBox(height: 12),
        ],
      ],
    );
  }
}


