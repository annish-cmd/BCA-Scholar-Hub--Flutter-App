import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ThumbnailImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool isDarkMode;

  const ThumbnailImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isNetworkImage = imageUrl.startsWith('http://') ||
                          imageUrl.startsWith('https://') ||
                          imageUrl.contains('supabase.co') ||
                          imageUrl.contains('://');

    Widget fallbackWidget = Container(
      height: height,
      width: width,
      color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
      child: Icon(
        Icons.picture_as_pdf,
        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        size: 40,
      ),
    );

    Widget imageWidget;

    if (isNetworkImage) {
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl,
        height: height,
        width: width,
        fit: fit,
        placeholder: (context, url) => Container(
          height: height,
          width: width,
          color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => fallbackWidget,
        memCacheWidth: width != null ? (width! * 2).toInt() : null,
        memCacheHeight: height != null ? (height! * 2).toInt() : null,
      );
    } else {
      imageWidget = Image.asset(
        'assets/images/$imageUrl',
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => fallbackWidget,
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
