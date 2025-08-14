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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtrar Por:'),
        backgroundColor: Colors.blueAccent,
      ),
      body: ListView(
        children: filterDisplayNames.keys.map((key) {
          final isSelected = key == currentFilterType;
          return ListTile(
            title: Text(
              filterDisplayNames[key] ?? key,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blueAccent : Colors.black,
              ),
            ),
            trailing: isSelected ? const Icon(Icons.check, color: Colors.blueAccent) : null,
            onTap: () {
              onFilterSelected(key);
              Navigator.of(context).pop(); // Volta para a página anterior
            },
          );
        }).toList(),
      ),
    );
  }
}


/*
// app/core/pages/filter_options_page.dart (ou onde você o tenha)
import 'package:flutter/material.dart';

class FilterOptionsPage extends StatefulWidget {
  final Map<String, String> filterDisplayNames;
  final String currentFilterType;
  final Function(String, String) onFilterSelected;

  const FilterOptionsPage({
    Key? key,
    required this.filterDisplayNames,
    required this.currentFilterType,
    required this.onFilterSelected,
  }) : super(key: key);

  @override
  _FilterOptionsPageState createState() => _FilterOptionsPageState();
}

class _FilterOptionsPageState extends State<FilterOptionsPage> {
  String? _selectedFilterKey;

  @override
  void initState() {
    super.initState();
    _selectedFilterKey = widget.currentFilterType;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FILTRAR POR:'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: widget.filterDisplayNames.keys.map((key) {
            final isSelected = key == _selectedFilterKey;
            return Column(
              children: [
                ListTile(
                  title: Text(
                    widget.filterDisplayNames[key] ?? key,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.blueAccent : Colors.black,
                    ),
                  ),
                  trailing: isSelected 
                      ? const Icon(Icons.arrow_drop_up, color: Colors.blueAccent) 
                      : const Icon(Icons.arrow_drop_down, color: Colors.black),
                  onTap: () {
                    setState(() {
                      _selectedFilterKey = isSelected ? null : key;
                    });
                  },
                ),
                if (isSelected)
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                          child: Text(
                            'Escolha o Resultado:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        _buildResultListTile('Resultado 1', key),
                        _buildResultListTile('Resultado 2', key),
                        _buildResultListTile('Resultado 3', key),
                      ],
                    ),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // Método auxiliar para construir os ListTiles de resultado
  Widget _buildResultListTile(String resultName, String filterKey) {
    return ListTile(
      title: Text(resultName),
      onTap: () {
        widget.onFilterSelected(filterKey, resultName);
        Navigator.of(context).pop();
      },
    );
  }
}

*/