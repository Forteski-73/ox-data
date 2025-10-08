// -----------------------------------------------------------
// app/core/injector/injector.dart (Injeção de Dependências)
// -----------------------------------------------------------
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:oxdata/app/core/http/api_client.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';
import 'package:oxdata/app/core/repositories/product_repository.dart';
import 'package:oxdata/app/core/repositories/pallet_repository.dart';
import 'package:oxdata/app/core/services/ftp_service.dart'; 
import 'package:oxdata/app/core/repositories/ftp_repository.dart'; 
import 'package:oxdata/app/core/services/auth_service.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/services/product_service.dart';
import 'package:oxdata/app/core/services/pallet_service.dart'; 
import 'package:oxdata/app/core/services/image_cache_service.dart';

class Injector {
  // A ordem dos providers é importante!
  // As dependências de baixo nível devem ser criadas primeiro.
  static List<SingleChildWidget> get providers => [
    // 1. Registra o ApiClient.
    Provider<ApiClient>(
      create: (_) => ApiClient(),
    ),

    // 2. Registra o AuthRepository, que depende do ApiClient.
    Provider<AuthRepository>(
      create: (context) => AuthRepository(apiClient: context.read<ApiClient>()),
    ),

    // 3. Registra o ProductRepository, que depende do ApiClient.
    Provider<ProductRepository>(
      create: (context) => ProductRepository(apiClient: context.read<ApiClient>()),
    ),

    // 4. Registra o PalletRepository, que depende do ApiClient.
    Provider<PalletRepository>(
      create: (context) => PalletRepository(apiClient: context.read<ApiClient>()),
    ),

    // 5. Registra o FtpRepository, que depende do ApiClient.
    Provider<FtpRepository>(
      create: (context) => FtpRepository(apiClient: context.read<ApiClient>()),
    ),
    
    // 8. Registra o ImageCacheService.
    // TEM QUE VIR ANTES do FtpService (que o consome)
    ChangeNotifierProvider<ImageCacheService>(
      create: (_) => ImageCacheService(),
    ),

    // 6. Registra o FtpService, que depende do FtpRepository.
    Provider<FtpService>(
          create: (context) => FtpService(
            ftpRepository: context.read<FtpRepository>(),
            imageCacheService: context.read<ImageCacheService>(),
          ),
        ),

    // 7. Registra o AuthService, que depende do AuthRepository.
    ChangeNotifierProvider<AuthService>(
      create: (context) => AuthService(context.read<AuthRepository>(), ApiClient()),
    ),
    
    // 8. Registra o LoadingService.
    ChangeNotifierProvider<LoadingService>(
      create: (_) => LoadingService(),
    ),

    // 9. Registra o ProductService, que agora dependerá do ProductRepository.
    ChangeNotifierProvider<ProductService>(
      create: (context) => ProductService(productRepository: context.read<ProductRepository>()),
    ),
    
    // 10. Registra o PalletService, que depende do PalletRepository.
    ChangeNotifierProvider<PalletService>(
      create: (context) => PalletService(palletRepository: context.read<PalletRepository>()),
    ),

  ];

  static void configureDependencies() {
    // Esta função é chamada no main para envolver o app com os providers.
    // Serve para centralizar a configuração de dependências.
  }
}
