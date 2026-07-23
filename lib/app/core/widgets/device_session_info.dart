// -----------------------------------------------------------
// app/core/widgets/device_session_info.dart
// -----------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Abre um diálogo mostrando o usuário logado, o token de autenticação
/// e o Device GUID, com botão de copiar em cada campo.
///
/// Exemplo de uso:
/// ```dart
/// showDeviceSessionInfoDialog(
///   context,
///   userName: 'Fulano de Tal',
///   authToken: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
///   deviceGuid: '458f56d8f-84f5d4-d8f74d65-de222',
/// );
/// ```
void showDeviceSessionInfoDialog(
  BuildContext context, {
  required String userName,
  required String authToken,
  required String deviceGuid,
}) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.85),
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.cyanAccent.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.badge_outlined,
                color: Colors.cyanAccent,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'SESSÃO ATUAL',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CopyableInfoRow(
              label: 'USUÁRIO',
              value: userName,
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 14),
            _CopyableInfoRow(
              label: 'TOKEN',
              value: authToken,
              icon: Icons.vpn_key_rounded,
              maxLines: 1,
            ),
            const SizedBox(height: 14),
            _CopyableInfoRow(
              label: 'DEVICE GUID',
              value: deviceGuid,
              icon: Icons.smartphone_rounded,
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            child: const Text(
              'FECHAR',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      );
    },
  );
}

// ─────────────────────────────────────────────────────────────────
// LINHA COPIÁVEL (uso interno deste arquivo)
// ─────────────────────────────────────────────────────────────────

class _CopyableInfoRow extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final int maxLines;

  const _CopyableInfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  State<_CopyableInfoRow> createState() => _CopyableInfoRowState();
}

class _CopyableInfoRowState extends State<_CopyableInfoRow> {
  bool _copied = false;

  Future<void> _copy() async {
    // Sempre copia o valor completo (widget.value), independente
    // de quantas linhas estão sendo exibidas na tela.
    await Clipboard.setData(ClipboardData(text: widget.value));
    if (!mounted) return;
    setState(() => _copied = true);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(widget.icon, color: Colors.white38, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: Colors.white38,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: widget.maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _copy,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _copied ? Icons.check_circle_rounded : Icons.copy_rounded,
                key: ValueKey(_copied),
                color: _copied ? Colors.greenAccent : Colors.cyanAccent,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}