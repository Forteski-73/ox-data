import 'package:flutter/material.dart';
// -----------------------------------------------------------
// app/core/models/menu_options.dart
// -----------------------------------------------------------
/// Uma classe de dados para encapsular as informações de um item de menu.
class MenuOption {
  final String title;
  final String routeName;
  final IconData? icon;
  final String? imagePath;

  const MenuOption({
    required this.title,
    required this.routeName,
    this.icon,
    this.imagePath,
  });
}