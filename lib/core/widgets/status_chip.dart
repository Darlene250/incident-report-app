import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../constants/incident_status.dart';
import '../theme/app_theme.dart';

/// Compact coloured pill for an incident status.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final IncidentStatus status;

  @override
  Widget build(BuildContext context) {
    final ({Color background, Color text}) colors = switch (status) {
      IncidentStatus.submitted => (
          background: AppColors.submittedChipBackground,
        text: AppColors.statusColor(status),
        ),
      IncidentStatus.inProgress => (
          background: AppColors.inProgressChipBackground,
        text: AppColors.statusColor(status),
        ),
      IncidentStatus.resolved => (
          background: AppColors.resolvedChipBackground,
        text: AppColors.statusColor(status),
        ),
    };

    return Container(
      padding: AppSizes.chipPadding,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppSizes.chipRadius),
      ),
      child: Text(
        status.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.chip.copyWith(color: colors.text),
      ),
    );
  }
}
