// -----------------------------------------------------------
// app/core/models/profile_model.dart
// -----------------------------------------------------------
class ProfileModel {
  final int id;
  final String name;
  final String? description;
  final String? createdAt;

  ProfileModel({
    required this.id,
    required this.name,
    this.description,
    this.createdAt,
  });

  /// Converte o JSON do C# (que usa camelCase) para o objeto do Flutter
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt,
    };
  }
}