/*import 'package:flutter/widgets.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:oxdata/app/core/services/message_service.dart';

class EmailSenderUtility {

  static Future<bool> sendEmail({
    required BuildContext context,
    required List<String> recipients,
    required String subject,
    required String body,
    required List<String> attachmentPaths,
  }) async {
    
    try {

      final Email email = Email(
        recipients: recipients,
        subject: subject,
        body: body,
        attachmentPaths: attachmentPaths,
        isHTML: false,
      );

      // Envio do e-mail
      await FlutterEmailSender.send(email);

      MessageService.showSuccess('E-mail enviado com sucesso.');
      return true;

    } catch (error) {
      MessageService.showError('Erro ao enviar e-mail.');
      return false;
    }
  }
}
*/

import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';
import 'package:oxdata/app/core/services/message_service.dart';

class EmailSenderUtility {

  static Future<bool> sendEmail({
    required BuildContext context,
    required List<String> recipients,
    required String subject,
    required String body,
    required List<String> attachmentPaths,
  }) async {

    try {

      // Converte todos os paths em XFile
      final files = attachmentPaths.map(
        (path) => XFile(
          path,
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ).toList();

      await Share.shareXFiles(
        files,
        subject: subject,
        text: body,
      );

      MessageService.showSuccess('E-mail enviado com sucesso.');
      return true;

    } catch (error) {
      MessageService.showError('Erro ao enviar e-mail.');
      return false;
    }
  }
}

