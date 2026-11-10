import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/filter_chip_row.dart';
import '../../core/widgets/icon_text_row.dart';
import '../../core/widgets/incident_card.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/summary_tile.dart';
import '../../core/widgets/user_avatar.dart';
import '../../models/app_user.dart';
import '../../models/incident.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../details/incident_details_screen.dart';

/// The signed-in user's profile and own reports ("My Reports").
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Local to this tab so it does not disturb the Reports tab filters.
  IncidentStatus? _statusFilter;

  Future<void> _confirmSignOut() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to report an issue.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final AuthProvider auth = context.read<AuthProvider>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    await auth.signOut();
    if (!mounted) return;

    final String? error = auth.errorMessage;
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error), backgroundColor: AppColors.error));
      auth.clearError();
    }
  }

  List<Incident> _visibleReports(IncidentProvider incidents) {
    if (_statusFilter == null) return incidents.myIncidents;

    return incidents.myIncidents
        .where((Incident incident) => incident.status == _statusFilter)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final AppUser? user = context.watch<AuthProvider>().currentUser;
    final IncidentProvider incidents = context.watch<IncidentProvider>();
    final List<Incident> reports = _visibleReports(incidents);

    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        title: const Text('My Reports'),
        actions: <Widget>[
          IconButton(
            onPressed: _confirmSignOut,
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.screenPadding,
            8,
            AppSizes.screenPadding,
            24,
          ),
          children: <Widget>[
            _ProfileCard(user: user),
            const SizedBox(height: 18),
            _StatsRow(incidents: incidents),
            const SizedBox(height: 18),
            FilterChipRow<IncidentStatus>(
              options: IncidentStatus.values,
              labelOf: (IncidentStatus status) => status.label,
              selected: _statusFilter,
              onSelected: (IncidentStatus? status) =>
                  setState(() => _statusFilter = status),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 14),
            if (incidents.isLoadingMyReports)
              const SizedBox(height: 160, child: LoadingView(message: 'Loading your reports…'))
            else if (incidents.errorMessage != null && reports.isEmpty)
              SizedBox(
                height: 260,
                child: ErrorView(
                  message: incidents.errorMessage!,
                  onRetry: incidents.refresh,
                ),
              )
            else if (reports.isEmpty)
              EmptyView(
                title: _statusFilter == null
                    ? 'You have not reported anything yet'
                    : 'No reports found',
                message: _statusFilter == null
                    ? 'Reports you submit will appear here.'
                    : 'Try a different status filter.',
              )
            else
              for (int i = 0; i < reports.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(height: 12),
                IncidentCard(
                  title: reports[i].title,
                  location: reports[i].location,
                  time: reports[i].createdAt,
                  status: reports[i].status,
                  imageFuture: incidents.photoFor(reports[i]),
                  thumbnailIcon: reports[i].category.icon,
                  onTap: () => IncidentDetailsScreen.open(context, reports[i].id),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final String fullName = user?.fullName.trim() ?? '';
    final String department = user?.department.trim() ?? '';
    final String location = user?.location.trim() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              UserAvatar(name: fullName, size: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      fullName.isEmpty ? 'Campus user' : fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle,
                    ),
                    const SizedBox(height: 6),
                    _RoleChip(role: user?.role),
                  ],
                ),
              ),
            ],
          ),
          if (department.isNotEmpty || location.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            if (department.isNotEmpty)
              IconTextRow(icon: Icons.menu_book_outlined, text: department),
            if (department.isNotEmpty && location.isNotEmpty) const SizedBox(height: 8),
            if (location.isNotEmpty)
              IconTextRow(icon: Icons.location_on_outlined, text: location),
          ],
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});

  final UserRole? role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSizes.chipPadding,
      decoration: BoxDecoration(
        color: AppColors.filterChip,
        borderRadius: BorderRadius.circular(AppSizes.chipRadius),
      ),
      child: Text(
        role?.label ?? 'Student',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.chip.copyWith(color: AppColors.primary),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.incidents});

  final IncidentProvider incidents;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: SummaryTile(
              label: 'Total Reports',
              count: incidents.myReportCount,
              icon: Icons.description_outlined,
              backgroundColor: AppColors.myReportsTile,
              iconColor: AppColors.myReportsIcon,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SummaryTile(
              label: 'In Progress',
              count: incidents.myInProgressCount,
              icon: Icons.hourglass_bottom_rounded,
              backgroundColor: AppColors.inProgressTile,
              iconColor: AppColors.inProgressIcon,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SummaryTile(
              label: 'Resolved',
              count: incidents.myResolvedCount,
              icon: Icons.check_circle_outline_rounded,
              backgroundColor: AppColors.resolvedTile,
              iconColor: AppColors.resolvedIcon,
            ),
          ),
        ],
      ),
    );
  }
}
