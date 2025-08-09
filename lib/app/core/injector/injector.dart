// -----------------------------------------------------------
// app/core/injector/injector.dart (Injeção de Dependências)
// -----------------------------------------------------------
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:oxdata/app/core/http/api_client.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';
import 'package:oxdata/app/core/repositories/product_repository.dart';
import 'package:oxdata/app/core/services/auth_service.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/services/product_service.dart';

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

    // 4. Registra o AuthService, que depende do AuthRepository.
    ChangeNotifierProvider<AuthService>(
      create: (context) => AuthService(context.read<AuthRepository>()),
    ),
    
    // 5. Registra o LoadingService.
    ChangeNotifierProvider<LoadingService>(
      create: (_) => LoadingService(),
    ),

    // 6. Registra o ProductService, que agora dependerá do ProductRepository.
    ChangeNotifierProvider<ProductService>(
      create: (context) => ProductService(productRepository: context.read<ProductRepository>()),
    ),
  ];

  static void configureDependencies() {
    // Esta função é chamada no main para envolver o app com os providers.
    // É uma prática comum para centralizar a configuração de dependências.
  }
}
