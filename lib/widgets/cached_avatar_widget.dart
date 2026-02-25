import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Cache'lenmiş avatar widget'ı
/// Network görsellerini cache'leyerek performansı artırır
/// ✅ Otomatik cache yönetimi
/// ✅ Hata durumunda fallback gösterimi
/// ✅ Placeholder desteği
class CachedAvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Color? backgroundColor;
  final IconData? defaultIcon;
  final Color? iconColor;
  final String? userName; // Avatar oluşturmak için kullanıcı adı
  final BoxFit fit;

  const CachedAvatarWidget({
    super.key,
    this.imageUrl,
    this.radius = 30,
    this.backgroundColor,
    this.defaultIcon,
    this.iconColor,
    this.userName,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    // Eğer imageUrl yoksa veya boşsa varsayılan avatar göster
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildDefaultAvatar(context);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey.shade200,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey.shade200,
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.grey.shade400,
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => _buildDefaultAvatar(context),
      fit: fit,
      // Cache ayarları
      memCacheWidth: (radius * 2).toInt(),
      memCacheHeight: (radius * 2).toInt(),
      maxWidthDiskCache: (radius * 2 * 2).toInt(), // Retina için 2x
      maxHeightDiskCache: (radius * 2 * 2).toInt(),
    );
  }

  Widget _buildDefaultAvatar(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.grey.shade200,
      child: defaultIcon != null
          ? Icon(
              defaultIcon,
              size: radius,
              color: iconColor ?? Colors.grey.shade600,
            )
          : userName != null && userName!.isNotEmpty
              ? Text(
                  userName!.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontSize: radius * 0.6,
                    fontWeight: FontWeight.bold,
                    color: iconColor ?? Colors.grey.shade600,
                  ),
                )
              : Icon(
                  Icons.person,
                  size: radius,
                  color: iconColor ?? Colors.grey.shade600,
                ),
    );
  }
}

/// Cache'lenmiş network görsel widget'ı
/// Büyük görseller için optimize edilmiş
class CachedNetworkImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const CachedNetworkImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ??
          Container(
            width: width,
            height: height,
            color: Colors.grey.shade200,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.grey.shade400,
                ),
              ),
            ),
          ),
      errorWidget: (context, url, error) => errorWidget ??
          Container(
            width: width,
            height: height,
            color: Colors.grey.shade200,
            child: Icon(
              Icons.error_outline,
              color: Colors.grey.shade400,
              size: 40,
            ),
          ),
      // Performans optimizasyonları
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}

