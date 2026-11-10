import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../theme/app_theme.dart';

/// Rounded incident photo with an icon placeholder when there is no image,
/// while it loads, or when it fails to load.
class IncidentThumbnail extends StatelessWidget {
  const IncidentThumbnail({
    super.key,
    required this.fallbackIcon,
    this.imageBytes,
    this.imageFuture,
    this.size = AppSizes.thumbnailSize,
  });

  final IconData fallbackIcon;

  /// Bytes already in memory, e.g. a freshly picked photo.
  final Uint8List? imageBytes;

  /// Photo loaded from Firestore. Used when [imageBytes] is null.
  final Future<Uint8List?>? imageFuture;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Widget placeholder = Container(
      color: AppColors.myReportsTile,
      child: Icon(fallbackIcon, size: size * 0.39, color: AppColors.primary),
    );

    final Widget image;
    if (imageBytes != null) {
      image = _memoryImage(imageBytes!, placeholder);
    } else if (imageFuture != null) {
      image = FutureBuilder<Uint8List?>(
        future: imageFuture,
        builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
          final Uint8List? bytes = snapshot.data;
          return bytes == null ? placeholder : _memoryImage(bytes, placeholder);
        },
      );
    } else {
      image = placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.thumbnailRadius),
      child: SizedBox(height: size, width: size, child: image),
    );
  }

  static Widget _memoryImage(Uint8List bytes, Widget placeholder) {
    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}
