// -----------------------------------------------------------
// app/core/models/user_model.dart
// -----------------------------------------------------------
class UserModel {

  final int id;

  final String user;

  final String account;

  final String? profileName;

  UserModel({
    required this.id,
    required this.user,
    required this.account,
    this.profileName,
  });

  factory UserModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return UserModel(
      id: json['id'] ?? 0,

      user: json['user'] ?? '',

      account: json['account'] ?? '',

      profileName: json['profileName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user,
      'account': account,
      'profileName': profileName,
    };
  }
}