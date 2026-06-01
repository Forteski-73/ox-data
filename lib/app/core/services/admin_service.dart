// -----------------------------------------------------------
// app/core/services/admin_service.dart
// -----------------------------------------------------------
import 'package:flutter/foundation.dart';
import 'package:oxdata/app/core/repositories/admin_repository.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';
import 'package:oxdata/app/core/models/user_model.dart';
import 'package:oxdata/app/core/models/profile_model.dart';
import 'package:oxdata/app/core/models/profiles_menu.dart';

class AdminService with ChangeNotifier {

  final AdminRepository adminRepository;

  AdminService({
    required this.adminRepository,
  });

  List<UserModel> _users = [];
  List<UserModel> get users => _users;

  List<ProfileModel> _profiles = [];
  List<ProfileModel> get profiles => _profiles;

  ProfilesMenu? _profilesMenu;
  ProfilesMenu? get profilesMenu => _profilesMenu;

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

  /// ============================== PROFILES & MENUS ==============================
  
  /// Busca a estrutura completa de menus padrões e perfis vinculados
  Future<void> fetchProfilesMenu() async {
    final ApiResponse<ProfilesMenu> response = await adminRepository.getProfilesMenu();

    if (response.success && response.data != null) {
      _profilesMenu = response.data!;
    } else {
      _profilesMenu = null;
      debugPrint(
        'Erro ao buscar menus por perfil: ${response.message}',
      );
    }

    notifyListeners();
  }

  /// ============================== UPDATE PROFILE MENUS ==============================

  /// Envia a atualização de menus de um perfil para o repositório
  /// e atualiza o estado local em caso de sucesso.
  Future<ApiResponse<String>> updateProfileMenus({
    required int profileId,
    required String profileName,
    required List<Map<String, dynamic>> menus,
  }) async {
    
    final ApiResponse<String> response = await adminRepository.updateProfileMenus(
      profileId: profileId,
      profileName: profileName,
      menus: menus,
    );

    if (response.success) {
      await fetchProfilesMenu();
    } else {
      debugPrint(
        'Erro ao atualizar menus do perfil: ${response.message}',
      );
    }

    return response;
  }

  /// ============================== UPDATE USER PROFILE ==============================
  /// Atualiza o perfil vinculado a um usuário específico.
  Future<ApiResponse<String>> updateUserProfile({
    required int id,
    required String user,
    required int profileId,
  }) async {
    
    final ApiResponse<String> response = await adminRepository.updateUserProfile(
      id: id,
      user: user,
      profileId: profileId,
    );

    if (response.success) {
      // Atualiza o estado local buscando a lista de usuários atualizada da API
      await fetchUsers();
    } else {
      debugPrint(
        'Erro ao atualizar o perfil do usuário: ${response.message}',
      );
    }

    return response;
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