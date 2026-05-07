import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A widget for displaying profile images with caching
class CachedProfileImage extends StatelessWidget {

  const CachedProfileImage({
    super.key,
    this.imageUrl,
    this.size = 48.0,
    this.placeholderIcon = Icons.person,
    this.backgroundColor,
    this.iconColor,
  });
  final String? imageUrl;
  final double size;
  final IconData placeholderIcon;
  final Color? backgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Theme.of(context).colorScheme.surface;
    final icColor = iconColor ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: bgColor,
        child: Icon(
          placeholderIcon,
          size: size * 0.5,
          color: icColor,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: size / 2,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: size / 2,
        backgroundColor: bgColor,
        child: SizedBox(
          width: size * 0.4,
          height: size * 0.4,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(icColor),
          ),
        ),
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: size / 2,
        backgroundColor: bgColor,
        child: Icon(
          placeholderIcon,
          size: size * 0.5,
          color: icColor,
        ),
      ),
    );
  }
}

/// A widget for displaying square cached images (e.g., case images, documents)
class CachedSquareImage extends StatelessWidget {

  const CachedSquareImage({
    super.key,
    required this.imageUrl,
    this.width = 100.0,
    this.height = 100.0,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });
  final String? imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: borderRadius,
        ),
        child: errorWidget ??
            Icon(
              Icons.image_not_supported,
              size: width * 0.4,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) =>
            placeholder ??
            Container(
              width: width,
              height: height,
              color: Theme.of(context).colorScheme.surface,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        errorWidget: (context, url, error) =>
            errorWidget ??
            Container(
              width: width,
              height: height,
              color: Theme.of(context).colorScheme.surface,
              child: Icon(
                Icons.broken_image,
                size: width * 0.4,
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.6),
              ),
            ),
      ),
    );
  }
}

/// A widget for displaying thumbnails with caching
class CachedThumbnail extends StatelessWidget {

  const CachedThumbnail({
    super.key,
    required this.imageUrl,
    this.size = 60.0,
    this.defaultIcon = Icons.image,
    this.backgroundColor,
    this.onTap,
  });
  final String? imageUrl;
  final double size;
  final IconData defaultIcon;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerHighest;

    final Widget imageWidget = CachedSquareImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(8),
      placeholder: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          defaultIcon,
          size: size * 0.5,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}

/// Extension to get full image URLs from relative paths
extension ImageUrlBuilder on String {
  /// Converts a relative path to a full URL
  String toImageUrl(String baseUrl) {
    if (isEmpty) return '';
    if (startsWith('http://') || startsWith('https://')) {
      return this;
    }
    // Remove leading slash if present
    final path = startsWith('/') ? substring(1) : this;
    // Remove trailing slash from baseUrl if present
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return '$base/$path';
  }
}
