import 'package:flutter/material.dart';
import 'package:oxdata/app/views/inventory/inventory_page.dart';
import 'package:oxdata/app/core/models/inventory_item.dart';

  // Widget do cartão de inventário
  class _InventoryCard extends StatelessWidget {
    final InventoryItem item;

    const _InventoryCard({required this.item});

    @override
    Widget build(BuildContext context) {
      Color statusColor = item.status == 'FECHADO' ? Colors.grey : Colors.green;

      return InkWell(
        borderRadius: BorderRadius.circular(8.0), // combina com o Card
        onTap: () {
          // Navega para a página de detalhes passando o inventário
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InventoryPage(inventory: item),
            ),
          );
        },
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          elevation: 2,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.date,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Registros', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                        Text(
                          item.records.toString(),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ],
                    ),
                    const SizedBox(width: 32),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Itens', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                        Text(
                          item.totalItems.toString(),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
  }


// Classe Principal
class SearchInventoryPage extends StatelessWidget {
  SearchInventoryPage({super.key});

  // Dados de Exemplo
  final List<InventoryItem> mockInventories = [
    InventoryItem(
      title: "Inventário Geral Jan/24",
      date: "15/01/2024",
      status: "FECHADO",
      records: 2,
      totalItems: 72,
    ),
    InventoryItem(
      title: "Inventário Cicl. Fev/24",
      date: "28/02/2024",
      status: "EM ANDAMENTO",
      records: 15,
      totalItems: 120,
    ),
    InventoryItem(
      title: "Inventário 2023",
      date: "31/12/2023",
      status: "FECHADO",
      records: 1,
      totalItems: 980,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Usa um Scaffold dentro do Container para poder usar o FloatingActionButton
    return Scaffold(
      backgroundColor: Colors.transparent, // Mantém a transparência para ver o fundo do PageView
      
      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Ação para adicionar novo inventário
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Adicionar novo inventário pressionado!')),
          );
        },
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      
      // Corpo Principal da Lista
      body: Column(
        children: [
          // Barra de Pesquisa (Exemplo de TextField com ícone)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Pesquisar inventários...',
                filled: true,
                fillColor: Colors.white,
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 15,
                ),
                prefixIcon: const Icon(Icons.search, size: 22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,             
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
              onChanged: (value) {
                // Lógica de filtro
              },
            ),
          ),
          
          // Lista de Inventários (Ocupa o espaço restante)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              itemCount: mockInventories.length,
              itemBuilder: (context, index) {
                return _InventoryCard(item: mockInventories[index]);
              },
              
            ),
          ),
        ],
      ),
    );
  }
}