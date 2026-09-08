import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/models/dto/inventory_header_model.dart';
import 'package:oxdata/app/core/services/inventory_service.dart';
import 'package:oxdata/app/core/services/message_service.dart';
import 'package:oxdata/app/core/utils/upper_case_text.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

/// Aba "Header" da InventoryAdmPage.
///
/// Cadastro de cabeçalhos de inventário (inventName, inventDescription e
/// salesChannelOnly) via `POST Inventory/Header` e listagem via
/// `GET Inventory/Header/Recent`, seguindo o mesmo padrão visual da
/// InventoryTabConfig.
///
/// Edição: em vez de editar os campos dentro da própria linha da lista
/// (o que abria o teclado por cima dos campos no celular), tocar em
/// "editar" carrega os valores no formulário fixo do topo — que nunca
/// rola junto com a lista — e o mesmo botão passa a atuar como
/// "Salvar" (a API já faz upsert pelo `id`).
class InventoryTabHeader extends StatefulWidget {
  const InventoryTabHeader({super.key});

  @override
  State<InventoryTabHeader> createState() => _InventoryTabHeaderState();
}

class _InventoryTabHeaderState extends State<InventoryTabHeader> {
  bool _isLoading = false;
  bool _isSubmitting = false;

  // Ids em processo de atualização (evita toques duplicados durante o POST).
  final Set<int> _updatingIds = {};

  // Formulário de cadastro/edição (o mesmo formulário serve para os dois).
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final FocusNode _formNameFocusNode = FocusNode();
  final FocusNode _formDescFocusNode = FocusNode();
  bool _salesChannelOnlyForm = false;

  // Id do registro em edição no formulário; null = cadastrando um novo.
  int? _editingItemId;

