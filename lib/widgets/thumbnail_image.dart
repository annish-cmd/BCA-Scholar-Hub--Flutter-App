import 'package:flutter/material.dart';

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

    // Default fallback widget
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
      // Handle network images
      imageWidget = Image.network(
        imageUrl,
        height: height,
        width: width,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: height,
            width: width,
            color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => fallbackWidget,
      );
    } else {
      // Handle asset images
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
