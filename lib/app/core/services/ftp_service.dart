// -----------------------------------------------------------
// app/core/services/ftp_service.dart (Serviço de FTP/HTTP)
// -----------------------------------------------------------
import 'package:oxdata/app/core/repositories/ftp_repository.dart'; 
import 'package:oxdata/app/core/models/ftp_image_request.dart';
import 'package:oxdata/app/core/models/ftp_image_response.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';

class FtpService {
  final FtpRepository ftpRepository; 

  FtpService({required this.ftpRepository});

  Future<ApiResponse<List<FtpImageResponse>>> fetchImagesBase64(List<String> imageUrls) async {
    final request = FtpImageRequest(imageUrls: imageUrls);

    final response = await ftpRepository.getImagesBase64(request);

    return response;
  }
  
}
