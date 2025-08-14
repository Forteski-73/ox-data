// -----------------------------------------------------------
// app/core/utils/image_base.dart
// -----------------------------------------------------------
import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';

class ImageBase {
  static String _getContentType(String fileName) {
    if (fileName.endsWith('.png')) {
      return 'image/png';
    } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
      return 'image/jpeg';
    } else if (fileName.endsWith('.gif')) {
      return 'image/gif';
    }
    return 'application/octet-stream';
  }

  static Future<String?> decodeAndExtractSingleImage(String? imageZipBase64) async {
    if (imageZipBase64 == null || imageZipBase64.isEmpty) {
      if (kDebugMode) {
        print('imageZipBase64 é nulo ou vazio, não há imagem para decodificar.');
      }
      return null;
    }

    try {
      final Uint8List zipBytes = base64Decode(imageZipBase64);
      final Archive archive = ZipDecoder().decodeBytes(zipBytes);

      final file = archive.firstWhere((f) =>
          f.isFile &&
          (f.name.endsWith('.png') ||
              f.name.endsWith('.jpg') ||
              f.name.endsWith('.jpeg')));

      final Uint8List imageBytes = Uint8List.fromList(file.content as List<int>);
      final String base64Image = base64Encode(imageBytes);
      final String contentType = _getContentType(file.name);
      final String dataUri = 'data:$contentType;base64,$base64Image';
      return dataUri;
    } on FormatException catch (e) {
      if (kDebugMode) {
        print('Erro de formato ao decodificar Base64 ou ZIP: $e');
      }
      return null;
    } on StateError {
      if (kDebugMode) {
        print('Nenhuma imagem válida encontrada no ZIP.');
      }
      return null;
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Erro inesperado ao decodificar ou extrair imagem do ZIP: $e');
      }
      return null;
    }
  }
}