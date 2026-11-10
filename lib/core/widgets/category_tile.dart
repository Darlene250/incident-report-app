import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../theme/app_theme.dart';

/// Fixed 76 x 64 category selector. Selected state fills purple with white content.
class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.icon,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppSizes.categoryTileRadius);
    final Color foreground = isSelected ? Colors.white : AppColors.textSecondary;

    return SizedBox(
      height: AppSizes.categoryTileHeight,
      width: AppSizes.categoryTileWidth,
      child: Material(
        color: isSelected ? AppColors.primary : AppColors.card,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: isSelected ? null : Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: 20, color: foreground),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.tileLabel.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
