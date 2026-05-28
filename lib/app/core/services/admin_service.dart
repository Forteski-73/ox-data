// -----------------------------------------------------------
// app/core/services/admin_service.dart
// -----------------------------------------------------------
import 'package:flutter/foundation.dart';
import 'package:oxdata/app/core/repositories/admin_repository.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';
import 'package:oxdata/app/core/models/user_model.dart';
import 'package:oxdata/app/core/models/profile_model.dart';

class AdminService with ChangeNotifier {

  final AdminRepository adminRepository;

  AdminService({
    required this.adminRepository,
  });

  List<UserModel> _users = [];
  List<UserModel> get users => _users;

  List<ProfileModel> _profiles = [];
  List<ProfileModel> get profiles => _profiles;

  /// ==================== USERS ====================

  /// Busca todos os usuários da API
  Future<void> fetchUsers() async {

    final ApiResponse<List<UserModel>> response =
        await adminRepository.getUsers();

    if (response.success && response.data != null) {

      _users = response.data!;

    } else {

      _users = [];

      debugPrint(
        'Erro ao buscar usuários: ${response.message}',
      );
    }

    notifyListeners();
  }

  /// ======================================== PROFILES ========================================
  Future<void> fetchProfiles() async {

    final ApiResponse<List<ProfileModel>> response = await adminRepository.getProfiles();

    if (response.success && response.data != null) {
      _profiles = response.data!;
    } else {
      _profiles = [];
      debugPrint(
        'Erro ao buscar perfis: ${response.message}',
      );
    }

    notifyListeners();
  }

  /// ====================================== UTILITÁRIOS ======================================

  void clearUsers() {

    _users = [];

    notifyListeners();
  }

  /// Busca usuário localmente pelo ID
  UserModel? getUserById(int id) {

    try {

      return _users.firstWhere(
        (u) => u.id == id,
      );

    } catch (e) {

      return null;
    }
  }

  /// Busca usuário localmente pelo username
  UserModel? getUserByUsername(String username) {

    try {

      return _users.firstWhere(
        (u) => u.user.toLowerCase() ==
            username.toLowerCase(),
      );

    } catch (e) {

      return null;
    }
  }
}