import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/utils/call_action.dart';
import 'package:oxdata/app/core/services/ftp_service.dart';
import 'package:oxdata/app/core/models/ftp_image_response.dart'; // Importe este modelo
import 'dart:io';
import 'dart:convert'; // Necessário para decodificar Base64

class ImagesPicker extends StatefulWidget {
  final List<String>? imagePaths;
  final Function(String newImagePath)? onImageAdded;
  final Function(String imagePath)? onImageRemoved;

  /// Altura de cada item. Se nulo, usa a altura máxima da tela.
  final double? itemHeight;

  /// Largura de cada item. Se nulo, usa a largura máxima da tela.
  final double? itemWidth;

  final double iconSize;

  const ImagesPicker({
    super.key,
    this.imagePaths,
    this.onImageAdded,
    this.onImageRemoved,
    this.itemHeight = 300,
    this.itemWidth = 300,
    this.iconSize = 28.0,
  });

  @override
  State<ImagesPicker> createState() => _ImagesPickerState();
}

class _ImagesPickerState extends State<ImagesPicker> {
  // 1. Estado para armazenar o Base64 das imagens.
  // Mapeia a URL (String) para a string Base64 (String).
  Map<String, String> _ftpImagesBase64 = {}; 
  bool _isLoadingFtpImages = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 2. Chamar o serviço para buscar as imagens FTP.
      await _fetchFtpImages();
    });
  }

  /// Busca as imagens via FTP/HTTP e armazena o Base64.
  Future<void> _fetchFtpImages() async {
    // 1. Garante que a lista não é nula, usando uma lista vazia se for.
    // Estes são todos os paths que serão enviados ao serviço de FTP.
    final List<String> allImagePaths = widget.imagePaths ?? [];

    if (allImagePaths.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoadingFtpImages = false;
        });
      }
      return;
    }

    // Opcional: Mostrar um loading global se necessário.
    final loadingService = context.read<LoadingService>();
    loadingService.show();

    try {
      final FtpService ftpService = context.read<FtpService>();
      
      // 2. Chama o serviço passando a lista completa (não nula).
      final response = await ftpService.fetchImagesBase64(allImagePaths);

      // Usa 'response.isSuccess' conforme o modelo de API assumido
      if (response.success && response.data != null) {
        final Map<String, String> fetchedImages = {};
        for (final FtpImageResponse imgResponse in response.data!) {
          // Garante que temos a URL e o Base64
          // Usando 'base64' conforme o modelo de API assumido
          if (imgResponse.url != null && imgResponse.base64Content != null) {
            fetchedImages[imgResponse.url!] = imgResponse.base64Content!;
          }
        }
        if (mounted) {
          setState(() {
            _ftpImagesBase64 = fetchedImages;
          });
        }
      } else {
        // Tratar erro (ex: exibir toast, logar, etc.)
        // print('Erro ao buscar imagens FTP: ${response.errorMessage}');
      }
    } catch (e) {
      // Tratar exceção
      // print('Exceção ao buscar imagens FTP: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFtpImages = false;
        });
      }
      loadingService.hide(); // Ocultar loading
    }
  }

  @override
  Widget build(BuildContext context) {
    // fallback para largura/altura máxima da tela
    final double height = widget.itemHeight ?? MediaQuery.of(context).size.height;
    final double width = widget.itemWidth ?? MediaQuery.of(context).size.width;

    // Se estiver carregando as imagens FTP, você pode mostrar um indicador
    if (_isLoadingFtpImages && (widget.imagePaths?.isNotEmpty ?? false)) {
      return SizedBox(
        height: height,
        width: width,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: (widget.imagePaths?.length ?? 0) + 1,
        itemBuilder: (context, index) {
          if (index == (widget.imagePaths?.length ?? 0)) {
            // Placeholder de adicionar
            return Container(
              width: width,
              height: height,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300, width: 1.0),
                borderRadius: BorderRadius.circular(4),
              ),
              child: GestureDetector(
                onTap: _showAddImageOptions,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Adicionar Foto', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            );
          }

          final imagePath = widget.imagePaths![index];
          return Container(
            width: width,
            height: height,
            margin: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                // Imagem
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 1.0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: _buildImageWidget(imagePath, height),
                  ),
                ),
                // Ícone de remoção
                Positioned(
                  top: 3,
                  left: 3,
                  child: GestureDetector(
                    onTap: () => widget.onImageRemoved?.call(imagePath),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.white70,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded, size: widget.iconSize, color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 3. Modificação para suportar Base64 (FTP)
  Widget _buildImageWidget(String imagePath, double height) {
    // 1. Tenta carregar a imagem em Base64, se disponível (Imagens FTP)
    if (_ftpImagesBase64.containsKey(imagePath)) {
      try {
        final bytes = base64Decode(_ftpImagesBase64[imagePath]!);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: height,
          // Placeholder enquanto a imagem é decodificada ou se falhar.
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.description, size: 80, color: Colors.grey),
        );
      } catch (e) {
        // Falha na decodificação do Base64
        return const Icon(Icons.broken_image, size: 80);
      }
    }
    
    // 2. Tenta carregar como imagem de rede padrão (HTTP/HTTPS)
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 80),
      );
    } 
    
    // 3. Tenta carregar como arquivo local (Imagens tiradas/escolhidas)
    else {
      // Verifica se o arquivo existe antes de tentar carregar para evitar exceções em caso de caminhos inválidos de FTP não carregados.
      if (File(imagePath).existsSync()) {
        return Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          width: double.infinity,
          height: height,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 80),
        );
      }
      
      // Se não for Base64 (FTP), nem HTTP, nem arquivo local existente (e não estiver carregando),
      // é um path inválido ou uma imagem FTP que falhou ao carregar e não é um arquivo local.
      return const Icon(Icons.description, size: 80, color: Colors.grey);
    }
  }

  Future<void> _showAddImageOptions() async {
    final loadingService = context.read<LoadingService>();
    await showDialog(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Adicionar Imagem'),
        children: [
          SimpleDialogOption(
            onPressed: () async {
              Navigator.pop(dialogContext);
              CallAction.run(
                action: () async {
                  loadingService.show();
                  final path = await _pickImage(ImageSource.camera);
                  if (path != null) widget.onImageAdded?.call(path);
                },
                onFinally: () => loadingService.hide(),
              );
            },
            child: const Text('Tirar foto com a Câmera'),
          ),
          SimpleDialogOption(
            onPressed: () async {
              Navigator.pop(dialogContext);
              CallAction.run(
                action: () async {
                  loadingService.show();
                  final path = await _pickImage(ImageSource.gallery);
                  if (path != null) widget.onImageAdded?.call(path);
                },
                onFinally: () => loadingService.hide(),
              );
            },
            child: const Text('Escolher da Galeria'),
          ),
        ],
      ),
    );
  }

  Future<String?> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    return picked?.path;
  }
}