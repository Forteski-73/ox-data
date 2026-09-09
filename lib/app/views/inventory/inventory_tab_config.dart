import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oxdata/app/core/models/dto/device_inventory_guid_model.dart';
import 'package:oxdata/app/core/models/dto/inventory_header_model.dart';
import 'package:oxdata/app/core/services/device_service.dart';
import 'package:oxdata/app/core/services/inventory_service.dart';
import 'package:oxdata/app/core/services/message_service.dart';
import 'package:oxdata/app/core/utils/device.dart' as device_utils;
import 'package:flutter_spinkit/flutter_spinkit.dart';

/// Aba "Devices" da InventoryAdmPage.
///
/// Busca no endpoint `Device/InventoryGuid` todos os devices vinculados
/// a um inventory_guid e lista o resultado em formato de grid
/// (tabela no desktop / cards no mobile), seguindo o mesmo padrão
/// visual da InventoryTabChkDiff. Permite buscar por nome, editar o
/// customDeviceName, ativar/desativar o device e trocar o cabeçalho de
/// inventário (`inventory_header`) vinculado ao `inventory_guid` do
/// device, refletindo cada alteração via `PUT Device/Update/{id}`
/// (campo opcional `inventHeaderId`).
class InventoryTabConfig extends StatefulWidget {
  const InventoryTabConfig({super.key});

  @override
  State<InventoryTabConfig> createState() => _InventoryTabConfigState();
}

class _InventoryTabConfigState extends State<InventoryTabConfig> {
  bool _isLoading = false;
  List<DeviceInventoryGuidModel> _devices = [];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // Ids em processo de atualização (evita toques duplicados durante o PUT).
  final Set<int> _updatingIds = {};

