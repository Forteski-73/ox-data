import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/utils/call_action.dart';
import 'package:oxdata/app/core/services/ftp_service.dart';
import 'package:oxdata/app/core/services/pallet_service.dart';
import 'package:oxdata/app/core/models/ftp_image_response.dart';
import 'package:oxdata/app/core/services/image_cache_service.dart';
import 'package:oxdata/app/views/pages/full_screen_image_dialog.dart'; 
import 'dart:io';
import 'dart:convert'; 

class ImagesPicker extends StatefulWidget {
  final List<String>? imagePaths;
  
  // O nome base a ser usado para gerar os caminhos sequenciais das novas imagens.
  final String baseImagePath;
  final int? codePallet;

  final Function(String imagePath)? onImageRemoved;
  final Function(List<String> newPaths)? onImagesChanged;

  /// Altura de cada item. Se nulo, usa a altura máxima da tela.
  final double? itemHeight;

  /// Largura de cada item. Se nulo, usa a largura máxima da tela.
  final double? itemWidth;

  final double iconSize;

  const ImagesPicker({
    super.key,
    this.imagePaths,
    required this.baseImagePath,
    this.codePallet, 
    this.onImageRemoved,
    this.onImagesChanged,
    this.itemHeight = 300,
    this.itemWidth = 300,
    this.iconSize = 28.0,
  });

  @override
  State<ImagesPicker> createState() => _ImagesPickerState();
}

class _ImagesPickerState extends State<ImagesPicker> {
  // O mapa local é mantido apenas para armazenar o Base64 temporário durante o INIT
  // e é sincronizado com o Provider.
  Map<String, String> _allImagesBase64 = {}; 
  //bool _isLoadingFtpImages = true;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {

      final imageCacheService = context.read<ImageCacheService>();
      imageCacheService.clearAllImages();

      // Usamos a lista inicial (widget.imagePaths) para buscar as imagens FTP.
      final initialPaths = widget.imagePaths ?? [];
      
