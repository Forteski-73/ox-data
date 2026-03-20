import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SearchImageDialog extends StatelessWidget {
  final Function(ImageSource) onSourceSelected;

  const SearchImageDialog({
    super.key,
    required this.onSourceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        elevation: 12,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- HEADER PADRÃO ---
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_a_photo_outlined,
                        color: Colors.indigo, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'ADICIONAR IMAGEM',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- BOTÃO CÂMERA ---
              _buildImageOption(
                icon: Icons.camera_alt_rounded,
                label: 'Tirar foto com a Câmera',
                onTap: () {
                  Navigator.pop(context);
                  onSourceSelected(ImageSource.camera);
                },
              ),
              const SizedBox(height: 12),

              // --- BOTÃO GALERIA ---
              _buildImageOption(
                icon: Icons.photo_library_rounded,
                label: 'Escolher da Galeria',
                onTap: () {
                  Navigator.pop(context);
                  onSourceSelected(ImageSource.gallery);
                },
              ),

              const SizedBox(height: 16),

              // --- BOTÃO CANCELAR ---
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "CANCELAR",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.indigo),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}