  // Edição inline do nome do device: apenas uma linha por vez.
  int? _editingId;
  final TextEditingController _editController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDevices();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _editController.dispose();
    super.dispose();
  }

  Future<void> _fetchDevices() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final deviceService = context.read<DeviceService>();
      await deviceService.fetchDevicesWithInventoryGuid();

      if (!mounted) return;

      setState(() {
        _devices = deviceService.inventoryGuidDevices;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Erro ao buscar devices: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        MessageService.showError("Erro ao carregar a lista de devices.");
      }
    }
  }

  /// Filtra por nome (device/usuário/inventário) e ordena com os ativos
  /// sempre primeiro, preservando a ordem original dentro de cada grupo.
  List<DeviceInventoryGuidModel> get _visibleDevices {
    final query = _searchQuery.trim().toLowerCase();

    final filtered = query.isEmpty
        ? _devices
        : _devices.where((d) {
            final deviceName = (d.customDeviceName ?? d.deviceName ?? '').toLowerCase();
            final username = d.username.toLowerCase();
            final inventName = (d.header?.inventName ?? '').toLowerCase();
            return deviceName.contains(query) || username.contains(query) || inventName.contains(query);
          }).toList();

    final active = filtered.where((d) => d.isActive).toList();
    final inactive = filtered.where((d) => !d.isActive).toList();
    return [...active, ...inactive];
  }

  Future<void> _updateDevice(
    DeviceInventoryGuidModel device, {
    String? customDeviceName,
    required bool isActive,
    InventoryHeaderModel? header,
  }) async {
    setState(() => _updatingIds.add(device.id));

    final deviceService = context.read<DeviceService>();
    final success = await deviceService.updateDeviceInventoryGuid(
      id: device.id,
      customDeviceName: customDeviceName,
      isActive: isActive,
      header: header,
    );

    if (!mounted) return;

    setState(() {
      _updatingIds.remove(device.id);
      _devices = deviceService.inventoryGuidDevices;
    });

    if (success) {
      MessageService.showSuccess("Device atualizado com sucesso!");
    } else {
      MessageService.showError("Erro ao atualizar o device.");
    }
  }

  /// Abre um seletor com os cabeçalhos de inventário disponíveis e, se o
  /// usuário escolher um diferente do atual, salva via `_updateDevice`
  /// (que envia `inventHeaderId` no PUT Device/Update/{id}).
  Future<void> _pickHeader(DeviceInventoryGuidModel device) async {
    final inventoryService = context.read<InventoryService>();

    if (inventoryService.inventoryHeaders.isEmpty) {
      await inventoryService.fetchRecentInventoryHeaders();
    }

    if (!mounted) return;

    final headers = inventoryService.inventoryHeaders;
    if (headers.isEmpty) {
      MessageService.showError("Nenhum cabeçalho de inventário disponível.");
      return;
    }

    final selected = await showDialog<InventoryHeaderModel>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Material(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          elevation: 12,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPickHeaderTitle(),
                  const SizedBox(height: 8),
                  Text(
                    "DEVICE: ${device.customDeviceName ?? device.deviceName ?? device.guid}",
                    style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Selecione o inventário para vincular a este device:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: headers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final header = headers[index];
                          return _buildHeaderOptionTile(
                            sheetContext: dialogContext,
                            header: header,
                            isSelected: device.header?.id == header.id,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.indigo),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('CANCELAR', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (selected == null || selected.id == device.header?.id) return;

    await _updateDevice(
      device,
      customDeviceName: device.customDeviceName,
      isActive: device.isActive,
      header: selected,
    );

    await _syncLocalPrefsIfOwnDevice(device, selected);
  }

  /// Se o device editado é o próprio device local (o mesmo que roda este
  /// app), atualiza também as preferências salvas no celular — sem isso,
  /// elas só seriam corrigidas na próxima vez que `initializeDeviceId()`
  /// rodasse.
  Future<void> _syncLocalPrefsIfOwnDevice(
    DeviceInventoryGuidModel device,
    InventoryHeaderModel newHeader,
  ) async {
    final myGuid = await device_utils.DeviceService.getExistingDeviceId();
    if (myGuid == null || myGuid.toLowerCase() != device.guid.toLowerCase()) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('inventory_header', newHeader.salesChannelOnly);
    await prefs.setString('inventory_header_name', newHeader.inventName);
    await prefs.setInt('inventory_header_id', newHeader.id);
  }

  /// Cabeçalho do popup de seleção de inventário (`_pickHeader`), no mesmo
  /// padrão visual dos demais popups da página (ícone circular + título
  /// em caixa alta, como em "EXPORTAR INVENTÁRIO" e "NOVO INVENTÁRIO").
  Widget _buildPickHeaderTitle() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.inventory_2_rounded, color: Colors.indigo, size: 28),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'LISTA DE INVENTÁRIOS',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  /// Uma opção da lista de inventários no seletor (`_pickHeader`), no
  /// mesmo estilo de "cartão" com borda usado nos FilterChip de
  /// DownloadInventoryDialog.
  Widget _buildHeaderOptionTile({
    required BuildContext sheetContext,
    required InventoryHeaderModel header,
    required bool isSelected,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.pop(sheetContext, header),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo.withOpacity(0.1) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.indigo : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    header.inventName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.indigo : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (header.inventDescription.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      header.inventDescription,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: Colors.indigo, size: 20),
          ],
        ),
      ),
    );
  }

  /// Mesmo padrão visual do campo de pesquisa (fundo, borda e cores),
  /// usado na edição inline do nome do device.
  InputDecoration _editFieldDecoration() {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(
          color: Colors.indigo,
          width: 1,
        ),
      ),
    );
  }

  void _startEditingName(DeviceInventoryGuidModel device) {
    _editController.text = device.customDeviceName ?? device.deviceName ?? '';
    setState(() => _editingId = device.id);
  }

  Future<void> _commitEditingName(DeviceInventoryGuidModel device) async {
    if (_editingId != device.id) return;

    final newName = _editController.text.trim();
    setState(() => _editingId = null);

    if (newName.isEmpty || newName == (device.customDeviceName ?? device.deviceName)) {
      return;
    }

    await _updateDevice(
      device,
      customDeviceName: newName,
      isActive: device.isActive,
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleDevices;
    final bool isDesktop = MediaQuery.of(context).size.width >= 900;

    return Column(
      children: [
        _buildSearchField(isDesktop),
        Expanded(
          child: _isLoading
              ? const Center(child: SpinKitThreeBounce(color: Colors.indigo, size: 30.0))
              : visible.isEmpty
                  ? _buildEmptyState()
                  : Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1400),
                        child: isDesktop
                            ? _buildWebGridTable(visible)
                            : _buildMobileCardsList(visible),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildSearchField(bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 16.0 : 10.0, vertical: 14.0),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Buscar..',
                      hintStyle: TextStyle(
                        color: Colors.blueGrey[300],
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Colors.indigo,
                        size: 22,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              style: IconButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(
                          color: Colors.indigo,
                          width: 1,
                        ),
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.indigo),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(50, double.infinity),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                    ),
                  ),
                  tooltip: 'Atualizar',
                  onPressed: _isLoading ? null : _fetchDevices,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebGridTable(List<DeviceInventoryGuidModel> list) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFF1F5F9),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    "USUÁRIO",
                    style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    "DEVICE",
                    style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "PLATAFORMA",
                    style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    "GUID",
                    style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                ),
                SizedBox(
                  width: 130,
                  child: Text(
                    "INVENTÁRIO",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569), fontSize: 11),
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: Text(
                    "ATIVO",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = list[index];
                final isUpdating = _updatingIds.contains(item.id);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          item.username,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.indigo),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: _editingId == item.id
                            ? TextField(
                                controller: _editController,
                                autofocus: true,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                decoration: _editFieldDecoration(),
                                onSubmitted: (_) => _commitEditingName(item),
                                onTapOutside: (_) => _commitEditingName(item),
                              )
                            : InkWell(
                                onTap: isUpdating ? null : () => _startEditingName(item),
                                child: Text(
                                  item.customDeviceName ?? item.deviceName ?? '',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          item.platform,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          item.guid,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                      SizedBox(
                        width: 130,
                        child: Center(
                          child: InkWell(
                            onTap: isUpdating ? null : () => _pickHeader(item),
                            child: Text(
                              item.header?.inventName ?? '—',
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.indigo,
                                decoration: TextDecoration.underline,
                                decorationColor: Color(0xFFE2E8F0),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 110,
                        child: Center(
                          child: Switch(
                            value: item.isActive,
                            activeColor: Colors.green,
                            onChanged: isUpdating
                                ? null
                                : (value) => _updateDevice(
                                      item,
                                      customDeviceName: item.customDeviceName,
                                      isActive: value,
                                    ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCardsList(List<DeviceInventoryGuidModel> list) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final statusColor = item.isActive ? Colors.green : Colors.grey;
        final isUpdating = _updatingIds.contains(item.id);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
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
                children: [
                  Container(
                    width: 6,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _editingId == item.id
                                    ? TextField(
                                        controller: _editController,
                                        autofocus: true,
                                        style: const TextStyle(
                                          color: Colors.indigo,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        decoration: _editFieldDecoration(),
                                        onSubmitted: (_) => _commitEditingName(item),
                                        onTapOutside: (_) => _commitEditingName(item),
                                      )
                                    : InkWell(
                                        onTap: isUpdating ? null : () => _startEditingName(item),
                                        child: Text(
                                          item.customDeviceName ?? item.deviceName ?? '',
                                          style: const TextStyle(
                                            color: Colors.indigo,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                              ),
                              Switch(
                                value: item.isActive,
                                activeColor: Colors.green,
                                onChanged: isUpdating
                                    ? null
                                    : (value) => _updateDevice(
                                          item,
                                          customDeviceName: item.customDeviceName,
                                          isActive: value,
                                        ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.guid,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: isUpdating ? null : () => _pickHeader(item),
                            child: Text(
                              'Inventário: ${item.header?.inventName ?? "—"}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.indigo,
                                decoration: TextDecoration.underline,
                                decorationColor: Color(0xFFE2E8F0),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Usuário: ${item.username}',
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Plataforma: ${item.platform}',
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text("Nenhum device vinculado a um inventário foi encontrado."));
  }
}
