import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; 

// Importe seus modelos e serviços
// Assumimos que InventoryRecordModel e InventoryModel estão nos caminhos corretos.
import 'package:oxdata/app/core/models/inventory_model.dart'; 
import 'package:oxdata/app/core/models/inventory_record_model.dart';
import 'package:oxdata/app/core/services/inventory_service.dart';

import 'package:oxdata/app/views/pages/barcode_scanner_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// -------------------------------------------------------------
// Widget para o Card de Item de Contagem (Inalterado)
// -------------------------------------------------------------

class _CountItemCard extends StatelessWidget {
 final InventoryRecordModel recordItem;

 const _CountItemCard({required this.recordItem});

 // Método para formatar a quantidade: P: Pilhas x Itens Av: Avulsos
 String _formatQuantity() {
  final stacks = recordItem.inventQtdStack ?? 0;
  final itemsPerStack = recordItem.inventStandardStack ?? 0;
  final loose = recordItem.inventQtdIndividual ?? 0;
  
  return 'P: ${stacks}x${itemsPerStack} Av: ${loose}';
 }
 
 // Método para formatar a hora, assumindo que inventCreated é um DateTime
 String _formatTime() {
  if (recordItem.inventCreated != null) {
   // Formata apenas a hora
   return DateFormat('HH:mm').format(recordItem.inventCreated!.toLocal());
  }
  return '--:--';
 }

