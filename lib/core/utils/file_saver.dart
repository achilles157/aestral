import 'dart:typed_data';
import 'file_saver_stub.dart'
    if (dart.library.html) 'file_saver_web.dart'
    if (dart.library.io) 'file_saver_desktop.dart';

Future<void> savePng(Uint8List bytes, String fileName) => savePngBytes(bytes, fileName);
