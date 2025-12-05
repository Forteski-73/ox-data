import 'package:flutter/material.dart';
import 'package:oxdata/app/core/models/inventory_item.dart';

/*class InventoryPage extends StatelessWidget {
  final InventoryItem inventory;

  const InventoryPage({required this.inventory, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(inventory.title),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Data: ${inventory.date}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Status: ${inventory.status}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Registros: ${inventory.records}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Total de Itens: ${inventory.totalItems}', style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}*/


// -------------------------------------------------------------
// Novo Widget para o Card de Item de Contagem
// -------------------------------------------------------------
// -------------------------------------------------------------
// Novo Widget para o Card de Item de Contagem
// -------------------------------------------------------------

class _CountItemCard extends StatelessWidget {
  final InventoryCountItem countItem;

  const _CountItemCard({required this.countItem});

  // Método para formatar a quantidade: P: 5x10 Av: 2
  String _formatQuantity() {
    return 'P: ${countItem.stacks}x${countItem.itemsPerStack} Av: ${countItem.loose}';
  }

  @override
  Widget build(BuildContext context) {
    // A cor de fundo é opcional, mas ajuda a destacar o card.
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informações do Item (Centro)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Código do Unitizador (CX-220, PAL-001)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          countItem.unitizerCode,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Hora
                      Text(
                        countItem.time,
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Código e Nome do Item
                  Text(
                    '${countItem.itemCode} - ${countItem.itemName}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  // Quantidade detalhada (P: 5x10 Av: 2)
                  Text(
                    _formatQuantity(),
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),

                  Text(
                    '${countItem.itemCode} - ${countItem.itemName}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            
            // Coluna Direita (Total e Ações)
            // Removemos 'width: 100' para que o Container ocupe o mínimo de espaço necessário.
            Container(
              alignment: Alignment.topRight,
              child: IntrinsicHeight( // Força a altura a ser apenas o necessário para os filhos
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch, // Ocupa altura total
                  children: [
                    // Total (52 ou 20)
                    Container(
                      // Padding para separar o número dos ícones
                      padding: const EdgeInsets.only(right: 16.0, left: 8.0, top: 6.0), 
                      alignment: Alignment.center,
                      child: Text(
                        countItem.totalCount.toString(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    
                    // Separador (Vertical Divider)
                    const VerticalDivider(
                      width: 1, 
                      thickness: 1, 
                      indent: 0,
                      endIndent: 0,
                      color: Color(0xFFE0E0E0), // Cor cinza claro para o separador
                    ),
                    
                    // Ícones de Ação (Editar e Excluir)
                    Padding(
                      padding: const EdgeInsets.only(left: 10.0), // Espaço após o divisor
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center, // Centraliza os ícones verticalmente
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Ícone de Editar
                          GestureDetector(
                            onTap: () {
                              // Ação de Editar
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Editar: ${countItem.itemName}')));
                            },
                            child: const Icon(Icons.edit, size: 36, color: Color(0xFF909090)), // Cor mais neutra
                          ),
                          const SizedBox(height: 20), // Espaço entre os ícones
                          // Ícone de Excluir
                          GestureDetector(
                            onTap: () {
                              // Ação de Excluir
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Excluir: ${countItem.itemName}')));
                            },
                            child: const Icon(Icons.delete, size: 36, color: Color(0xFF909090)), // Cor mais neutra
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// -------------------------------------------------------------
// Página Principal (InventoryPage)
// -------------------------------------------------------------

class InventoryPage extends StatelessWidget {
  final InventoryItem inventory;

  InventoryPage({required this.inventory, super.key});

  // Dados de Contagem de Exemplo (Simulando a origem de dados)
  final List<InventoryCountItem> mockCountItems = [
    InventoryCountItem(
      unitizerCode: "CX-220",
      itemCode: "7891001",
      itemName: "Mouse Óptico USB",
      time: "08:54",
      totalCount: 52,
      stacks: 5,
      itemsPerStack: 10,
      loose: 2,
    ),
    InventoryCountItem(
      unitizerCode: "PAL-001",
      itemCode: "7891003",
      itemName: "Monitor LED 24pol",
      time: "08:54",
      totalCount: 20,
      stacks: 4,
      itemsPerStack: 5,
      loose: 0,
    ),
  ];

  // -------------------------------------------------------------
  // Widget de Cabeçalho (STATUS, TOTAL DE ITENS, Registros)
  // -------------------------------------------------------------
  Widget _buildHeader(BuildContext context) {
    Color statusColor = inventory.status == 'FECHADO' ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // TOTAL DE ITENS (Lado Esquerdo)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TOTAL DE ITENS', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text(inventory.totalItems.toString(),
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold)),
            ],
          ),
          
          // STATUS e Registros (Lado Direito)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  inventory.status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Registros
              Text('Registros', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text(inventory.records.toString(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar ajustada para o título dinâmico
      appBar: AppBar(
        title: Text(inventory.title), // Ex: Inventário Geral Jan/24
        backgroundColor: Colors.indigo,
      ),
      
      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Ação para adicionar uma nova contagem
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Adicionar nova contagem')),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      
      body: Column(
        children: [
          // Cabeçalho de Resumo
          _buildHeader(context),
          
          // Lista de Itens Contados
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: mockCountItems.length,
              itemBuilder: (context, index) {
                return _CountItemCard(countItem: mockCountItems[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
