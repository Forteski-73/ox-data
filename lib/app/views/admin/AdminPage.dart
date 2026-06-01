import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/models/user_model.dart';
import 'package:oxdata/app/core/models/profile_model.dart';
import 'package:oxdata/app/core/models/profiles_menu.dart';
import 'package:oxdata/app/core/services/admin_service.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/widgets/app_bar.dart';
import 'package:oxdata/app/core/widgets/pulse_icon.dart';
import 'package:oxdata/app/core/utils/call_action.dart';
import 'package:oxdata/app/core/services/message_service.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool _showUsers = false;
  bool _showProfiles = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  final Map<String, String?> _selectedProfilesLocally = {};

  // =========================================
  // PICK LIST STATE (Fortemente tipado)
  // =========================================
  final Map<String, List<MenuSimpleModel>> _selectedMenusByProfile = {};
  final Map<String, List<MenuSimpleModel>> _availableMenusByProfile = {};

  // =========================================
  // ITEM SELECIONADO POR PERFIL (MenuSimpleModel?)
  // =========================================
  final Map<String, MenuSimpleModel?> _selectedAvailableMenu = {};
  final Map<String, MenuSimpleModel?> _selectedSelectedMenu = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchText = value;
    });
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: 'Pesquisar usuário',
        hintStyle: TextStyle(
          color: Colors.blueGrey[300],
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: Colors.indigo,
          size: 22,
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  size: 20,
                ),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged("");
                },
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(
            color: Colors.indigo,
            width: 1,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loadingService = context.read<LoadingService>();
    final adminService = context.watch<AdminService>();

    final List<UserModel> users = adminService.users;
    final List<ProfileModel> profiles = adminService.profiles;

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppBarCustom(
          title: 'Painel Administrativo',
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // =========================================
            // HEADER BUTTONS
            // =========================================
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // PERFIS
                  Expanded(
                    child: PulseIconButton(
                      icon: Icons.settings_outlined,
                      color: Colors.indigo,
                      onPressed: () async {
                        await CallAction.run(
                          action: () async {
                            loadingService.show();
                            await adminService.fetchProfilesMenu();

                            final profilesMenu = adminService.profilesMenu;

                            // LIMPA ESTADO ANTIGO
                            _selectedMenusByProfile.clear();
                            _availableMenusByProfile.clear();
                            _selectedAvailableMenu.clear();
                            _selectedSelectedMenu.clear();

                            // MONTA DADOS REAIS DA API (Mantendo objetos completos)
                            if (profilesMenu != null) {
                              final allMenus = profilesMenu.menusDefault;

                              for (final profileMenu in profilesMenu.profiles) {
                                final List<MenuSimpleModel> selectedMenus = profileMenu.menus;

                                final List<MenuSimpleModel> availableMenus = allMenus
                                    .where(
                                      (menuDefault) => !profileMenu.menus.any(
                                        (selected) => selected.id == menuDefault.id,
                                      ),
                                    )
                                    .toList();

                                _selectedMenusByProfile[profileMenu.name] = selectedMenus;
                                _availableMenusByProfile[profileMenu.name] = availableMenus;
                              }
                            }

                            setState(() {
                              _showProfiles = true;
                              _showUsers = false;
                            });
                          },
                          onFinally: () {
                            loadingService.hide();
                          },
                        );
                      },
                    ),
                  ),
                  // USUÁRIOS
                  Expanded(
                    child: PulseIconButton(
                      icon: Icons.group_outlined,
                      color: Colors.indigo,
                      onPressed: () async {
                        await CallAction.run(
                          action: () async {
                            loadingService.show();
                            await adminService.fetchUsers();
                            await adminService.fetchProfiles();

                            setState(() {
                              _showUsers = true;
                              _showProfiles = false;
                              _searchText = '';
                              _searchController.clear();
                            });
                          },
                          onFinally: () {
                            loadingService.hide();
                          },
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: PulseIconButton(
                      icon: Icons.announcement_outlined,
                      color: Colors.indigo.shade300,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
            
            // =========================================
            // DINAMIC BODY CONTENT
            // =========================================
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: _showUsers
                    ? Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildSearchField(),
                          ),
                          Expanded(
                            child: _buildUsersList(users, profiles),
                          ),
                        ],
                      )
                    : _showProfiles
                        ? _buildProfilesList(
                            adminService.profilesMenu?.profiles ?? [],
                          )
                        : _buildWelcome(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.admin_panel_settings_outlined,
            size: 85,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Bem-vindo Administrador!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // PERFIS + PICK LIST
  // =========================================================
  Widget _buildProfilesList(List<dynamic> profiles) {
    if (profiles.isEmpty) {
      return const Center(
        child: Text('Nenhum perfil encontrado.'),
      );
    }

    return ListView.builder(
      itemCount: profiles.length,
      itemBuilder: (context, index) {
        final profile = profiles[index];

        final selectedMenus = _selectedMenusByProfile[profile.name] ?? [];
        final availableMenus = _availableMenusByProfile[profile.name] ?? [];
        final selectedAvailable = _selectedAvailableMenu[profile.name];
        final selectedSelected = _selectedSelectedMenu[profile.name];

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: ExpansionTile(
            shape: const Border(),
            collapsedShape: const Border(),
            leading: const CircleAvatar(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              child: Icon(Icons.security),
            ),
            title: Text(
              profile.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text('Gerenciamento de menus'),
            children: [
              const Divider(height: 1),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // DISPONÍVEIS
                    Expanded(
                      child: _buildMenuList(
                        title: 'Menus disponíveis',
                        items: availableMenus,
                        selectedItem: selectedAvailable,
                        onTap: (menu) {
                          setState(() {
                            _selectedAvailableMenu[profile.name] = menu;
                            _selectedSelectedMenu[profile.name] = null;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // BOTÕES DE ALTERNÂNCIA
                    Column(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            // Ativo
                            backgroundColor: Colors.indigo.shade500,  // Cor de fundo do botão
                            foregroundColor: Colors.white,            // Cor do ícone
                            // Inativo
                            disabledBackgroundColor: Colors.grey.shade200, 
                            disabledForegroundColor: Colors.grey.shade400, 
                          ),
                          onPressed: selectedAvailable == null
                              ? null
                              : () async {
                                  setState(() {
                                    _availableMenusByProfile[profile.name]?.remove(selectedAvailable);
                                    _selectedMenusByProfile[profile.name] ??= [];
                                    _selectedMenusByProfile[profile.name]!.add(selectedAvailable);
                                    _selectedAvailableMenu[profile.name] = null;
                                  });

                                  final adminService = Provider.of<AdminService>(context, listen: false);
                                  
                                  final currentSelected = _selectedMenusByProfile[profile.name] ?? [];
                                  final menusPayload = currentSelected.map((m) => {
                                    "id": m.id,
                                    "title": m.title,
                                  }).toList();

                                  final response = await adminService.updateProfileMenus(
                                    profileId: profile.id,
                                    profileName: profile.name,
                                    menus: menusPayload,
                                  );

                                  if (!response.success && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Erro ao salvar: ${response.message}')),
                                    );
                                  }
                                },
                          child: const Icon(Icons.chevron_right_rounded, size: 28,),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            // Ativo
                            backgroundColor: Colors.indigo.shade500,  // Cor de fundo do botão
                            foregroundColor: Colors.white,            // Cor do ícone
                            // Inativo
                            disabledBackgroundColor: Colors.grey.shade200, 
                            disabledForegroundColor: Colors.grey.shade400, 
                          ),
                          onPressed: selectedSelected == null
                              ? null
                              : () async {
                                  setState(() {
                                    _selectedMenusByProfile[profile.name]?.remove(selectedSelected);
                                    _availableMenusByProfile[profile.name] ??= [];
                                    _availableMenusByProfile[profile.name]!.add(selectedSelected);
                                    _selectedSelectedMenu[profile.name] = null;
                                  });

                                  final adminService = Provider.of<AdminService>(context, listen: false);
                                  
                                  final currentSelected = _selectedMenusByProfile[profile.name] ?? [];
                                  final menusPayload = currentSelected.map((m) => {
                                    "id": m.id,
                                    "title": m.title,
                                  }).toList();

                                  final response = await adminService.updateProfileMenus(
                                    profileId: profile.id,
                                    profileName: profile.name,
                                    menus: menusPayload,
                                  );

                                  if (!response.success && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Erro ao salvar: ${response.message}')),
                                    );
                                  }
                                },
                          child: const Icon(Icons.chevron_left_rounded, size: 28,),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // SELECIONADOS
                    Expanded(
                      child: _buildMenuList(
                        title: 'Menus selecionados',
                        items: selectedMenus,
                        selectedItem: selectedSelected,
                        onTap: (menu) {
                          setState(() {
                            _selectedSelectedMenu[profile.name] = menu;
                            _selectedAvailableMenu[profile.name] = null;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuList({
    required String title,
    required List<MenuSimpleModel> items,
    required MenuSimpleModel? selectedItem,
    required Function(MenuSimpleModel menu) onTap,
  }) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.indigo,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('Nenhum item'))
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isSelected = selectedItem?.id == item.id;

                      return Material(
                        color: isSelected ? Colors.indigo.shade50 : Colors.transparent,
                        child: InkWell(
                          onTap: () => onTap(item),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.menu,
                                  size: 18,
                                  color: isSelected ? Colors.indigo : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? Colors.indigo : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // LISTA DE USUÁRIOS
  // =========================================================
  Widget _buildUsersList(List<UserModel> users, List<ProfileModel> profiles,)
  {
    final adminService = context.watch<AdminService>();
    final filteredUsers = users.where((user) {
      final search = _searchText.toLowerCase();
      return user.user.toLowerCase().contains(search) ||
          user.account.toLowerCase().contains(search) ||
          (user.profileName ?? '').toLowerCase().contains(search);
    }).toList();

    if (filteredUsers.isEmpty) {
      return const Center(
        child: Text('Nenhum usuário encontrado.'),
      );
    }

    return ListView.builder(
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];

        final String? currentProfile = _selectedProfilesLocally.containsKey(user.account)
            ? _selectedProfilesLocally[user.account]
            : user.profileName;

        final bool profileExists = profiles.any((p) => p.name == currentProfile);
        final String? initialValue = profileExists ? currentProfile : null;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: ExpansionTile(
            shape: const Border(),
            collapsedShape: const Border(),
            leading: CircleAvatar(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              child: Text(
                user.user.isNotEmpty ? user.user[0].toUpperCase() : '?',
              ),
            ),
            title: Text(
              user.user,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.account),
                if (currentProfile != null && currentProfile.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      currentProfile,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
              ],
            ),
            children: [
              const Divider(height: 1),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: profiles.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Nenhum perfil carregado da API.'),
                        ),
                      )
                      :DropdownButtonFormField<int>(
                        value: profiles.where((p) => p.name == initialValue,).isNotEmpty
                            ? profiles.firstWhere((p) => p.name == initialValue,).id
                            : null,
                        hint: const Text('Selecione um perfil'),
                        items: profiles.map<DropdownMenuItem<int>>((profile) {
                          return DropdownMenuItem<int>(
                            value: profile.id,
                            child: Text(profile.name),
                          );
                        }).toList(),

                        onChanged: (int? profileId) async {

                          if (profileId != null) {
                            
                            final selectedProfile = profiles.firstWhere((p) => p.id == profileId,);

                            final response = await adminService.updateUserProfile(
                              id: user.id,
                              user: user.user,
                              profileId: profileId,
                            );

                            if (response.success) {

                              setState(() {
                                _selectedProfilesLocally[user.account] = selectedProfile.name;
                              });

                              MessageService.showSuccess(response.message ?? 'Perfil atualizado com sucesso.',);
                            } else {
                              MessageService.showError(response.message ?? 'Erro ao atualizar o perfil.',);
                            }
                          }
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}