import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class AssetFileCache {
  static final Map<String, Future<String>> _inflight = {};

  /// Ensures the given [assetPath] is available as a local file on disk and
  /// returns the absolute file path.
  ///
  /// This is needed because `model_viewer_plus` expects a URL/file path, not an
  /// AssetBundle reference.
  static Future<String> ensureOnDisk(String assetPath) {
    return _inflight.putIfAbsent(assetPath, () async {
      if (kIsWeb) {
        throw UnsupportedError('AssetFileCache is not supported on web');
      }

      final bytes = await rootBundle.load(assetPath);
      final data = bytes.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final safeName = assetPath
          .replaceAll('assets/', '')
          .replaceAll('/', '_')
          .replaceAll('..', '_');
      final file = File('${dir.path}/avatar_asset_cache_$safeName');

      if (await file.exists()) {
        final len = await file.length();
        if (len == data.length) return file.path;
      }

      await file.writeAsBytes(data, flush: true);
      return file.path;
    });
  }
}