  // Busca
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchHeaders();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _formNameFocusNode.dispose();
    _formDescFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchHeaders() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await context.read<InventoryService>().fetchRecentInventoryHeaders();
    } catch (e) {
      debugPrint("Erro ao buscar cabeçalhos de inventário: $e");
      if (mounted) {
        MessageService.showError("Erro ao carregar a lista de inventários.");
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  List<InventoryHeaderModel> _visibleItems(List<InventoryHeaderModel> all) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return all;

    return all.where((item) {
      return item.inventName.toLowerCase().contains(query) ||
          item.inventDescription.toLowerCase().contains(query);
    }).toList();
  }

  InventoryHeaderModel? _findHeaderById(int id) {
    for (final h in context.read<InventoryService>().inventoryHeaders) {
      if (h.id == id) return h;
    }
    return null;
  }

  /// Carrega o registro no formulário do topo para edição. É chamado ao
  /// tocar no nome ou na descrição de uma linha da lista, ou no ícone de
  /// editar — nunca mais abre campos de edição dentro da própria linha.
  void _startEditingInForm(InventoryHeaderModel item, {bool focusDescription = false}) {
    _nameController.text = item.inventName;
    _descController.text = item.inventDescription;

    setState(() {
      _salesChannelOnlyForm = item.salesChannelOnly;
      _editingItemId = item.id;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _editingItemId != item.id) return;
      (focusDescription ? _formDescFocusNode : _formNameFocusNode).requestFocus();
    });
  }

  void _cancelEditingForm() {
    _resetForm();
  }

  void _resetForm() {
    _nameController.clear();
    _descController.clear();
    setState(() {
      _salesChannelOnlyForm = false;
      _editingItemId = null;
    });
  }

  Future<void> _submitForm() async {
    final name = _nameController.text.trim();
    final description = _descController.text.trim();

    if (name.isEmpty) {
      MessageService.showError("Informe o nome do inventário.");
      return;
    }

    final editingId = _editingItemId;
    final existing = editingId == null ? null : _findHeaderById(editingId);

    setState(() => _isSubmitting = true);

    final success = await context.read<InventoryService>().createOrUpdateInventoryHeader(
          InventoryHeaderModel(
            id: editingId ?? 0,
            inventName: name,
            inventDescription: description,
            salesChannelOnly: _salesChannelOnlyForm,
            active: existing?.active ?? true,
          ),
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      final wasEditing = editingId != null;
      _resetForm();
      MessageService.showSuccess(
        wasEditing ? "Inventário atualizado com sucesso!" : "Inventário cadastrado com sucesso!",
      );
    } else {
      MessageService.showError(
        editingId == null ? "Erro ao cadastrar o inventário." : "Erro ao atualizar o inventário.",
      );
    }
  }

  Future<void> _toggleSalesChannelOnly(InventoryHeaderModel item, bool value) async {
    setState(() => _updatingIds.add(item.id));

    final success = await context.read<InventoryService>().createOrUpdateInventoryHeader(
          item.copyWith(salesChannelOnly: value),
        );

    if (!mounted) return;
    setState(() => _updatingIds.remove(item.id));

    if (!success) {
      MessageService.showError("Erro ao atualizar o inventário.");
    }

    // Se o item alternado é o mesmo que está aberto no formulário, mantém
    // o formulário sincronizado com o valor recém-salvo.
    if (_editingItemId == item.id) {
      setState(() => _salesChannelOnlyForm = value);
    }
  }

  /// Mesmo padrão visual dos campos de texto usado na InventoryTabConfig.
  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      counterText: '',
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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

  @override
  Widget build(BuildContext context) {
    final all = context.watch<InventoryService>().inventoryHeaders;
    final visible = _visibleItems(all);
    final bool isDesktop = MediaQuery.of(context).size.width >= 900;

    return Column(
      children: [
        _buildCadastroForm(isDesktop),
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

  Widget _buildCadastroForm(bool isDesktop) {
    final isEditing = _editingItemId != null;

    return Container(
      padding: EdgeInsets.fromLTRB(isDesktop ? 16.0 : 10.0, 10.0, isDesktop ? 16.0 : 10.0, 0),
      decoration: const BoxDecoration(color: Colors.white),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isEditing ? Colors.indigo : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isEditing) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _isSubmitting ? null : _cancelEditingForm,
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text("Cancelar edição", style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: _buildNameField()),
                          const SizedBox(width: 10),
                          Expanded(flex: 3, child: _buildDescField()),
                          const SizedBox(width: 10),
                          _buildSalesChannelOnlySwitch(),
                          const SizedBox(width: 10),
                          _buildSubmitButton(),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildNameField(),
                          const SizedBox(height: 6),
                          _buildDescField(),
                          const SizedBox(height: 6),
                          _buildSalesChannelOnlySwitch(),
                          const SizedBox(height: 8),
                          SizedBox(width: double.infinity, child: _buildSubmitButton()),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Limites espelham as colunas `invent_name` (50) e `invent_description`
  // (255) de `inventory_header` no backend — passar disso é rejeitado com
  // 400 pelo model validation do ASP.NET antes mesmo de chegar na action.
  static const int _nameMaxLength = 50;
  static const int _descMaxLength = 255;

  Widget _buildNameField() {
    return TextField(
      controller: _nameController,
      focusNode: _formNameFocusNode,
      enabled: !_isSubmitting,
      maxLength: _nameMaxLength,
      textCapitalization: TextCapitalization.characters,
      inputFormatters: [UpperCaseTextFormatter()],
      decoration: _fieldDecoration('Nome do inventário'),
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
    );
  }

  Widget _buildDescField() {
    return TextField(
      controller: _descController,
      focusNode: _formDescFocusNode,
      enabled: !_isSubmitting,
      maxLength: _descMaxLength,
      textCapitalization: TextCapitalization.characters,
      inputFormatters: [UpperCaseTextFormatter()],
      decoration: _fieldDecoration('Descrição'),
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
    );
  }

  Widget _buildSalesChannelOnlySwitch() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Somente canal de vendas",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF475569)),
        ),
        Transform.scale(
          scale: 0.9,
          child: Switch(
            value: _salesChannelOnlyForm,
            activeColor: Colors.indigo,
            onChanged: _isSubmitting ? null : (value) => setState(() => _salesChannelOnlyForm = value),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final isEditing = _editingItemId != null;

    return FilledButton.icon(
      onPressed: _isSubmitting ? null : _submitForm,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.indigo,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: _isSubmitting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Icon(isEditing ? Icons.save_rounded : Icons.add_rounded, size: 20),
      label: Text(isEditing ? "Salvar" : "Cadastrar"),
    );
  }

  Widget _buildSearchField(bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 16.0 : 10.0, vertical: 10.0),
      decoration: const BoxDecoration(color: Colors.white),
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
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [UpperCaseTextFormatter()],
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Buscar por nome ou descrição...',
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
                        horizontal: 12,
                        vertical: 12,
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
                      fontSize: 15,
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
                  onPressed: _isLoading ? null : _fetchHeaders,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebGridTable(List<InventoryHeaderModel> list) {
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
                  flex: 3,
                  child: Text(
                    "NOME",
                    style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    "DESCRIÇÃO",
                    style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: Text(
                    "SOMENTE CANAL VENDAS",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569), fontSize: 11),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    "AÇÕES",
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
                final isBeingEdited = _editingItemId == item.id;

                return Container(
                  color: isBeingEdited ? Colors.indigo.withOpacity(0.06) : null,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: InkWell(
                          onTap: isUpdating ? null : () => _startEditingInForm(item),
                          child: Text(
                            item.inventName,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.indigo),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 4,
                        child: InkWell(
                          onTap: isUpdating ? null : () => _startEditingInForm(item, focusDescription: true),
                          child: Text(
                            item.inventDescription,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 150,
                        child: Center(
                          child: Switch(
                            value: item.salesChannelOnly,
                            activeColor: Colors.indigo,
                            onChanged: isUpdating ? null : (value) => _toggleSalesChannelOnly(item, value),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Center(
                          child: IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.edit_outlined, color: Colors.indigo),
                            tooltip: 'Editar',
                            onPressed: isUpdating ? null : () => _startEditingInForm(item),
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

  Widget _buildMobileCardsList(List<InventoryHeaderModel> list) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final isUpdating = _updatingIds.contains(item.id);
        final isBeingEdited = _editingItemId == item.id;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            decoration: BoxDecoration(
              color: isBeingEdited ? Colors.indigo.withOpacity(0.06) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: isBeingEdited ? Border.all(color: Colors.indigo) : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: isUpdating ? null : () => _startEditingInForm(item),
                          child: Text(
                            item.inventName,
                            style: const TextStyle(
                              color: Colors.indigo,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.edit_outlined, color: Colors.indigo),
                        tooltip: 'Editar',
                        onPressed: isUpdating ? null : () => _startEditingInForm(item),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: isUpdating ? null : () => _startEditingInForm(item, focusDescription: true),
                    child: Text(
                      item.inventDescription.isEmpty ? '—' : item.inventDescription,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Somente canal de vendas',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      Switch(
                        value: item.salesChannelOnly,
                        activeColor: Colors.indigo,
                        onChanged: isUpdating ? null : (value) => _toggleSalesChannelOnly(item, value),
                      ),
                    ],
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
    return const Center(child: Text("Nenhum inventário cadastrado."));
  }
}
