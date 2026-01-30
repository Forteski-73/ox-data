import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:oxdata/app/core/utils/device.dart';
import 'package:oxdata/app/core/services/inventory_service.dart';
import 'package:oxdata/app/core/models/inventory_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/services/message_service.dart';

class NewInventoryPopup extends StatefulWidget {
  const NewInventoryPopup({super.key});

  @override
  State<NewInventoryPopup> createState() => _NewInventoryPopupState();
}

class _NewInventoryPopupState extends State<NewInventoryPopup> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _sectorController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Controle manual para não validar ao carregar a tela
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;
  
  final String _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
  final FocusNode _nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadInventoryCode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _sectorController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadInventoryCode() async {
    String code = await DeviceService.getDeviceFineNumber();
    setState(() => _codeController.text = code);
  }

  Future<void> _handleSave() async {
    setState(() => _autoValidate = AutovalidateMode.onUserInteraction);

    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    final loading = context.read<LoadingService>();

    try {
      loading.show();

      final inventoryService = context.read<InventoryService>();
      final userId = await _storage.read(key: 'username');
      final deviceGuid = await DeviceService.getDeviceId();

      final inventory = InventoryModel(
        inventCode: _codeController.text.trim(),
        inventName: _nameController.text.trim().toUpperCase(),
        inventGuid: deviceGuid,
        inventSector: _sectorController.text.trim().toUpperCase(),
        inventCreated: DateTime.now(),
        inventUser: userId,
        inventStatus: InventoryStatus.Iniciado,
        inventTotal: 0,
      );

      await inventoryService.createOrUpdateInventory(inventory);
      MessageService.showSuccess("Inventário ${inventory.inventName} criado com sucesso!");
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      MessageService.showError('Erro ao criar o inventário: $e');
    } finally {
      loading.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        elevation: 12,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            autovalidateMode: _autoValidate,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),

                  _buildModernField(
                    label: 'Código do Inventário',
                    controller: _codeController,
                    enabled: false, 
                  ),
                  const SizedBox(height: 16),
                  
                  _buildModernField(
                    label: 'Data de Criação',
                    controller: TextEditingController(text: _currentDate),
                    enabled: false, 
                  ),
                  const SizedBox(height: 16),

                  _buildModernField(
                    label: 'Nome Inventário',
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) => v == null || v.isEmpty ? '' : null,
                    onClear: () => _nameController.clear(),
                  ),
                  const SizedBox(height: 16),

                  _buildModernField(
                    label: 'Setor',
                    controller: _sectorController,
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) => v == null || v.isEmpty ? '' : null,
                    onClear: () => _sectorController.clear(),
                    onSubmitted: (_) => _handleSave(),
                  ),

                  const SizedBox(height: 32),
                  _buildActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.post_add_outlined, color: Colors.indigo, size: 28),
        ),
        const SizedBox(width: 12),
        const Text(
          'NOVO INVENTÁRIO',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildModernField({
    required String label,
    required TextEditingController controller,
    FocusNode? focusNode,
    bool enabled = true,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    VoidCallback? onClear,
    void Function(String)? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      validator: validator,
      textCapitalization: textCapitalization,
      onFieldSubmitted: onSubmitted,
      onTapOutside: (_) => focusNode?.unfocus(),
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: enabled ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        errorStyle: const TextStyle(height: 0, fontSize: 0), 
        
        suffixIcon: onClear != null && enabled
            ? ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) => value.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: onClear,
                      )
                    : const SizedBox.shrink(),
              )
            : null,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        // Borda azul padrão quando o campo ganha foco ao abrir a tela
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Colors.indigo, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        // Garante que se tiver erro mas clicar no campo ele volta a ser azul
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Colors.indigo, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Colors.indigo),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.indigo)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _handleSave,
            child: const Text('CRIAR', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}