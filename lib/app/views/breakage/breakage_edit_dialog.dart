import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oxdata/app/core/models/breakage_model.dart';

/// Alterações feitas no diálogo de edição (só os campos alterados vêm preenchidos).
class BreakageEditResult {
  final int? quantity;
  final Uint8List? photo;
  final String justification;

  BreakageEditResult({this.quantity, this.photo, required this.justification});
}

/// Abre o diálogo de edição de foto/quantidade com justificativa obrigatória.
/// [photoBuilder] desenha a foto atual; [onCapturePhoto] tira uma foto nova na hora.
Future<BreakageEditResult?> showBreakageEditDialog({
  required BuildContext context,
  required BreakageModel breakage,
  required String productName,
  required Widget Function(String url, double size) photoBuilder,
  required Future<Uint8List?> Function() onCapturePhoto,
}) {
  return showDialog<BreakageEditResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _BreakageEditDialog(
      breakage: breakage,
      productName: productName,
      photoBuilder: photoBuilder,
      onCapturePhoto: onCapturePhoto,
    ),
  );
}

class _BreakageEditDialog extends StatefulWidget {
  final BreakageModel breakage;
  final String productName;
  final Widget Function(String url, double size) photoBuilder;
  final Future<Uint8List?> Function() onCapturePhoto;

  const _BreakageEditDialog({
    required this.breakage,
    required this.productName,
    required this.photoBuilder,
    required this.onCapturePhoto,
  });

  @override
  State<_BreakageEditDialog> createState() => _BreakageEditDialogState();
}

class _BreakageEditDialogState extends State<_BreakageEditDialog> {
  static const int _minJustification = 10;
  static const Color _oxfordColor = Color(0xFF002B49);

  final TextEditingController _justificationController = TextEditingController();
  final NumberFormat _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  late int _quantidade = widget.breakage.quantity;
  Uint8List? _newPhoto;

  bool get _quantityChanged => _quantidade != widget.breakage.quantity;
  bool get _hasChanges => _quantityChanged || _newPhoto != null;
  bool get _justificationOk => _justificationController.text.trim().length >= _minJustification;

  @override
  void initState() {
    super.initState();
    _justificationController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _justificationController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    final bytes = await widget.onCapturePhoto();
    if (bytes != null && mounted) setState(() => _newPhoto = bytes);
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.breakage;
    final unitPrice = b.unitPrice;

    final canSave = _hasChanges && _justificationOk;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Row(
        children: [
          const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 28),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Editar registro #${b.breakageId}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.productName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text('Código: ${b.productId}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 12),

              // Foto
              const Text('FOTO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _newPhoto != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(_newPhoto!, width: 72, height: 72, fit: BoxFit.cover),
                        )
                      : widget.photoBuilder(b.photoUrl, 72),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _oxfordColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _capturePhoto,
                          icon: const Icon(Icons.camera_alt, size: 16),
                          label: Text(_newPhoto == null ? 'Tirar nova foto' : 'Tirar outra', style: const TextStyle(fontSize: 12)),
                        ),
                        if (_newPhoto != null)
                          TextButton(
                            onPressed: () => setState(() => _newPhoto = null),
                            child: const Text('Manter foto atual', style: TextStyle(fontSize: 11)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Quantidade
              const Text('QUANTIDADE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => setState(() => _quantidade = max(1, _quantidade - 1)),
                      icon: const Icon(Icons.remove_rounded, color: Colors.indigo),
                    ),
                    Text('$_quantidade', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    IconButton(
                      onPressed: () => setState(() => _quantidade++),
                      icon: const Icon(Icons.add_rounded, color: Colors.indigo),
                    ),
                  ],
                ),
              ),
              if (_quantityChanged)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Antes: ${b.quantity} un'
                    '${unitPrice == null ? '' : ' • Novo total: ${_currency.format(unitPrice * _quantidade)}'}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 12),

              // Justificativa
              const Text('JUSTIFICATIVA *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 6),
              TextField(
                controller: _justificationController,
                maxLines: 3,
                maxLength: 500,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Explique o motivo da alteração',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_justificationController.text.isNotEmpty && !_justificationOk)
                const Text(
                  'Mínimo de $_minJustification caracteres.',
                  style: TextStyle(fontSize: 11, color: Colors.red),
                ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.grey),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onPressed: canSave
              ? () => Navigator.pop(
                    context,
                    BreakageEditResult(
                      quantity: _quantityChanged ? _quantidade : null,
                      photo: _newPhoto,
                      justification: _justificationController.text.trim(),
                    ),
                  )
              : null,
          child: const Text('Salvar', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
