import 'package:oxdata/app/core/models/menu_item_model.dart';

class LoginResponse {
  final String token;
  final int profileId;
  final List<MenuItemModel> menus;

  LoginResponse({
    required this.token,
    required this.profileId,
    required this.menus,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'],
      profileId: json['profileId'],
      menus: (json['menus'] as List<dynamic>)
          .map((e) => MenuItemModel.fromJson(e))
          .toList(),
    );
  }
}