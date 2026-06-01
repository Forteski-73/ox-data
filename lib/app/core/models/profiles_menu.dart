/// Classe que representa o retorno unificado do endpoint ProfilesForMenu
class ProfilesMenu {
  final List<MenuSimpleModel> menusDefault;
  final List<ProfileWithMenusModel> profiles;

  ProfilesMenu({
    required this.menusDefault,
    required this.profiles,
  });

  factory ProfilesMenu.fromJson(Map<String, dynamic> json) {
    return ProfilesMenu(
      menusDefault: (json['menus_default'] as List? ?? [])
          .map((m) => MenuSimpleModel.fromJson(m as Map<String, dynamic>))
          .toList(),
      profiles: (json['profiles'] as List? ?? [])
          .map((p) => ProfileWithMenusModel.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Modelo simplificado de Menu contendo apenas ID e Title
class MenuSimpleModel {
  final int id;
  final String title;

  MenuSimpleModel({
    required this.id,
    required this.title,
  });

  factory MenuSimpleModel.fromJson(Map<String, dynamic> json) {
    return MenuSimpleModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
    );
  }
}

/// Modelo de Perfil que carrega a sua própria lista de menus simplificados
class ProfileWithMenusModel {
  final int id;
  final String name;
  final List<MenuSimpleModel> menus;

  ProfileWithMenusModel({
    required this.id,
    required this.name,
    required this.menus,
  });

  factory ProfileWithMenusModel.fromJson(Map<String, dynamic> json) {
    return ProfileWithMenusModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      menus: (json['menus'] as List? ?? [])
          .map((m) => MenuSimpleModel.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}