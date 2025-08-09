import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img;

Future<String> optimizeImage(File file) async {
  final bytes = await file.readAsBytes();
  final original = img.decodeImage(bytes);
  if (original == null) throw Exception('Unable to decode image');
  final resized = img.copyResize(original, width: 1024, height: 1024, interpolation: img.Interpolation.average, maintainAspect: true);
  final jpg = img.encodeJpg(resized, quality: 80);
  return base64Encode(jpg);
}