 @override
 Widget build(BuildContext context) {
  // Provider para ações como exclusão/edição
  final inventoryService = Provider.of<InventoryService>(context, listen: false);

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
           // Código do Unitizador (inventUnitizer)
           Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
             color: Colors.grey.shade200,
             borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
             recordItem.inventUnitizer ?? "N/A", 
             style: TextStyle(
               fontSize: 16,
               fontWeight: FontWeight.bold,
               color: Colors.grey.shade700),
            ),
           ),
           const SizedBox(width: 8),
           // Hora
           Text(
            _formatTime(), 
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
           ),
          ],
         ),
         const SizedBox(height: 4),
         // Código e Nome do Item (inventProduct - inventBarcode)
         Text(
          '${recordItem.inventProduct} - ${recordItem.inventBarcode ?? "Nome Desconhecido"}', 
          style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600),
         ),
         const SizedBox(height: 4),
         // Quantidade detalhada
         Text(
          _formatQuantity(), 
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
         ),
        ],
       ),
      ),
      
      // Coluna Direita (Total e Ações)
      Container(
       alignment: Alignment.topRight,
       child: IntrinsicHeight(
        child: Row(
         crossAxisAlignment: CrossAxisAlignment.stretch,
         children: [
          // Total
          Container(
           padding: const EdgeInsets.only(right: 16.0, left: 8.0, top: 6.0), 
           alignment: Alignment.center,
           child: Text(
            recordItem.inventTotal.toString(), // Total do Record
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
           color: Color(0xFFE0E0E0),
          ),
          
          // Ícones de Ação (Editar e Excluir)
          Padding(
           padding: const EdgeInsets.only(left: 10.0),
           child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
             // Ícone de Editar
             GestureDetector(
              onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('Editar: ${recordItem.inventProduct}')));
              },
              child: const Icon(Icons.edit, size: 36, color: Color(0xFF909090)),
             ),
             const SizedBox(height: 20),
             // Ícone de Excluir
             GestureDetector(
              onTap: () async {
               if (recordItem.id != null) {
                // Ação de exclusão
                await inventoryService.deleteInventoryRecord(recordItem.id!);
                ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('Registro ${recordItem.inventProduct} excluído!')));
               }
              },
              child: const Icon(Icons.delete, size: 36, color: Color(0xFF909090)),
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
// Página Principal (InventoryPage) - STATEFUL
// -------------------------------------------------------------

class InventoryPage extends StatefulWidget {
const InventoryPage({super.key});

@override
State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
 bool _isLoading = true;
  // Variável local para armazenar o inventário selecionado
 InventoryModel? _currentInventory; 

 @override
 void initState() {
  super.initState();
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
   _checkAndFetchRecords();
  });
 }

 Future<void> _checkAndFetchRecords() async {
  final inventoryService = context.read<InventoryService>();
  
  // 1. Tenta obter o inventário selecionado do serviço
  _currentInventory = inventoryService.selectedInventory;

  if (_currentInventory == null) {
   // Se não houver um inventário selecionado, talvez seja necessário buscar a lista
   // ou mostrar uma tela de erro/vazia. 
   // Por enquanto, apenas para evitar NullPointerException:
   debugPrint("Erro: Nenhum inventário selecionado no Provider.");
   if (mounted) {
    setState(() {
     _isLoading = false;
    });
   }
   return;
  }
  
  final records = inventoryService.inventoryRecords;

  // Define isLoading para garantir que o CircularProgressIndicator apareça
  if (mounted) {
   setState(() {
    _isLoading = true;
   });
  }

  // 🔑 Lógica de verificação e busca (agora usando _currentInventory.inventCode)
  if (records.isEmpty) {
   debugPrint("initState: Registros vazios. Buscando records para ${_currentInventory!.inventCode}");
   
   // Usa inventCode do InventoryModel obtido do Provider
   await inventoryService.fetchRecordsByInventCode(_currentInventory!.inventCode);

  } else {
   debugPrint("initState: Registros já carregados (${records.length}).");
  }
  
  // Finaliza o carregamento
  if (mounted) {
   setState(() {
    _isLoading = false;
   });
  }
 }

// -------------------------------------------------------------
 // Widget de Cabeçalho (STATUS, TOTAL DE ITENS, Registros)
 // -------------------------------------------------------------
 Widget _buildHeader(BuildContext context, InventoryModel inventory, int recordsCount) {
  // Acessa o status do InventoryModel e o converte para String
  final String statusText = inventory.inventStatus.name.toUpperCase();
  // Ajuste de cor baseado no status do ENUM
  Color statusColor = statusText == 'FINALIZADO' ? Colors.orange : Colors.green;

  // O totalItems agora deve vir de inventTotal do InventoryModel
  double totalItems = inventory.inventTotal ?? 0;


  return Container(
   padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 10.0, bottom: 4.0),
   decoration: BoxDecoration(
    color: Colors.white,
    border: Border(
     bottom: BorderSide(color: Colors.grey.shade300, width: 1),
    ),
   ),
   child: Column( // Alterado para Column para colocar o título acima
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
     // 🔑 NOVO: TÍTULO DO INVENTÁRIO (inventCode)
     Text(
      'INVENTÁRIO: ${inventory.inventCode}',
      style: const TextStyle(
       fontSize: 22, 
       fontWeight: FontWeight.bold,
       color: Colors.black87
      ),
     ),
     const SizedBox(height: 12),
     
     // Conteúdo Original (TOTAL DE ITENS, STATUS, REGISTROS)
     Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
       // TOTAL DE ITENS (Lado Esquerdo)
       Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         Text('TOTAL DE ITENS', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
         // Usa inventTotal do InventoryModel
         Text(totalItems.toString(),
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
           statusText, // Status vindo do ENUM
           style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: statusColor,
           ),
          ),
         ),
         const SizedBox(height: 8),
         // Registros (Contagem dinâmica da lista de records)
         Text('Registros', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
         Text(recordsCount.toString(), 
           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
       ),
      ],
     ),
    ],
   ),
  );
 }

 @override
 Widget build(BuildContext context) {
  // 2. Obtém o inventário selecionado e os registros usando watch
  final inventoryService = context.watch<InventoryService>();
  final InventoryModel? currentInventory = inventoryService.selectedInventory;
  final records = inventoryService.inventoryRecords;
  
  // 3. Se o inventário selecionado for nulo, mostra um placeholder
  if (currentInventory == null) {
   return Scaffold(
    appBar: AppBar(
     title: const Text('Inventário'),
     backgroundColor: Colors.blue.shade700,
     foregroundColor: Colors.white,
    ),
    body: const Center(
     child: Padding(
      padding: EdgeInsets.all(32.0),
      child: Text(
       'Nenhum inventário selecionado. Por favor, selecione um na lista.',
       textAlign: TextAlign.center,
       style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
     ),
    ),
   );
  }

  // 4. Se o inventário estiver disponível, renderiza a tela normalmente
  return Scaffold(
   /*floatingActionButton: FloatingActionButton(
    onPressed: () {
     // Ação para adicionar uma nova contagem
     ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Adicionar nova contagem')),
     );
    },
    backgroundColor: Colors.blue,
    child: const Icon(Icons.add, color: Colors.white),
   ),*/
   
   body: Column(
    children: [
     // Cabeçalho de Resumo (passa o inventário obtido do Provider)
     _buildHeader(context, currentInventory, records.length), 
     
     // Lista de Itens Contados
     Expanded(
      // Mostra o indicador de progresso
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        // Se não estiver carregando e a lista estiver vazia
        : records.isEmpty
          ? Center(
            child: Text(
             currentInventory.inventStatus.name.toUpperCase() == 'FINALIZADO'
              ? 'O Inventário está Finalizado e não possui registros.'
              : 'Nenhum registro de contagem encontrado. Use o FAB para adicionar.',
             textAlign: TextAlign.center,
             style: TextStyle(color: Colors.grey.shade600),
            ),
           )
          // Se não estiver carregando e houver registros
          : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            itemCount: records.length, 
            itemBuilder: (context, index) {
             return _CountItemCard(recordItem: records[index]); 
            },
           ),
     ),
    ],
   ),
  );
 }
}




