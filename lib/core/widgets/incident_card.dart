import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../constants/incident_status.dart';
import '../theme/app_theme.dart';
import '../utils/time_ago.dart';
import 'incident_thumbnail.dart';
import 'status_chip.dart';

/// White card summarising a single report in a list.
class IncidentCard extends StatelessWidget {
  const IncidentCard({
    super.key,
    required this.title,
    required this.location,
    required this.time,
    required this.status,
    this.imageBytes,
    this.imageFuture,
    this.thumbnailIcon = Icons.report_gmailerrorred_rounded,
    this.metaIcon = Icons.schedule_rounded,
    this.onTap,
  });

  final String title;
  final String location;
  final DateTime time;
  final IncidentStatus status;

  /// Thumbnail source: bytes already in memory, or a photo loading from Firestore.
  final Uint8List? imageBytes;
  final Future<Uint8List?>? imageFuture;
  final IconData thumbnailIcon;

  /// Clock icon by default; pass a calendar icon for scheduled-style entries.
  final IconData metaIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppSizes.cardRadius);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: radius,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                IncidentThumbnail(
                  imageBytes: imageBytes,
                  imageFuture: imageFuture,
                  fallbackIcon: thumbnailIcon,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          StatusChip(status: status),
                          const SizedBox(width: 8),
                          Icon(metaIcon, size: 13, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              formatRelativeTime(time),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
