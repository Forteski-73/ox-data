import 'package:flutter/material.dart';

class NotasTab extends StatefulWidget {
  const NotasTab({super.key});

  @override
  State<NotasTab> createState() => _NotasTabState();
}

class _NotasTabState extends State<NotasTab> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<IconData> _icons = [
    Icons.add_circle_sharp,
    Icons.file_upload_sharp,
    Icons.file_download_sharp,
    Icons.receipt,
  ];

  final List<String> _labels = [
    'Novo',
    'Montar',
    'Receber',
    'Notas',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Text(
                'Conteúdo da Aba ${_labels[_selectedIndex]}',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
          ),
          SafeArea(
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_icons.length, (index) {
                  final isSelected = _selectedIndex == index;
                  return GestureDetector(
                    onTap: () => _onItemTapped(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _icons[index],
                            color: isSelected ? Colors.black : Colors.white, size: 28,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _labels[index],
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
