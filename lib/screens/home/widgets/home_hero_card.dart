import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_theme.dart';
import 'campus_illustration.dart';

/// Purple gradient hero card with the campus illustration and the primary
/// "Report an Issue" action.
class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({super.key, required this.onReportPressed});

  final VoidCallback onReportPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 165),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppSizes.heroRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('See an issue on campus?', style: AppTextStyles.heroTitle),
                      const SizedBox(height: 6),
                      Text(
                        'Report it and help improve our learning environment.',
                        style: AppTextStyles.heroBody,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const CampusIllustration(),
              ],
            ),
            const SizedBox(height: 12),
            _ReportPillButton(onPressed: onReportPressed),
          ],
        ),
      ),
    );
  }
}

class _ReportPillButton extends StatelessWidget {
  const _ReportPillButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppSizes.buttonRadius);

    return SizedBox(
      height: 48,
      width: double.infinity,
      child: Material(
        color: Colors.white,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: <Widget>[
                Container(
                  height: 28,
                  width: 28,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Report an Issue',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardTitle.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.primary),
                const SizedBox(width: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
