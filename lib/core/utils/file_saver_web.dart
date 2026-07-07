import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<void> savePngBytes(Uint8List bytes, String fileName) async {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'image/png'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..setAttribute('download', fileName)
    ..style.display = 'none';
  web.document.body?.append(anchor);
  anchor.click();
  web.document.body?.removeChild(anchor);
  web.URL.revokeObjectURL(url);
}
