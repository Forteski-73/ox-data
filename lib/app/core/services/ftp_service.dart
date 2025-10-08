// -----------------------------------------------------------
// app/core/services/ftp_service.dart (Serviço de FTP/HTTP)
// -----------------------------------------------------------
import 'package:oxdata/app/core/repositories/ftp_repository.dart'; 
import 'package:oxdata/app/core/models/ftp_image_request.dart';
import 'package:oxdata/app/core/models/ftp_image_response.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';
import 'package:oxdata/app/core/services/image_cache_service.dart';

/*class FtpService {
  final FtpRepository ftpRepository; 

  FtpService({required this.ftpRepository});

  Future<ApiResponse<List<FtpImageResponse>>> fetchImagesBase64(List<String> imageUrls) async {
    final request = FtpImageRequest(imageUrls: imageUrls);

    final response = await ftpRepository.getImagesBase64(request);

    return response;
  }

}*/

class FtpService {
  final FtpRepository ftpRepository; 
  final ImageCacheService imageCacheService;

  // Construtor com a nova dependência
  FtpService({required this.ftpRepository, required this.imageCacheService});

  Future<ApiResponse<List<FtpImageResponse>>> fetchImagesBase64(List<String> imageUrls) async {
    final request = FtpImageRequest(imageUrls: imageUrls);

    final response = await ftpRepository.getImagesBase64(request);
    
    if (response.success && response.data != null) {
        // Salva as imagens buscadas no cache global
        imageCacheService.setCacheImages(response.data!);
    }
    else{
      imageCacheService.clearCache();
    }
    
    return response;
  }

  Future<ApiResponse<List<FtpImageResponse>>> setImagesBase64(List<FtpImageResponse> cachedImages) async {

    final response = await ftpRepository.setImagesBase64(cachedImages);
    
    if (response.success && response.data != null) {
        // Salva as imagens buscadas no cache global
        imageCacheService.setCacheImages(response.data!);
    }
    else{
      imageCacheService.clearCache();
    }

    return response;
  }
}
