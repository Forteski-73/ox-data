class MenuItemModel {
  final String title;
  final String routeName;
  final String imagePath;
  final bool   isReadOnly;

  MenuItemModel({
    required this.title,
    required this.routeName,
    required this.imagePath,
    required this.isReadOnly,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      title:      json['title'],
      routeName:  json['routeName'],
      imagePath:  json['imagePath'],
      isReadOnly: json['isReadOnly'],
    );
  }
}