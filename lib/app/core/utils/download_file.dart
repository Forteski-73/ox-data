import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart'; // Adicione no pubspec.yaml
import 'package:universal_html/html.dart' as html;

class DownloadFile {
  static Future<void> saveTxt(String content, String fileName) async {
    final bytes = utf8.encode(content);

    if (kIsWeb) {
      _downloadWeb(bytes, fileName);
    } else {
      await _downloadMobile(bytes, fileName);
    }
  }

  // 🌐 WEB (Estável e sem deprecated - Mantido como estava)
  static void _downloadWeb(List<int> bytes, String fileName) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  // 📱 MOBILE / DESKTOP (Refatorado)
  static Future<void> _downloadMobile(
    List<int> bytes,
    String fileName,
  ) async {
    // 1. Pegamos o diretório temporário para não ocupar espaço permanente do app
    final dir = await getTemporaryDirectory();
    final file = io.File('${dir.path}/$fileName');

    // 2. Escrevemos o arquivo
    await file.writeAsBytes(bytes, flush: true);

    // 3. Chamamos a interface nativa. O usuário pode escolher "Salvar nos Arquivos"
    // ou compartilhar no WhatsApp, Email, etc.
    final xFile = XFile(file.path, mimeType: 'text/plain');
    await Share.shareXFiles([xFile], subject: 'Download: $fileName');
  }
}