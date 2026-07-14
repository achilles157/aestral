import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

/// Capture screenshot dari [controller] lalu share.
/// - Web: text-only share (Web Share API Level 2 / file tidak tersedia universal)
/// - Mobile/Desktop: share sebagai PNG image
Future<void> shareCosmicImage({
  required BuildContext context,
  required ScreenshotController controller,
  required String shareText,
  String fileName = 'aestral_share.png',
}) async {
  try {
    if (kIsWeb) {
      // Flutter Web: share_plus tidak support shareFiles — gunakan text share
      await Share.share(shareText);
      return;
    }

    final imageBytes = await controller.capture(pixelRatio: 2.0);
    if (imageBytes == null || !context.mounted) {
      await Share.share(shareText);
      return;
    }

    // Mobile / Desktop: tulis ke temp file lalu share sebagai image
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(imageBytes);
    await Share.shareXFiles([
      XFile(file.path, mimeType: 'image/png'),
    ], text: shareText);
  } catch (e) {
    debugPrint('shareCosmicImage error: $e');
    if (context.mounted) {
      try {
        await Share.share(shareText);
      } catch (_) {}
    }
  }
}
