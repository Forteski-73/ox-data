import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:oxdata/app/core/models/user_model.dart';
import 'package:oxdata/app/core/models/profile_model.dart'; // <-- IMPORTADO O MODELO DE PERFIL
import 'package:oxdata/app/core/services/admin_service.dart';
import 'package:oxdata/app/core/services/loading_service.dart';

import 'package:oxdata/app/core/widgets/app_bar.dart';
import 'package:oxdata/app/core/widgets/pulse_icon.dart';

import 'package:oxdata/app/core/utils/call_action.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool _showUsers = false;
  final TextEditingController _searchController = TextEditingController();
  
  String _searchText = '';
  
  // O estado de _profiles agora é controlado globalmente pelo AdminService.
  // Mantemos apenas o mapa de controle visual local na View:
  final Map<String, String?> _selectedProfilesLocally = {};

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

  // =========================================================
  // SEU CAMPO DE PESQUISA ESTILIZADO
  // =========================================================
  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: 'Pesquisar usuário...',
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
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged("");
                },
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Colors.indigo, width: 1),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loadingService = context.read<LoadingService>();
    final adminService = context.watch<AdminService>();
    
    // Pegando as duas listas reativas direto do Service unificado
    final List<UserModel> users = adminService.users;
    final List<ProfileModel> profiles = adminService.profiles;

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppBarCustom(
          title: 'Painel Administrativo',
        ),
      ),
      body: Stack(
        children: [
          // CONTEÚDO
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 80.0,
                left: 10.0,
                right: 10.0,
                bottom: 10.0,
              ),
              child: _showUsers
                  ? Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildSearchField(),
                        ),
                        Expanded(
                          // Passando os usuários e os perfis tipados para a listagem
                          child: _buildUsersList(users, profiles),
                        ),
                      ],
                    )
                  : _buildWelcome(),
            ),
          ),

          // HEADER BUTTONS
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: PulseIconButton(
                      icon: Icons.settings_outlined,
                      color: Colors.indigo,
                      onPressed: () {},
                    ),
                  ),
                  
                  // BOTÃO USUÁRIOS
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
                      icon: Icons.analytics_outlined,
                      color: Colors.indigo,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.admin_panel_settings_outlined,
            size: 85,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Bem-vindo ao Admin',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // LISTA DE USUÁRIOS COM COMBOBOX DINÂMICO
  // =========================================================
  Widget _buildUsersList(List<UserModel> users, List<ProfileModel> profiles) {
    final filteredUsers = users.where((user) {
      final search = _searchText.toLowerCase();
      return user.user.toLowerCase().contains(search) ||
          user.account.toLowerCase().contains(search) ||
          (user.profileName ?? '').toLowerCase().contains(search);
    }).toList();

    if (filteredUsers.isEmpty) {
      return const Center(child: Text('Nenhum usuário encontrado.'));
    }

    return ListView.builder(
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];

        final String? currentProfile = _selectedProfilesLocally.containsKey(user.account)
            ? _selectedProfilesLocally[user.account]
            : user.profileName;

        // Valida se o perfil atual existe na lista de objetos ProfileModel
        final bool profileExists = profiles.any((p) => p.name == currentProfile);
        final String? initialValue = profileExists ? currentProfile : null;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ExpansionTile(
            shape: const Border(),
            collapsedShape: const Border(),
            leading: CircleAvatar(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              child: Text(user.user.isNotEmpty ? user.user[0].toUpperCase() : '?'),
            ),
            title: Text(user.user, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.account),
                if (currentProfile != null && currentProfile.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      currentProfile,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.indigo),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    profiles.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Nenhum perfil carregado da API.'),
                            ),
                          )
                        : DropdownButtonFormField<String>(
                            value: initialValue,
                            hint: const Text('Selecione um perfil'),
                            style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              labelText: 'Perfil de Acesso',
                              labelStyle: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
                              prefixIcon: const Icon(Icons.admin_panel_settings, color: Colors.indigo),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.indigo, width: 1.5),
                              ),
                            ),
                            // Mapeia os dados usando propriedades do ProfileModel (.name) ao invés de chaves de String
                            items: profiles.map<DropdownMenuItem<String>>((profile) {
                              return DropdownMenuItem<String>(
                                value: profile.name,
                                child: Text(profile.name),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedProfilesLocally[user.account] = newValue;
                                });
                                
                                debugPrint('Novo perfil salvo localmente para ${user.user}: $newValue');
                              }
                            },
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
}