// -----------------------------------------------------------
// app/core/services/call_action.dart
// -----------------------------------------------------------
import 'package:oxdata/app/core/services/message_service.dart';

class CallAction {
  static Future<T?> run<T>({
    required Future<T> Function() action,
    Function(Exception e)? onError,
    Function()? onFinally,
  }) async {
    try {
      return await action();
    } catch (e) {
      if (e is Exception) {
        if (onError != null) {
          onError(e); // Tratamento para erro personalizado.
        } else {
          // Tratamento padrão (fallback)
          MessageService.showError(e.toString());
        }
      } else {
        // Caso seja um erro mais grave (Error, não Exception)
        MessageService.showError('Erro inesperado: $e');
      }
      return null;
    } finally {
      onFinally?.call();
    }
  }
}
