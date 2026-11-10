import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Small muted icon + caption row used for report and profile metadata.
class IconTextRow extends StatelessWidget {
  const IconTextRow({
    super.key,
    required this.icon,
    required this.text,
    this.maxLines = 2,
  });

  final IconData icon;
  final String text;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 14, color: AppColors.textHint),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption,
          ),
        ),
      ],
    );
  }
}
