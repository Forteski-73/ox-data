import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oxdata/app/core/utils/device.dart';
import 'package:oxdata/app/core/services/inventory_service.dart';
import 'package:oxdata/app/core/models/inventory_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

class NewInventoryPopup extends StatefulWidget {
  const NewInventoryPopup({super.key});

  @override
  State<NewInventoryPopup> createState() => _NewInventoryPopupState();
}

class _NewInventoryPopupState extends State<NewInventoryPopup> {
  // Controladores para capturar os dados
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _sectorController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Data atual formatada
  final String _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    // Chama a função para carregar o ID assim que o popup abrir
    _loadInventoryCode();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _sectorController.dispose();
    super.dispose();
  }

  Future<String> getFileName() async {
    String idNumerico = await DeviceService.getDeviceFineNumber();
    return idNumerico;
  }

  // Função para carregar o código e atualizar o TextField
  Future<void> _loadInventoryCode() async {
    String code = await getFileName();
    setState(() {
      _codeController.text = code;
    });
  }

  Future<String> getDevice() async {
    String idNumerico = await DeviceService.getDeviceId();
    return idNumerico;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      elevation: 12,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView( // Garante que o teclado não quebre o layout
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_business,
                      color: Colors.indigo,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'NOVO INVENTÁRIO *',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Campo: Código do Inventário
              _buildLabel('Código do Inventário'),
              TextField(
                controller: _codeController,
                decoration: _inputDecoration('Ex: INV-2024'),
              ),
              const SizedBox(height: 15),

              // Campo: Data de Criação (Apenas leitura)
              _buildLabel('Data de Criação'),
              TextField(
                controller: TextEditingController(text: _currentDate),
                readOnly: true,
                decoration: _inputDecoration(''),
              ),
              const SizedBox(height: 15),

              // Campo: Nome do Inventário (Maiúsculas)
              _buildLabel('Nome Inventário'),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.characters,
                onChanged: (value) => _nameController.value = _nameController.value.copyWith(
                  text: value.toUpperCase(),
                ),
                decoration: _inputDecoration('NOME DO DEPÓSITO'),
              ),
              const SizedBox(height: 15),

              // Campo: Setor (Maiúsculas)
              _buildLabel('Setor'),
              TextField(
                controller: _sectorController,
                textCapitalization: TextCapitalization.characters,
                onChanged: (value) => _sectorController.value = _sectorController.value.copyWith(
                  text: value.toUpperCase(),
                ),
                decoration: _inputDecoration('SETOR LOGÍSTICO'),
              ),

              const SizedBox(height: 32),

              // Botões de Ação
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.indigo),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        await context.read<InventoryService>().setDecrementSequence();
                        Navigator.pop(context);    // fecha a tela
                      },
                      child: const Text('CANCELAR', style: TextStyle(fontSize: 16, color: Colors.indigo)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        final inventoryService = context.read<InventoryService>();
                        final userId = await _storage.read(key: 'username');
                        final inventory = InventoryModel(
                          inventCode:     _codeController.text.trim(),
                          inventName:     _nameController.text.trim(),
                          inventGuid:     await getDevice(), // ou outro GUID se você gerar depois
                          inventSector:   _sectorController.text.trim(),
                          inventCreated:  DateTime.now(),
                          inventUser:     userId,
                          inventStatus:   InventoryStatus.Iniciado,
                          inventTotal:    0,
                        );

                        await inventoryService.createOrUpdateInventory(inventory);

                        Navigator.pop(context);
                      },
                      child: const Text('CRIAR', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para labels
  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
      ),
    );
  }

  // Estilização comum dos inputs
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      
      // Borda quando o campo está habilitado, mas NÃO focado
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Colors.grey), // Cor da borda padrão
      ),

      // Borda quando o campo está focado (clicado)
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Colors.indigo, width: 2),
      ),

      // Borda quando o campo está DESABILITADO (Resolve o erro da data)
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Colors.grey), // Mesma cor do enabled
      ),

      // Borda genérica (fallback)
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}