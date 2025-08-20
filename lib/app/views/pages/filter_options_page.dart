import 'package:oxdata/app/core/widgets/app_bar.dart';
import 'package:flutter/material.dart';

class FilterOptionsPage extends StatelessWidget {
  final Map<String, String> filterDisplayNames;
  final String currentFilterType;
  final Function(String) onFilterSelected;

  const FilterOptionsPage({
    Key? key,
    required this.filterDisplayNames,
    required this.currentFilterType,
    required this.onFilterSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final keys = filterDisplayNames.keys.toList();

    return Scaffold(
      appBar: const AppBarCustom(title: 'Filtrar Por'),
      body: ListView.builder(
        itemCount: keys.length,
        itemBuilder: (context, index) {
          final key = keys[index];
          final isSelected = key == currentFilterType;
          
          return Column(
            children: [
              ListTile(
                tileColor: isSelected 
                ? Colors.green.withOpacity(0.2)
                : null,
                title: Text(
                  filterDisplayNames[key] ?? key,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: Colors.black,
                  ),
                ),
                trailing: isSelected ? const Icon( Icons.check, color: Color.fromARGB(255, 100, 240, 170), size: 46,) : null,
                onTap: () {
                  onFilterSelected(key);
                  Navigator.of(context).pop();
                },
              ),
              Divider(
                height: 1,
                color: Colors.grey[400],
              ),
            ],
          );
        },
      ),
    );
  }
}