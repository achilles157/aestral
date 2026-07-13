import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

/// Capture screenshot dari [controller] lalu share sebagai image.
/// Non-fatal — error di-catch secara graceful.
Future<void> shareCosmicImage({
  required BuildContext context,
  required ScreenshotController controller,
  required String shareText,
  String fileName = 'aestral_share.png',
}) async {
  try {
    final imageBytes = await controller.capture(pixelRatio: 2.0);
    if (imageBytes == null || !context.mounted) return;
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/$fileName';
    await File(path).writeAsBytes(imageBytes);
    await Share.shareXFiles(
      [XFile(path, mimeType: 'image/png')],
      text: shareText,
    );
  } catch (e) {
    debugPrint('shareCosmicImage error (non-fatal): $e');
  }
}
