class MenuItemModel {
  final String title;
  final String routeName;
  final String imagePath;

  MenuItemModel({
    required this.title,
    required this.routeName,
    required this.imagePath,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      title: json['title'],
      routeName: json['routeName'],
      imagePath: json['imagePath'],
    );
  }
}