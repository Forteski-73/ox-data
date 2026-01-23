import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; 

// Importe seus modelos e serviços
// Assumimos que InventoryRecordModel e InventoryModel estão nos caminhos corretos.
import 'package:oxdata/app/core/models/inventory_model.dart'; 
import 'package:oxdata/app/core/models/inventory_record_model.dart';
import 'package:oxdata/app/core/services/inventory_service.dart';
import 'package:oxdata/app/core/services/load_service.dart';
import 'package:oxdata/app/core/models/dto/inventory_record_input.dart';

// -------------------------------------------------------------
// Widget para o Card de Item de Contagem (Inalterado)
// -------------------------------------------------------------

class _CountItemCard extends StatelessWidget {
  final InventoryRecordModel recordItem;
  final InventoryModel inventory;

  const _CountItemCard({required this.recordItem, required this.inventory,});

  String _formatTime() {
    if (recordItem.inventCreated != null) {
      return DateFormat('HH:mm').format(recordItem.inventCreated!.toLocal());
    }
    return '--:--';
  }

  @override
  Widget build(BuildContext context) {

    final inventoryService = Provider.of<InventoryService>(context, listen: false);
    final Color statusColor = inventory.inventStatus == InventoryStatus.Finalizado ? Colors.green : Colors.orange;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra lateral colorida (Indigo para registros de contagem)
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
              ),
              
              // Conteúdo Central
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only( left: 10, top: 10, right: 2, bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Descrição com Scroll Horizontal
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          '${recordItem.productDescription}',
                          softWrap: false,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      
                      // Código e Badge de Hora
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${recordItem.inventProduct}  •  ${recordItem.inventBarcode?.replaceFirst(RegExp(r'^0+'), '') ?? ""}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                          // Badge de Hora (seguindo o estilo do status do outro card)
                          _buildTimeBadge(_formatTime()),
                        ],
                      ),
                      
                      const SizedBox(height: 10),
                      const Divider(height: 2, color: Color(0xFFF1F1F1)),
                      const SizedBox(height: 6),
                      
                      // Seção de Quantidade
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "TOTAL CONTADO:",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            formatQty(recordItem.inventTotal),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Coluna de Ações
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ColorChangingButton(
                      size: 45,
                      icon: Icons.edit_rounded,
                      onPressed: () {

                        //context.read<InventoryService>().setSelectedInventory(inventory);
                        //context.read<InventoryService>().fetchRecordsByInventCode(inventory.inventCode);

                      final input = InventoryRecordInput(
                        id: recordItem.id,
                        unitizer: recordItem.inventUnitizer ?? '',
                        position: recordItem.inventLocation ?? '',
                        product: recordItem.inventProduct,
                        qtdPorPilha: recordItem.inventStandardStack?.toDouble(),
                        numPilhas: recordItem.inventQtdStack?.toDouble(),
                        qtdAvulsa: recordItem.inventQtdIndividual,
                      );

                        context.read<InventoryService>().updateDraft(input);
                        context.read<LoadService>().setPage(1);
        
                      },
                    ),
                    const SizedBox(height: 8),
                    _ColorChangingButton(
                      size: 45,
                      icon: Icons.delete_forever_rounded,
                      onPressed: () async {
                        if (recordItem.id != null) {
                          await inventoryService.deleteInventoryRecord(recordItem.id!);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para a hora (seguindo o padrão visual do _buildStatusBadge)
  Widget _buildTimeBadge(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time, size: 12, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            time,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ],
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
  final String statusText = inventory.inventStatus.name.toUpperCase();
  Color statusColor = statusText == InventoryStatus.Finalizado ? Colors.orange : Colors.green;

  // O totalItems agora deve vir de inventTotal do InventoryModel
  double totalItems = inventory.inventTotal ?? 0;


  return Container(
   padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 5.0, bottom: 5.0),
   decoration: BoxDecoration(
    color: Colors.white,
    border: Border(
     bottom: BorderSide(color: Colors.grey.shade300, width: 1),
    ),
   ),
   child: Column( // Alterado para Column para colocar o título acima
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // TÍTULO DO INVENTÁRIO (inventCode)
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Empurra um para cada lado
        crossAxisAlignment: CrossAxisAlignment.baseline,   // Alinha as bases do texto
        textBaseline: TextBaseline.alphabetic, 
        children: [
          // LADO ESQUERDO: Nome do Inventário
          Text(
            inventory.inventName ?? '',
            style: const TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold, 
              color: Colors.black87,
            ),
          ),
          
          // LADO DIREITO: Código do Inventário
          Text(
            inventory.inventCode ?? '',
            style: const TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.normal, 
              color: Colors.black54,
            ),
          ),
        ],
      ),
     const SizedBox(height: 6),
     
     // Conteúdo Original (TOTAL DE ITENS, STATUS, REGISTROS)
     Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
       // TOTAL DE ITENS (Lado Esquerdo)
       Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         Text('TOTAL DE ITENS', style: TextStyle(fontSize: 14, color: Colors.grey.shade800)),
         // Usa inventTotal do InventoryModel
         Text(formatQty(totalItems),
           style: const TextStyle(
            fontSize: 33, fontWeight: FontWeight.bold)),
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
            color: statusColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: statusColor.withOpacity(0.2)),
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
         Text('Contagens', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8.8),
            itemCount: records.length, 
            itemBuilder: (context, index) {
             return _CountItemCard(recordItem: records[index], inventory: currentInventory); 
            },
           ),
     ),
    ],
   ),
  );
 }
}

// -------------------------------------------------------------------
// WIDGET REUTILIZÁVEL: _ColorChangingButton
// -------------------------------------------------------------------
class _ColorChangingButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? color;

  const _ColorChangingButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.size = 54,
    this.color,
  }) : super(key: key);

  @override
  State<_ColorChangingButton> createState() => __ColorChangingButtonState();
}

class __ColorChangingButtonState extends State<_ColorChangingButton> {
  late Color _containerColor;

  final Color _defaultColor = const Color(0xFFE3F2FD);
  final Color _darkerColor = const Color.fromARGB(255, 187, 211, 251);
  final Color _primaryIconColor = const Color(0xFF3F51B5);

  @override
  void initState() {
    super.initState();
    _containerColor = widget.color ?? _defaultColor;
  }

  // Função que faz a "piscadinha"
  void _handleTap() async {
    if (widget.onPressed == null) return;

    setState(() {
      // Escurece a cor ao tocar
      _containerColor = widget.color != null 
          ? widget.color!.withOpacity(0.7) 
          : _darkerColor;
    });

    // Pequeno delay para o olho humano perceber a mudança
    await Future.delayed(const Duration(milliseconds: 150));

    if (mounted) {
      setState(() {
        _containerColor = widget.color ?? _defaultColor;
      });
    }

    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100), // Transição rápida
        height: widget.size,
        width: widget.size,
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey[200] : _containerColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(
            widget.icon,
            color: isDisabled 
                ? Colors.grey[400] 
                : (widget.color != null ? Colors.white : _primaryIconColor),
            // Aumentado de 0.55 para 0.7 para o ícone ficar maior
            size: widget.size * 0.7, 
          ),
        ),
      ),
    );
  }
}

  String formatQty(double? value) {
    if (value == null) return "0";
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toString();
  }