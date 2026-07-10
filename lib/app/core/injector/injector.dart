// -----------------------------------------------------------
// app/core/injector/injector.dart
// -----------------------------------------------------------
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:oxdata/app/core/http/api_client.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';
import 'package:oxdata/app/core/repositories/product_repository.dart';
import 'package:oxdata/app/core/repositories/pallet_repository.dart';
import 'package:oxdata/app/core/repositories/inventory_repository.dart';
import 'package:oxdata/app/core/repositories/inventory_local_repository.dart';
import 'package:oxdata/app/core/repositories/product_packing_repository.dart';
import 'package:oxdata/app/core/repositories/pallet_load_repository.dart';
import 'package:oxdata/app/core/repositories/admin_repository.dart';
import 'package:oxdata/app/core/repositories/ftp_repository.dart';
import 'package:oxdata/app/core/repositories/device_repository.dart';
import 'package:oxdata/app/core/repositories/image_repository.dart';
import 'package:oxdata/app/core/services/ftp_service.dart';
import 'package:oxdata/app/core/services/auth_service.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/services/product_service.dart';
import 'package:oxdata/app/core/services/pallet_service.dart';
import 'package:oxdata/app/core/services/load_service.dart';
import 'package:oxdata/app/core/services/image_cache_service.dart';
import 'package:oxdata/app/core/services/inventory_service.dart';
import 'package:oxdata/app/core/services/product_packing_service.dart';
import 'package:oxdata/app/core/services/admin_service.dart';
import 'package:oxdata/app/core/services/device_service.dart';
import 'package:oxdata/app/core/services/image_service.dart';
import 'package:oxdata/app/core/sync/sync_api_client_impl.dart';
import 'package:oxdata/db/app_database.dart';
import 'package:oxdata/db/daos/sync_queue_dao.dart';
import 'package:oxdata/app/core/services/sync_manager.dart';


class Injector {
  static List<SingleChildWidget> get providers {
    final db = AppDatabase();
    final syncQueueDao = SyncQueueDao(db);

    return [
      // 0. Banco de dados
      Provider<AppDatabase>.value(value: db),

      // 1. ApiClient
      Provider<ApiClient>(
        create: (_) => ApiClient(),
      ),

      // 2. AuthRepository
      Provider<AuthRepository>(
        create: (context) => AuthRepository(apiClient: context.read<ApiClient>()),
      ),

      // 3. ProductRepository
      Provider<ProductRepository>(
        create: (context) => ProductRepository(apiClient: context.read<ApiClient>()),
      ),

      // 4. PalletRepository
      Provider<PalletRepository>(
        create: (context) => PalletRepository(apiClient: context.read<ApiClient>()),
      ),

      // 5. LoadRepository
      Provider<LoadRepository>(
        create: (context) => LoadRepository(apiClient: context.read<ApiClient>()),
      ),

      // 6. InventoryRepository
      Provider<InventoryRepository>(
        create: (context) => InventoryRepository(apiClient: context.read<ApiClient>()),
      ),

      // 7. InventoryRecordsRepository (Outbox)
      Provider<InventoryRecordsRepository>(
        create: (context) => InventoryRecordsRepository(db, syncQueueDao),
      ),

      // 8. AdminRepository
      Provider<AdminRepository>(
        create: (context) => AdminRepository(apiClient: context.read<ApiClient>()),
      ),

      // 9. SyncManager — inicia em background ao ser criado
      Provider<SyncManager>(
        create: (context) {
          final manager = SyncManager(
            db: db,
            queueDao: syncQueueDao,
            api: SyncApiClientImpl(
              inventoryRepository: context.read<InventoryRepository>(),
              adminRepository: context.read<AdminRepository>(),
              database: db,
            ),
            connectivity: Connectivity(),
          );
          manager.start();
          return manager;
        },
        dispose: (_, manager) => manager.dispose(),
      ),

      // 10. FtpRepository
      Provider<FtpRepository>(
        create: (context) => FtpRepository(apiClient: context.read<ApiClient>()),
      ),

      // 11. ProductPackingRepository
      Provider<ProductPackingRepository>(
        create: (context) => ProductPackingRepository(
          apiClient: context.read<ApiClient>(),
        ),
      ),

      // 12. ImageCacheService
      ChangeNotifierProvider<ImageCacheService>(
        create: (_) => ImageCacheService(),
      ),

      // 13. FtpService
      Provider<FtpService>(
        create: (context) => FtpService(
          ftpRepository: context.read<FtpRepository>(),
          imageCacheService: context.read<ImageCacheService>(),
        ),
      ),

      // 14. AuthService
      ChangeNotifierProvider<AuthService>(
        create: (context) => AuthService(
          context.read<AuthRepository>(),
          context.read<ApiClient>(),
        ),
      ),

      // 15. LoadingService
      ChangeNotifierProvider<LoadingService>(
        create: (_) => LoadingService(),
      ),

      // 16. ProductService
      ChangeNotifierProvider<ProductService>(
        create: (context) => ProductService(
          productRepository: context.read<ProductRepository>(),
        ),
      ),

      // 17. PalletService
      ChangeNotifierProvider<PalletService>(
        create: (context) => PalletService(
          palletRepository: context.read<PalletRepository>(),
        ),
      ),

      // 18. LoadService
      ChangeNotifierProvider<LoadService>(
        create: (context) => LoadService(
          loadRepository: context.read<LoadRepository>(),
        ),
      ),

      // 19. InventoryService
      ChangeNotifierProvider<InventoryService>(
        create: (context) => InventoryService(
          inventoryRepository:  context.read<InventoryRepository>(),
          database:             db,
          recordsRepository:    context.read<InventoryRecordsRepository>(),
          syncManager:          context.read<SyncManager>(),
        ),
      ),

      // 20. ProductPackingService
      ChangeNotifierProvider<ProductPackingService>(
        create: (context) => ProductPackingService(
          repository: context.read<ProductPackingRepository>(),
        ),
      ),

      // 21. AdminService
      ChangeNotifierProvider<AdminService>(
        create: (context) => AdminService(
          adminRepository: context.read<AdminRepository>(),
        ),
      ),

      // 22. DeviceRepository
      Provider<DeviceRepository>(
        create: (context) => DeviceRepository(apiClient: context.read<ApiClient>()),
      ),

      // 23. DeviceService
      ChangeNotifierProvider<DeviceService>(
        create: (context) => DeviceService(
          deviceRepository: context.read<DeviceRepository>(),
        ),
      ),
      
      // 24. ImageRepository
      Provider<ImageRepository>(
        create: (context) => ImageRepository(apiClient: context.read<ApiClient>()),
      ),

      // 25. ImageService
      ChangeNotifierProvider<ImageService>(
        create: (context) => ImageService(
          imageRepository: context.read<ImageRepository>(),
        ),
      ),

    ];
  }

  static void configureDependencies() {}
}
