import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/models/breakage_history_model.dart';
import 'package:oxdata/app/core/models/breakage_model.dart';
import 'package:oxdata/app/core/services/breakage_service.dart';

/// Abre a linha do tempo do registro (GET Breakage/{id}/history).
/// [photoBuilder] desenha uma miniatura; [onPhotoTap] amplia a foto;
/// [statusColor] é a cor do status usada na tela.
Future<void> showBreakageHistorySheet({
  required BuildContext context,
  required BreakageModel breakage,
  required String productName,
  required String storeName,
  required Color statusColor,
  required Widget Function(String url, double size) photoBuilder,
  required void Function(String url) onPhotoTap,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: _BreakageHistorySheet(
          scrollController: scrollController,
          breakage: breakage,
          productName: productName,
          storeName: storeName,
          statusColor: statusColor,
          photoBuilder: photoBuilder,
          onPhotoTap: onPhotoTap,
        ),
      ),
    ),
  );
}

class _BreakageHistorySheet extends StatefulWidget {
  final ScrollController scrollController;
  final BreakageModel breakage;
  final String productName;
  final String storeName;
  final Color statusColor;
  final Widget Function(String url, double size) photoBuilder;
  final void Function(String url) onPhotoTap;

  const _BreakageHistorySheet({
    required this.scrollController,
    required this.breakage,
    required this.productName,
    required this.storeName,
    required this.statusColor,
    required this.photoBuilder,
    required this.onPhotoTap,
  });

  @override
  State<_BreakageHistorySheet> createState() => _BreakageHistorySheetState();
}

class _BreakageHistorySheetState extends State<_BreakageHistorySheet> {
  static const Color _oxfordColor = Color(0xFF002B49);
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final NumberFormat _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  /// Eventos em ordem cronológica (do registro até hoje).
  List<BreakageHistoryModel>? _events;
  String? _error;
  bool _newestFirst = false;