/*
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; 
// Importe seus modelos e serviços
import 'package:oxdata/app/core/models/inventory_item.dart'; 
import 'package:oxdata/app/core/models/inventory_record_model.dart';
import 'package:oxdata/app/core/services/inventory_service.dart';

// -------------------------------------------------------------
// Novo Widget para o Card de Item de Contagem
// -------------------------------------------------------------

class _CountItemCard extends StatelessWidget {
  // Agora recebe o modelo real do backend
  final InventoryRecordModel recordItem;

  const _CountItemCard({required this.recordItem});

  // Método para formatar a quantidade: P: Pilhas x Itens Av: Avulsos
  String _formatQuantity() {
    final stacks = recordItem.inventQtdStack ?? 0;
    final itemsPerStack = recordItem.inventStandardStack ?? 0;
    final loose = recordItem.inventQtdIndividual ?? 0;
    
    return 'P: ${stacks}x${itemsPerStack} Av: ${loose}';
  }
  
  // Método para formatar a hora, assumindo que recordDate é um DateTime
  String _formatTime() {
    if (recordItem.inventCreated != null) {
      // Formata apenas a hora
      return DateFormat('HH:mm').format(recordItem.inventCreated!.toLocal());
    }
    return '--:--';
  }

  @override
  Widget build(BuildContext context) {
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
                          recordItem.inventUnitizer ?? "N/A", // Dados do Record
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Hora
                      Text(
                        _formatTime(), // Hora formatada
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Código e Nome do Item
                  Text(
                    '${recordItem.inventProduct ?? "Sem Código"} - ${recordItem.inventBarcode ?? "Nome Desconhecido"}', // Dados do Record
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  // Quantidade detalhada (P: 5x10 Av: 2)
                  Text(
                    _formatQuantity(), // Quantidade formatada
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            
            // Coluna Direita (Total e Ações)
            Container(
              alignment: Alignment.topRight,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Total
                    Container(
                      padding: const EdgeInsets.only(right: 16.0, left: 8.0, top: 6.0), 
                      alignment: Alignment.center,
                      child: Text(
                        recordItem.inventTotal.toString(), // Total do Record
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
                      color: Color(0xFFE0E0E0),
                    ),
                    
                    // Ícones de Ação (Editar e Excluir)
                    Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Ícone de Editar
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Editar: ${recordItem.inventProduct}')));
                            },
                            child: const Icon(Icons.edit, size: 36, color: Color(0xFF909090)),
                          ),
                          const SizedBox(height: 20),
                          // Ícone de Excluir
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Excluir: ${recordItem.inventProduct}')));
                            },
                            child: const Icon(Icons.delete, size: 36, color: Color(0xFF909090)),
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
  
  // -------------------------------------------------------------
  // Widget de Cabeçalho (STATUS, TOTAL DE ITENS, Registros)
  // -------------------------------------------------------------
  Widget _buildHeader(BuildContext context, int recordsCount) {
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
              Text(recordsCount.toString(), // Contagem DINÂMICA
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🔑 CONECTANDO AO PROVIDER: O widget escuta o InventoryService e reconstrói 
    // quando a lista `inventoryRecords` muda.
    final records = context.watch<InventoryService>().inventoryRecords;
    
    return Scaffold(
      
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
          _buildHeader(context, records.length), // Passa o número real de registros
          
          // Lista de Itens Contados
          Expanded(
            child: records.isEmpty
                ? const Center(child: Text('Nenhum registro de contagem encontrado.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    itemCount: records.length, // Usando a lista do Provider
                    itemBuilder: (context, index) {
                      return _CountItemCard(recordItem: records[index]); // Passando o Record Model
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

*/