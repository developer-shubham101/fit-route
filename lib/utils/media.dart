import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
// import 'package:video_thumbnail/video_thumbnail.dart';

const String kPlaceholderAsset = 'assets/images/workout_placeholder.png';

class _FitRouteCacheManager {
  static const key = 'fitrouteCache';
  static final instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 14),
      maxNrOfCacheObjects: 200,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}

class MediaUtil {
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (_) {
      return false;
    }
  }

  static bool isVideoUrl(String url) {
    final l = url.toLowerCase();
    return l.endsWith('.mp4') || l.endsWith('.webm') || l.contains('video');
  }

  static bool isImageUrl(String url) {
    final l = url.toLowerCase();
    return l.endsWith('.png') ||
        l.endsWith('.jpg') ||
        l.endsWith('.jpeg') ||
        l.endsWith('.gif') ||
        l.endsWith('.webp');
  }

  static Widget placeholderBox(
      {double? width, double? height, BorderRadius? radius}) {
    final image = Image.asset(kPlaceholderAsset,
        fit: BoxFit.cover, width: width, height: height);
    return radius != null
        ? ClipRRect(borderRadius: radius, child: image)
        : image;
  }

  static Widget cachedImage(String url,
      {BoxFit fit = BoxFit.cover,
      double? width,
      double? height,
      BorderRadius? radius}) {
    final image = CachedNetworkImage(
      cacheManager: _FitRouteCacheManager.instance,
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      placeholder: (_, __) =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      errorWidget: (_, __, ___) => Image.asset(kPlaceholderAsset,
          fit: fit, width: width, height: height),
    );
    return radius != null
        ? ClipRRect(borderRadius: radius, child: image)
        : image;
  }

  static Future<void> clearCache() async {
    try {
      await _FitRouteCacheManager.instance.emptyCache();
      // Also clear default image cache in memory
      imageCache.clear();
      imageCache.clearLiveImages();
    } catch (_) {
      // ignore
    }
  }

  static Future<ImageProvider?> generateVideoThumbnail(String url) async {
    /*if (kIsWeb) return null; // Not supported on web; avoid plugin call
    try {
      final bytes = await VideoThumbnail.thumbnailData(
        video: url,
        imageFormat: ImageFormat.PNG,
        maxWidth: 512,
        quality: 60,
      );
      if (bytes == null) return null;
      return MemoryImage(bytes);
    } catch (_) {
      return null;
    }*/
    return null;
  }
}
