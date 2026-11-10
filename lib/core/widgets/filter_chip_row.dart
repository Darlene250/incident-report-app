import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../theme/app_theme.dart';

/// One horizontally scrollable row of single-select filter chips with a leading
/// "All" option (selected value `null`).
class FilterChipRow<T> extends StatelessWidget {
  const FilterChipRow({
    super.key,
    required this.options,
    required this.labelOf,
    required this.selected,
    required this.onSelected,
    this.allLabel = 'All',
    this.padding = const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
  });

  final List<T> options;
  final String Function(T option) labelOf;

  /// Null means the "All" chip is selected.
  final T? selected;
  final ValueChanged<T?> onSelected;
  final String allLabel;

  /// Horizontal inset of the scrolling row; pass [EdgeInsets.zero] when the
  /// parent already applies the screen padding.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        children: <Widget>[
          _FilterChip(
            label: allLabel,
            isSelected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final T option in options) ...<Widget>[
            const SizedBox(width: 8),
            _FilterChip(
              label: labelOf(option),
              isSelected: selected == option,
              onTap: () => onSelected(option),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppSizes.chipRadius);
    final Color foreground = isSelected ? Colors.white : AppColors.textSecondary;

    return Material(
      color: isSelected ? AppColors.primary : AppColors.filterChip,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.chip.copyWith(color: foreground),
            ),
          ),
        ),
      ),
    );
  }
}
