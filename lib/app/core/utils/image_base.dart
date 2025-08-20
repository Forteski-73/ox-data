// -----------------------------------------------------------
// app/core/utils/image_base.dart
// -----------------------------------------------------------
import 'dart:convert';
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
      throw Exception('O arquivo da imagem está corrompido ou não existe.');
    }

    try {
      
      final Uint8List zipBytes = base64Decode(imageZipBase64);
      final Archive archive = ZipDecoder().decodeBytes(zipBytes);

      final file = archive.firstWhere((f) =>
          f.isFile &&
          ( f.name.endsWith('.png') ||
            f.name.endsWith('.jpg') ||
            f.name.endsWith('.jpeg')
          ));

      final Uint8List imageBytes = Uint8List.fromList(file.content as List<int>);
      final String base64Image = base64Encode(imageBytes);
      final String contentType = _getContentType(file.name);
      final String dataUri = 'data:$contentType;base64,$base64Image';
      return dataUri;

    } on FormatException catch (e) {
        throw Exception('Erro de formato ao decodificar a imagem: $e');
    } on StateError {
        throw Exception('Nenhuma imagem válida encontrada.');
    } on Exception catch (e) {
        throw Exception('Erro inesperado ao processar a imagem: $e');
    }
  }

}