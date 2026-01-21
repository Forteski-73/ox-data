// -----------------------------------------------------------
// app/core/injector/injector.dart (Injeção de Dependências)
// -----------------------------------------------------------
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:oxdata/app/core/http/api_client.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';
import 'package:oxdata/app/core/repositories/product_repository.dart';
import 'package:oxdata/app/core/repositories/pallet_repository.dart';
import 'package:oxdata/app/core/repositories/inventory_repository.dart';
import 'package:oxdata/app/core/services/ftp_service.dart'; 
import 'package:oxdata/app/core/repositories/ftp_repository.dart'; 
import 'package:oxdata/app/core/services/auth_service.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/services/product_service.dart';
import 'package:oxdata/app/core/services/pallet_service.dart'; 
import 'package:oxdata/app/core/services/load_service.dart'; 
import 'package:oxdata/app/core/services/image_cache_service.dart';
import 'package:oxdata/app/core/services/inventory_service.dart';
import 'package:oxdata/app/core/repositories/pallet_load_repository.dart';
import 'package:oxdata/db/app_database.dart';

class Injector {
  // A ordem dos providers é importante!
  // As dependências de baixo nível devem ser criadas primeiro.
  static List<SingleChildWidget> get providers {
    // Instância única do banco de dados (Singleton)
    final db = AppDatabase();

    return [
      // 0. Registra o Banco de Dados para que possa ser lido via context se necessário
      Provider<AppDatabase>.value(value: db),

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

      // 5. Registra o LoadRepository, que depende do ApiClient.
      Provider<LoadRepository>(
        create: (context) => LoadRepository(apiClient: context.read<ApiClient>()),
      ),

      // Registra o InventoryRepository
      Provider<InventoryRepository>(
        create: (context) => InventoryRepository(apiClient: context.read<ApiClient>()),
      ),

      // 6. Registra o FtpRepository, que depende do ApiClient.
      Provider<FtpRepository>(
        create: (context) => FtpRepository(apiClient: context.read<ApiClient>()),
      ),
      
      // 7. Registra o ImageCacheService.
      ChangeNotifierProvider<ImageCacheService>(
        create: (_) => ImageCacheService(),
      ),

      // 8. Registra o FtpService, que depende do FtpRepository.
      Provider<FtpService>(
        create: (context) => FtpService(
          ftpRepository: context.read<FtpRepository>(),
          imageCacheService: context.read<ImageCacheService>(),
        ),
      ),

      // 9. Registra o AuthService, que depende do AuthRepository.
      ChangeNotifierProvider<AuthService>(
        create: (context) => AuthService(context.read<AuthRepository>(), context.read<ApiClient>()),
      ),
      
      // 10. Registra o LoadingService.
      ChangeNotifierProvider<LoadingService>(
        create: (_) => LoadingService(),
      ),

      // 11. Registra o ProductService.
      ChangeNotifierProvider<ProductService>(
        create: (context) => ProductService(productRepository: context.read<ProductRepository>()),
      ),
      
      // 12. Registra o PalletService.
      ChangeNotifierProvider<PalletService>(
        create: (context) => PalletService(palletRepository: context.read<PalletRepository>()),
      ),

      // 13. Registra o LoadService.
      ChangeNotifierProvider<LoadService>(
        create: (context) => LoadService(loadRepository: context.read<LoadRepository>()),
      ),

      // 14. Registra o InventoryService, injetando Repository e o Database
      ChangeNotifierProvider<InventoryService>(
        create: (context) => InventoryService(
          inventoryRepository: context.read<InventoryRepository>(),
          database: db,
        ),
      ),
    ];
  }

  static void configureDependencies() {
    // Esta função é chamada no main para envolver o app com os providers.
  }
}

/*
// -----------------------------------------------------------
// app/core/injector/injector.dart (Injeção de Dependências)
// -----------------------------------------------------------
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:oxdata/app/core/http/api_client.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';
import 'package:oxdata/app/core/repositories/product_repository.dart';
import 'package:oxdata/app/core/repositories/pallet_repository.dart';
import 'package:oxdata/app/core/repositories/inventory_repository.dart';
import 'package:oxdata/app/core/services/ftp_service.dart'; 
import 'package:oxdata/app/core/repositories/ftp_repository.dart'; 
import 'package:oxdata/app/core/services/auth_service.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/services/product_service.dart';
import 'package:oxdata/app/core/services/pallet_service.dart'; 
import 'package:oxdata/app/core/services/load_service.dart'; 
import 'package:oxdata/app/core/services/image_cache_service.dart';
import 'package:oxdata/app/core/services/inventory_service.dart';
import 'package:oxdata/app/core/repositories/pallet_load_repository.dart';
import 'package:oxdata/db/app_database.dart';

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

    // 5. Registra o LoadRepository, que depende do ApiClient.
    Provider<LoadRepository>(
      create: (context) => LoadRepository(apiClient: context.read<ApiClient>()),
    ),

    Provider<InventoryRepository>(
      create: (context) => InventoryRepository(apiClient: context.read<ApiClient>()),
    ),

    // 6. Registra o FtpRepository, que depende do ApiClient.
    Provider<FtpRepository>(
      create: (context) => FtpRepository(apiClient: context.read<ApiClient>()),
    ),
    
    // 7. Registra o ImageCacheService.
    // TEM QUE VIR ANTES do FtpService (que o consome)
    ChangeNotifierProvider<ImageCacheService>(
      create: (_) => ImageCacheService(),
    ),

    // 8. Registra o FtpService, que depende do FtpRepository.
    Provider<FtpService>(
          create: (context) => FtpService(
            ftpRepository: context.read<FtpRepository>(),
            imageCacheService: context.read<ImageCacheService>(),
          ),
        ),

    // 9. Registra o AuthService, que depende do AuthRepository.
    ChangeNotifierProvider<AuthService>(
      create: (context) => AuthService(context.read<AuthRepository>(), ApiClient()),
    ),
    
    // 10. Registra o LoadingService.
    ChangeNotifierProvider<LoadingService>(
      create: (_) => LoadingService(),
    ),

    // 11. Registra o ProductService, que agora dependerá do ProductRepository.
    ChangeNotifierProvider<ProductService>(
      create: (context) => ProductService(productRepository: context.read<ProductRepository>()),
    ),
    
    // 12. Registra o PalletService, que depende do PalletRepository.
    ChangeNotifierProvider<PalletService>(
      create: (context) => PalletService(palletRepository: context.read<PalletRepository>()),
    ),

    // 13. Registra o PalletService, que depende do PalletRepository.
    ChangeNotifierProvider<LoadService>(
      create: (context) => LoadService(loadRepository: context.read<LoadRepository>()),
    ),

    //14. Registra o InventoryService, que depende do InventoryRepository.
    ChangeNotifierProvider<InventoryService>(
      create: (context) => InventoryService(inventoryRepository: context.read<InventoryRepository>()),
    ),
  ];

  static void configureDependencies() {
    // Esta função é chamada no main para envolver o app com os providers.
    // Serve para centralizar a configuração de dependências.
  }
}
*/