  BreakageModel get _b => widget.breakage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _events = null;
      _error = null;
    });

    final service = context.read<BreakageService>();
    final response = await service.fetchHistory(_b.breakageId);
    if (!mounted) return;

    if (!response.success || response.data == null) {
      setState(() => _error = response.message ?? 'Erro ao carregar a linha do tempo.');
      return;
    }

    final events = List<BreakageHistoryModel>.from(response.data!)
      ..sort((a, b) {
        final byDate = (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0));
        return byDate != 0 ? byDate : a.historyId.compareTo(b.historyId);
      });
    setState(() => _events = events);

    // Miniaturas: foto original (CRIADO) e fotos antigas/novas das edições.
    service.fetchPhotoUrls([
      _originalPhotoUrl(events),
      ...events.where((e) => e.isPhotoChange).expand((e) => [e.oldValue ?? '', e.newValue ?? '']),
    ]);
  }

  /// Foto do registro original: a "antiga" da primeira troca de foto, ou a atual.
  String _originalPhotoUrl(List<BreakageHistoryModel> events) {
    final firstPhotoEdit = events.where((e) => e.event == BreakageEvent.editado && e.isPhotoChange).firstOrNull;
    return firstPhotoEdit?.oldValue ?? _b.photoUrl;
  }

  /// Quantidade registrada originalmente: a "antiga" da primeira troca de quantidade, ou a atual.
  String _originalQuantity(List<BreakageHistoryModel> events) {
    final firstQtyEdit = events.where((e) => e.event == BreakageEvent.editado && !e.isPhotoChange).firstOrNull;
    return firstQtyEdit?.oldValue ?? '${_b.quantity}';
  }

  @override
  Widget build(BuildContext context) {
    // Reconstrói quando as fotos chegam do FTP.
    context.watch<BreakageService>();

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Center(
          child: Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
        ),
        _buildHeader(),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 8),
        ..._buildBody(),
      ],
    );
  }

  // ── Cabeçalho ─────────────────────────────────────────────

  Widget _buildHeader() {
    final events = _events;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Linha do tempo • #${_b.breakageId}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  Text(widget.productName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(
                    'Loja: ${widget.storeName} • ${_b.quantity} un • '
                    '${_b.totalValue == null ? '—' : _currency.format(_b.totalValue)}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: widget.statusColor.withValues(alpha: 0.4)),
              ),
              child: Text(BreakageStatus.label(_b.status),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: widget.statusColor)),
            ),
            Text('na fila de: ${BreakageStatus.queueLabel(_b.status)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        if (events != null && events.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(_summary(events), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
        ],
      ],
    );
  }

  String _summary(List<BreakageHistoryModel> events) {
    int count(String event) => events.where((e) => e.event == event).length;
    final sent = count(BreakageEvent.aprovadoGerente) + count(BreakageEvent.reenviadoCi);
    final returned = count(BreakageEvent.devolvidoCi);
    final edited = count(BreakageEvent.editado);

    final start = events.first.createdAt;
    final isFinal = _b.status == BreakageStatus.baixado ||
        _b.status == BreakageStatus.excluido ||
        _b.status == BreakageStatus.rejeitado;
    final end = isFinal ? events.last.createdAt : DateTime.now();

    return [
      'Enviado ao CI $sent×',
      'Reprovado $returned×',
      'Editado $edited×',
      if (start != null && end != null) 'Tempo total: ${_formatDuration(end.difference(start))}',
    ].join(' • ');
  }

  // ── Corpo ─────────────────────────────────────────────────

  List<Widget> _buildBody() {
    if (_error != null) {
      return [
        const SizedBox(height: 24),
        const Icon(Icons.cloud_off_outlined, color: Colors.red, size: 40),
        const SizedBox(height: 8),
        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        Center(
          child: TextButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Tentar novamente', style: TextStyle(fontSize: 12)),
          ),
        ),
      ];
    }

    final events = _events;
    if (events == null) return List.generate(3, (i) => _buildSkeletonNode(isLast: i == 2));

    final hasCreation = events.any((e) => e.event == BreakageEvent.criado);
    final legacyNote = Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text('Sem histórico detalhado (registro anterior à v2)',
          style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade600)),
    );

    if (events.isEmpty) return [legacyNote];

    // Agrupa por ciclo: um novo ciclo começa a cada envio a Controles Internos.
    final groups = <List<int>>[[]];
    for (var i = 0; i < events.length; i++) {
      if (BreakageEvent.startsCycle(events[i].event) && groups.last.isNotEmpty) groups.add([]);
      groups.last.add(i);
    }
    // Número do ciclo de cada grupo (0 = antes do primeiro envio).
    var cycle = 0;
    final cycleOf = [
      for (final g in groups) BreakageEvent.startsCycle(events[g.first].event) ? ++cycle : 0,
    ];

    final order = List<int>.generate(groups.length, (i) => i);
    final displayed = <(int, int?)>[]; // (índice do evento, ciclo a mostrar antes dele)
    for (final gi in _newestFirst ? order.reversed : order) {
      final indexes = _newestFirst ? groups[gi].reversed.toList() : groups[gi];
      for (var k = 0; k < indexes.length; k++) {
        displayed.add((indexes[k], k == 0 && cycleOf[gi] > 0 ? cycleOf[gi] : null));
      }
    }

    return [
      Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: () => setState(() => _newestFirst = !_newestFirst),
          icon: Icon(_newestFirst ? Icons.arrow_upward : Icons.arrow_downward, size: 14),
          label: Text(_newestFirst ? 'Mais recentes primeiro' : 'Mais antigos primeiro',
              style: const TextStyle(fontSize: 11)),
        ),
      ),
      for (var d = 0; d < displayed.length; d++) ...[
        if (displayed[d].$2 != null) _buildCycleHeader(displayed[d].$2!),
        _buildNode(
          events,
          displayed[d].$1,
          nextColor: d + 1 < displayed.length ? BreakageEvent.color(events[displayed[d + 1].$1].event) : null,
        ),
      ],
      if (!hasCreation) legacyNote,
    ];
  }

  Widget _buildCycleHeader(int cycle) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: _oxfordColor, borderRadius: BorderRadius.circular(10)),
            child: Text('Ciclo $cycle', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: Colors.grey.shade300)),
        ],
      ),
    );
  }

  Widget _buildNode(List<BreakageHistoryModel> events, int index, {required Color? nextColor}) {
    final e = events[index];
    final color = BreakageEvent.color(e.event);
    final previous = index > 0 ? events[index - 1].createdAt : null;
    final delta = previous != null && e.createdAt != null ? '+${_formatDuration(e.createdAt!.difference(previous))}' : null;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(BreakageEvent.icon(e.event), size: 18, color: color),
              ),
              if (nextColor != null) Expanded(child: Container(width: 2, color: nextColor.withValues(alpha: 0.5))),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(BreakageEvent.label(e), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      if (delta != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(delta, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                        ),
                    ],
                  ),
                  Text(e.createdAt == null ? '-' : _dateFormat.format(e.createdAt!),
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ..._buildDetail(e, events),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDetail(BreakageHistoryModel e, List<BreakageHistoryModel> events) {
    final hasText = (e.justification ?? '').isNotEmpty;

    switch (e.event) {
      case BreakageEvent.criado:
        return [
          const SizedBox(height: 4),
          Text('${_originalQuantity(events)} un • ${_b.reason}', style: const TextStyle(fontSize: 11)),
          const SizedBox(height: 6),
          _buildThumb(_originalPhotoUrl(events)),
        ];

      case BreakageEvent.editado:
        return [
          const SizedBox(height: 4),
          if (e.isPhotoChange)
            Row(
              children: [
                _buildThumb(e.oldValue),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                ),
                _buildThumb(e.newValue),
              ],
            )
          else
            Text('${e.oldValue ?? '-'} → ${e.newValue ?? '-'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          if (hasText) _buildBalloon(e.justification!, Colors.amber.shade50, Colors.black87),
        ];

      case BreakageEvent.aprovadoGerente:
        return [const Text('Enviado a Controles Internos', style: TextStyle(fontSize: 11, color: Colors.grey))];

      case BreakageEvent.reenviadoCi:
        return [if (hasText) _buildBalloon(e.justification!, Colors.orange.shade50, Colors.black87)];

      case BreakageEvent.devolvidoCi:
        return [
          if (hasText) _buildBalloon(e.justification!, Colors.red.shade50, Colors.red.shade800, bold: true),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('Voltou para o gerente', style: TextStyle(fontSize: 11, color: Colors.red.shade400)),
          ),
        ];

      case BreakageEvent.excluido:
      case BreakageEvent.rejeitadoGerente:
        return [if (hasText) _buildBalloon(e.justification!, Colors.grey.shade100, Colors.black87)];

      default:
        return [if (hasText) _buildBalloon(e.justification!, Colors.grey.shade100, Colors.black87)];
    }
  }

  /// Motivo/justificativa completa, sem cortar.
  Widget _buildBalloon(String text, Color background, Color foreground, {bool bold = false}) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(8),
      width: double.infinity,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(8)),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: foreground, fontWeight: bold ? FontWeight.w600 : FontWeight.normal, fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _buildThumb(String? url) {
    if (url == null || url.isEmpty) return widget.photoBuilder('', 56);
    return InkWell(onTap: () => widget.onPhotoTap(url), child: widget.photoBuilder(url, 56));
  }

  /// Esqueleto de carregamento (3 nós).
  Widget _buildSkeletonNode({required bool isLast}) {
    final shade = Colors.grey.shade200;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(width: 30, height: 30, decoration: BoxDecoration(color: shade, shape: BoxShape.circle)),
              if (!isLast) Expanded(child: Container(width: 2, color: shade)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 12, width: 180, decoration: BoxDecoration(color: shade, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 6),
                  Container(height: 10, width: 100, decoration: BoxDecoration(color: shade, borderRadius: BorderRadius.circular(4))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "2d 5h", "3h 20min", "15min" ou "<1min".
  static String _formatDuration(Duration d) {
    if (d.isNegative) d = Duration.zero;
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    if (days > 0) return hours > 0 ? '${days}d ${hours}h' : '${days}d';
    if (d.inHours > 0) return minutes > 0 ? '${d.inHours}h ${minutes}min' : '${d.inHours}h';
    if (d.inMinutes > 0) return '${d.inMinutes}min';
    return '<1min';
  }
}