      // 1. Busca os paths do Pallet
      final palletService = context.read<PalletService>();
      if (widget.codePallet != null)
      {
        final images = await palletService.getPalletImages(widget.codePallet!);
        if (mounted) {
          
          final List<String> imagePathsFromApi = images
              .map<String>((img) => img['imagePath'] as String)
              .toList();

          // 2. Define a lista de paths para buscar (paths da API têm prioridade)
          final List<String> pathsToFetch = imagePathsFromApi.isEmpty 
              ? initialPaths 
              : imagePathsFromApi;
          
          // 3. Busca o conteúdo Base64 via FTP/HTTP
          await _fetchFtpImages(pathsToFetch); 
        }
      }
      else
      {
        //_isLoadingFtpImages = false;
      }
    });
    
  }

  /// Busca as imagens via FTP/HTTP e armazena o Base64.
  Future<void> _fetchFtpImages(List<String> images) async {
    final List<String> ftpImagePaths = images
      .where((path) => path.startsWith('http') || path.contains('/'))
      .toList();

    if (ftpImagePaths.isEmpty) {
      /*if (mounted) {
        setState(() {
          _isLoadingFtpImages = false;
        });
      }*/
      return;
    }

    final loadingService = context.read<LoadingService>();
    final imageCacheService = context.read<ImageCacheService>();
    loadingService.show();

    try {
      final FtpService ftpService = context.read<FtpService>();
      
      final response = await ftpService.fetchImagesBase64(ftpImagePaths);

      if (response.success && response.data != null) {
        final Map<String, String> fetchedImages = {};
        for (final FtpImageResponse imgResponse in response.data!) {
          if (imgResponse.url!.isNotEmpty && imgResponse.base64Content!.isNotEmpty) {
            fetchedImages[imgResponse.url!] = imgResponse.base64Content!;
          }
        }
        if (mounted) {
          setState(() {
            _allImagesBase64.addAll(fetchedImages);
          });
          
          // CRÍTICO: Sincroniza o mapa de imagens FTP e o cache no Provider após o fetch
          imageCacheService.setCacheFromMap(_allImagesBase64);
        }
      } 
    } catch (e) {
      // Tratar exceção
    } finally {
      /*if (mounted) {
        setState(() {
          _isLoadingFtpImages = false;
        });
      }*/
      loadingService.hide();
    }
  }

  void _openFullScreenImage(String base64Image) {
    // É uma boa prática verificar se a string Base64 está vazia antes de navegar.
    if (base64Image.isEmpty) return;

    Navigator.push(
      context,
      PageRouteBuilder(
        // Transição sem animação para parecer um "pop-up" instantâneo
        pageBuilder: (context, animation, secondaryAnimation) => 
            FullScreenImageDialog(base64Image: base64Image),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        fullscreenDialog: true, // Indica que é um diálogo de tela cheia (opcional)
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. WATCH: Assiste ao serviço de cache para obter a lista ATUALIZADA
    final imageCacheService = context.watch<ImageCacheService>();
    final List<String> currentImagePaths = imageCacheService.imagePaths;
    
    // Mapeia o Base64 atual do Provider para uso no _buildImageWidget
    final Map<String, String> currentImagesBase64 = {
        for (var img in imageCacheService.cachedImages) img.url!: img.base64Content!,
    };

    final double height = widget.itemHeight ?? MediaQuery.of(context).size.height;
    final double width  = widget.itemWidth ?? MediaQuery.of(context).size.width;
    
    final bool canAddImage  = widget.baseImagePath.isNotEmpty;
    final Color iconColor   = canAddImage ? Colors.grey : Colors.grey.shade400;
    final Color borderColor = canAddImage ? Colors.grey.shade300 : Colors.red.shade200;
    final String message    = canAddImage ? 'Adicionar Foto' : 'Base path ausente';

    // ListView usa a lista do Provider
    final int imageCount = currentImagePaths.length;

    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imageCount + 1,
        itemBuilder: (context, index) {
          if (index == imageCount) {
            // Placeholder de adicionar
            return Container(
              width: width,
              height: height,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: borderColor, width: 1.0),
                borderRadius: BorderRadius.circular(4),
              ),
              child: GestureDetector(
                onTap: canAddImage ? _showAddImageOptions : () {
                  // Mensagem de base path ausente
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, size: 40, color: iconColor),
                    const SizedBox(height: 8),
                    Text(message, style: TextStyle(color: iconColor)),
                  ],
                ),
              ),
            );
          }

          // ⭐️ 3. ITEM: O item é pego da lista ATUALIZADA do Provider
          final imagePath = currentImagePaths[index];
          final base64Image = currentImagesBase64[imagePath]; 
          return Container(
            width: width,
            height: height,
            margin: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                // Imagem
                GestureDetector(
                // ⭐️ Implementação do onDoubleTap
                onDoubleTap: base64Image != null && base64Image.isNotEmpty
                    ? () => _openFullScreenImage(base64Image)
                    : null,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      border: base64Image == null || base64Image.isEmpty
                          ? Border.all(color: Colors.grey, width: 1.0)
                          : null,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: _buildImageWidget(imagePath, height, currentImagesBase64),
                    ),
                  ),
                ),
                // Ícone de remoção
                Positioned(
                  top: 3,
                  left: 3,
                  child: GestureDetector(
                    // onImageRemoved deve acionar o ImageCacheService.removeImageByPath no widget pai
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

  // ⭐️ MODIFICADO: Aceita o mapa de Base64 atualizado do build
  Widget _buildImageWidget(String imagePath, double height, Map<String, String> allImagesBase64) {
    // 1. Tenta carregar a imagem em Base64 (Imagens Base64 de novas fotos ou FTP)
    if (allImagesBase64.containsKey(imagePath)) {
      try {
        final bytes = base64Decode(allImagesBase64[imagePath]!);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: height,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.description, size: 80, color: Colors.grey),
        );
      } catch (e) {
        return const Icon(Icons.broken_image, size: 80);
      }
    }
    
    // 2. Tenta carregar como imagem de rede padrão (FTP/HTTP)
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
    
    // 3. Tratar como placeholder
    else {
      return const Icon(Icons.description, size: 80, color: Colors.grey);
    }
  }

  // Lógica para adicionar e reordenar novas imagens
  Future<void> _processNewImage(String? path) async {
    if (path == null || widget.baseImagePath.isEmpty) {
      return;
    }

    try {
      final file = File(path);

      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);

      final String extension = path.split('.').last.toLowerCase();

      final imageCacheService = context.read<ImageCacheService>();
      
      // 1. Coleta o Base64 das imagens já no Provider (FTP/Existentes)
      final Map<String, String> existingImages = {
          for (var img in imageCacheService.cachedImages) img.url!: img.base64Content!,
      };

      // 2. Adiciona a nova imagem com uma chave TEMPORÁRIA para reordenação
      final String tempKey = 'temp_${DateTime.now().millisecondsSinceEpoch}.$extension';
      existingImages[tempKey] = base64String;
      
      // 3. Reorganiza TODAS as imagens em sequência.
      final Map<String, String> reordered = {};
      int index = 1;
      String? lastSequentialPath;
      
      for (final entry in existingImages.entries) {
        final String currentExtension = entry.key.split('.').last.toLowerCase();
        final String newSequentialPath = 
            '${widget.baseImagePath}${widget.codePallet}_${index.toString().padLeft(3, '0')}.$currentExtension';

        reordered[newSequentialPath] = entry.value;
        
        lastSequentialPath = newSequentialPath;
        index++;
      }

      // ATUALIZAÇÃO CRÍTICA: Atualiza o mapa local e o Provider
      if (mounted) {
        setState(() {
          // Atualiza o mapa local para ser usado no build (Base64)
          _allImagesBase64
            ..clear()
            ..addAll(reordered);
        });
      }

      // LÓGICA FINAL: Usa o método setCacheFromMap para substituir o cache inteiro e CHAMA notifyListeners().
      imageCacheService.setCacheFromMap(reordered);

      // Notifica TODA a lista reorganizada para o widget pai.
      widget.onImagesChanged?.call(reordered.keys.toList());

    } catch (e) {
      // Tratar erro
    }
  }


  Future<void> _showAddImageOptions() async {
    if (widget.baseImagePath.isEmpty) return;

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
                  await _processNewImage(path);
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
                  await _processNewImage(path);
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