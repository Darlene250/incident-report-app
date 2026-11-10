import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/filter_chip_row.dart';
import '../../core/widgets/incident_card.dart';
import '../../core/widgets/loading_view.dart';
import '../../models/incident.dart';
import '../../providers/incident_provider.dart';
import '../details/incident_details_screen.dart';

/// Every campus report with search, status and category filters.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final IncidentProvider incidents = context.watch<IncidentProvider>();

    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(title: const Text('Reports')),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenPadding,
                8,
                AppSizes.screenPadding,
                14,
              ),
              child: AppTextField(
                hintText: 'Search reports',
                controller: _searchController,
                prefixIcon: Icons.search_rounded,
                textInputAction: TextInputAction.search,
                onChanged: incidents.setSearchQuery,
              ),
            ),
            FilterChipRow<IncidentStatus>(
              options: IncidentStatus.values,
              labelOf: (IncidentStatus status) => status.label,
              selected: incidents.statusFilter,
              onSelected: incidents.setStatusFilter,
            ),
            const SizedBox(height: 8),
            FilterChipRow<IncidentCategory>(
              options: IncidentCategory.values,
              labelOf: (IncidentCategory category) => category.label,
              selected: incidents.categoryFilter,
              onSelected: incidents.setCategoryFilter,
            ),
            const SizedBox(height: 8),
            Expanded(child: _ReportsList(incidents: incidents)),
          ],
        ),
      ),
    );
  }
}

class _ReportsList extends StatelessWidget {
  const _ReportsList({required this.incidents});

  final IncidentProvider incidents;

  @override
  Widget build(BuildContext context) {
    if (incidents.isLoading) {
      return const LoadingView(message: 'Loading reports…');
    }

    final String? error = incidents.errorMessage;
    if (error != null && incidents.filteredIncidents.isEmpty) {
      return ErrorView(message: error, onRetry: incidents.refresh);
    }

    final List<Incident> reports = incidents.filteredIncidents;
    if (reports.isEmpty) {
      return const EmptyView(
        title: 'No reports found',
        message: 'Try a different search or filter.',
        icon: Icons.search_off_rounded,
        boxed: false,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        4,
        AppSizes.screenPadding,
        24,
      ),
      itemCount: reports.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        final Incident incident = reports[index];

        return IncidentCard(
          title: incident.title,
          location: incident.location,
          time: incident.createdAt,
          status: incident.status,
          imageFuture: incidents.photoFor(incident),
          thumbnailIcon: incident.category.icon,
          onTap: () => IncidentDetailsScreen.open(context, incident.id),
        );
      },
    );
  }
}


