import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/utils/call_action.dart';
import 'package:oxdata/app/core/services/ftp_service.dart';
import 'package:oxdata/app/core/models/ftp_image_response.dart'; 
import 'dart:io';
import 'dart:convert'; 

class ImagesPicker extends StatefulWidget {
  final List<String>? imagePaths;
  
  // O nome base a ser usado para gerar os caminhos sequenciais das novas imagens.
  // Ex: se for 'produto_123', as novas imagens serão 'produto_123_001.jpg', etc.
  final String baseImagePath;
  final String codeImg;

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
    required this.baseImagePath,
    required this.codeImg, 
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
  // Mapeia a URL/Caminho Sequencial (String) para a string Base64 (String).
  Map<String, String> _allImagesBase64 = {}; 
  bool _isLoadingFtpImages = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchFtpImages();
    });
  }

  /// Busca as imagens via FTP/HTTP e armazena o Base64.
  Future<void> _fetchFtpImages() async {
    // Filtra apenas caminhos que parecem ser URLs (que precisam de busca via FTP/API)
    final List<String> ftpImagePaths = (widget.imagePaths ?? [])
      .where((path) => path.startsWith('http') || path.contains('/'))
      .toList();


    if (ftpImagePaths.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoadingFtpImages = false;
        });
      }
      return;
    }

    final loadingService = context.read<LoadingService>();
    loadingService.show();

    try {
      final FtpService ftpService = context.read<FtpService>();
      
      final response = await ftpService.fetchImagesBase64(ftpImagePaths);

      if (response.success && response.data != null) {
        final Map<String, String> fetchedImages = {};
        for (final FtpImageResponse imgResponse in response.data!) {
          if (imgResponse.url.isNotEmpty && imgResponse.base64Content.isNotEmpty) {
            fetchedImages[imgResponse.url] = imgResponse.base64Content;
          }
        }
        if (mounted) {
          setState(() {
            // Armazena todas as imagens FTP no mapa unificado
            _allImagesBase64.addAll(fetchedImages);
          });
        }
      } else {
        // CallAction.showToast('Erro ao buscar imagens FTP: ${response.message}');
      }
    } catch (e) {
      // CallAction.showToast('Exceção ao buscar imagens FTP: $e');
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
    
    // Verifica se o baseImagePath é válido para habilitar a adição de novas imagens
    final bool canAddImage  = widget.baseImagePath.isNotEmpty;
    final Color iconColor   = canAddImage ? Colors.grey : Colors.grey.shade400;
    final Color borderColor = canAddImage ? Colors.grey.shade300 : Colors.red.shade200;
    final String message    = canAddImage ? 'Adicionar Foto' : 'Base path ausente';


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
                border: Border.all(color: borderColor, width: 1.0),
                borderRadius: BorderRadius.circular(4),
              ),
              child: GestureDetector(
                // Adiciona a lógica de verificação
                onTap: canAddImage ? _showAddImageOptions : () {
                  //CallAction.showToast('Preencha o caminho base da imagem primeiro.');
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

  Widget _buildImageWidget(String imagePath, double height) {
    // 1. Tenta carregar a imagem em Base64, se disponível (Imagens FTP ou Novas Renomeadas)
    if (_allImagesBase64.containsKey(imagePath)) {
      try {
        final bytes = base64Decode(_allImagesBase64[imagePath]!);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: height,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.description, size: 80, color: Colors.grey),
        );
      } catch (e) {
        // Falha na decodificação do Base64
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
    
    // 3. Tratar como placeholder se for um path desconhecido (nem Base64, nem HTTP)
    else {
      // Se a imagem não for Base64, nem HTTP, nem arquivo local existente,
      // é um path inválido, uma imagem FTP que falhou ao carregar ou um path local temporário antigo.
      return const Icon(Icons.description, size: 80, color: Colors.grey);
    }
  }

  // NOVO MÉTODO: Lê o arquivo local e o converte para Base64
  Future<void> _processNewImage(String? path) async {
    // 1. Verificação de segurança: Não processa se o caminho for nulo ou se o baseImagePath estiver vazio
    if (path == null || widget.baseImagePath.isEmpty) {
      // Se este método for chamado diretamente (e não via _showAddImageOptions), 
      // ele não fará nada. A notificação de erro é tratada no UI (build/GestureDetector).
      return;
    }

    try {
      final file = File(path);
      
      // Lê e converte para Base64
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);

      final String extension = path.split('.').last.toLowerCase();
      // Determina o próximo índice sequencial (baseado no total de itens)
      final int newIndex = (widget.imagePaths?.length ?? 0) + 1;
      
      // Cria o novo caminho padronizado: '{baseImagePath}_001.jpg'
      final String newSequentialPath = 
        '${widget.baseImagePath}_${newIndex.toString().padLeft(3, '0')}.$extension';

      setState(() {
        // Usa o NOVO CAMINHO SEQUENCIAL como chave para armazenar o Base64
        _allImagesBase64[newSequentialPath] = base64String;
      });

      // Notifica o widget pai com o NOVO CAMINHO SEQUENCIAL
      widget.onImageAdded?.call(newSequentialPath);

    } catch (e) {
      // Tratar erro de leitura/conversão
      // CallAction.showToast('Erro ao processar a imagem selecionada: $e');
    }
  }

  Future<void> _showAddImageOptions() async {
    // Verifica novamente aqui para garantir que a opção só aparece se puder adicionar.
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
                  await _processNewImage(path); // Novo passo de processamento
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
                  await _processNewImage(path); // Novo passo de processamento
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
