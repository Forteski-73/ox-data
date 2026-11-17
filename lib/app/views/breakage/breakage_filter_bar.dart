import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oxdata/app/core/models/breakage_model.dart';
import 'package:oxdata/app/core/models/store_model.dart';

/// Barra de filtros de período e loja usada nas abas Aprovações, Baixar e Histórico.
/// O período filtra pela data de registro (`createdAt`).
class BreakageFilterBar extends StatelessWidget {
  final BreakageFilter filter;
  final List<StoreModel> stores;
  final ValueChanged<BreakageFilter> onChanged;

  const BreakageFilterBar({
    super.key,
    required this.filter,
    required this.stores,
    required this.onChanged,
  });

  static const Color _oxfordColor = Color(0xFF002B49);
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void _setPeriod(DateTime from, DateTime to) => onChanged(filter.copyWith(dateFrom: from, dateTo: to));

  Future<void> _pickPeriod(BuildContext context) async {
    final range = await showDateRangePicker(
      context: context,
      locale: const Locale('pt', 'BR'),
      firstDate: DateTime(2020),
      lastDate: _today,
      initialDateRange: filter.dateFrom != null && filter.dateTo != null
          ? DateTimeRange(start: filter.dateFrom!, end: filter.dateTo!)
          : null,
    );
    if (range != null) _setPeriod(range.start, range.end);
  }

  String get _periodLabel {
    if (!filter.hasPeriod) return 'Período';
    final from = filter.dateFrom == null ? '...' : _dateFormat.format(filter.dateFrom!);
    final to = filter.dateTo == null ? '...' : _dateFormat.format(filter.dateTo!);
    return from == to ? from : '$from a $to';
  }

  @override
  Widget build(BuildContext context) {
    final today = _today;
    final selectedStore = stores.where((s) => s.storeId == filter.storeId).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _oxfordColor,
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  alignment: Alignment.centerLeft,
                ),
                onPressed: () => _pickPeriod(context),
                icon: const Icon(Icons.date_range, size: 16),
                label: Text(_periodLabel, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
              ),
            ),
            if (stores.length > 1) ...[
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: selectedStore?.storeId,
                  isExpanded: true,
                  isDense: true,
                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Todas as lojas')),
                    ...stores.map((s) => DropdownMenuItem<String?>(
                          value: s.storeId,
                          child: Text(s.displayName, overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: (id) => onChanged(id == null ? filter.copyWith(clearStore: true) : filter.copyWith(storeId: id)),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildShortcut('Hoje', () => _setPeriod(today, today)),
              _buildShortcut('7 dias', () => _setPeriod(today.subtract(const Duration(days: 6)), today)),
              _buildShortcut('30 dias', () => _setPeriod(today.subtract(const Duration(days: 29)), today)),
              _buildShortcut('Este mês', () => _setPeriod(DateTime(today.year, today.month, 1), today)),
              if (filter.hasPeriod)
                _buildActiveChip(_periodLabel, () => onChanged(filter.copyWith(clearPeriod: true))),
              if (selectedStore != null)
                _buildActiveChip(selectedStore.displayName, () => onChanged(filter.copyWith(clearStore: true))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShortcut(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 10)),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: Colors.grey.shade100,
        side: BorderSide(color: Colors.grey.shade300),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildActiveChip(String label, VoidCallback onClear) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InputChip(
        label: Text(label, style: const TextStyle(fontSize: 10, color: Colors.white)),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: _oxfordColor,
        deleteIconColor: Colors.white,
        side: BorderSide.none,
        onDeleted: onClear,
      ),
    );
  }
}
