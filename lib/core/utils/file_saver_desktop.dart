import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

Future<void> savePngBytes(Uint8List bytes, String fileName) async {
  final Directory? downloadsDir = await getDownloadsDirectory();
  if (downloadsDir != null) {
    final String filePath = '${downloadsDir.path}/$fileName';
    final File file = File(filePath);
    await file.writeAsBytes(bytes);
  } else {
    final Directory docDir = await getApplicationDocumentsDirectory();
    final String filePath = '${docDir.path}/$fileName';
    final File file = File(filePath);
    await file.writeAsBytes(bytes);
  }
}
