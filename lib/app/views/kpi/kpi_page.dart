import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:oxdata/app/core/widgets/app_bar.dart';
import 'package:oxdata/app/core/models/dto/kpi_completude_model.dart';
import 'package:oxdata/app/core/services/kpi_service.dart';

/// Página de KPIs (Completude) — exibe métricas em cards e um gráfico
/// de barras simples mostrando a % de cobertura por categoria de
/// imagem (Produto, Embalagem, Paletização), buscadas em
/// `GET Kpi/Completude`.
class KpiPage extends StatefulWidget {
  const KpiPage({super.key});

  @override
  State<KpiPage> createState() => _KpiPageState();
}

class _KpiPageState extends State<KpiPage> {
  // Paleta fixa aplicada às categorias, na ordem em que a API retorna.
  static const List<Color> _categoryColors = [
    Color(0xFF4F46E5),
    Color(0xFF6366F1),
    Color(0xFF818CF8),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KpiService>().fetchCompletude();
    });
  }

  @override
  Widget build(BuildContext context) {
    final kpiService = context.watch<KpiService>();
    final completude = kpiService.completude;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppBarCustom(title: 'KPI - Imagens'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildRefreshBar(kpiService),
            Expanded(
              child: kpiService.isLoading && completude == null
                  ? const Center(child: SpinKitThreeBounce(color: Colors.indigo, size: 30.0))
                  : completude == null
                      ? _buildErrorState(kpiService.errorMessage)
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          children: [
                            _buildKpiHeaderCard(completude),
                            const SizedBox(height: 16),
                            _buildChartCard(completude),
                            const SizedBox(height: 16),
                            _buildSummaryRow(completude),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshBar(KpiService kpiService) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.indigo),
            style: IconButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            tooltip: 'Atualizar',
            onPressed: kpiService.isLoading ? null : () => kpiService.fetchCompletude(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String? message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message ?? 'Erro ao carregar os indicadores de completude.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // KPI principal (número grande no topo)
  // ---------------------------------------------------------------------
  Widget _buildKpiHeaderCard(KpiCompletudeModel completude) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'GERAL · APARELHOS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4F46E5),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${(completude.completudeGeral * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${NumberFormat.decimalPattern('pt_BR').format(completude.produtosCompletos)} de '
                '${NumberFormat.decimalPattern('pt_BR').format(completude.totalProdutos)} aparelhos com imagem completa',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Completo = tem imagem de Produto + Embalagem + Paletização',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: completude.completudeGeral,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Gráfico de barras por categoria
  // ---------------------------------------------------------------------
  Widget _buildChartCard(KpiCompletudeModel completude) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cobertura por categoria',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                '% de aparelhos com ao menos uma imagem na categoria',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 180,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < completude.categorias.length; i++)
                      _buildBar(
                        completude.categorias[i],
                        _categoryColors[i % _categoryColors.length],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBar(KpiCategoriaModel categoria, Color color) {
    const double maxBarHeight = 130;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '${(categoria.percent * 100).toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 44,
          height: maxBarHeight * categoria.percent,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 72,
          child: Text(
            categoria.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Linha de resumo (mini cards)
  // ---------------------------------------------------------------------
  Widget _buildSummaryRow(KpiCompletudeModel completude) {
    final incompletos = completude.totalProdutos - completude.produtosCompletos;
    final formatter = NumberFormat.decimalPattern('pt_BR');

    return Row(
      children: [
        Expanded(child: _summaryCard('Completos', formatter.format(completude.produtosCompletos), const Color(0xFF10B981))),
        const SizedBox(width: 12),
        Expanded(child: _summaryCard('Incompletos', formatter.format(incompletos), const Color(0xFFEF4444))),
        const SizedBox(width: 12),
        Expanded(child: _summaryCard('Total', formatter.format(completude.totalProdutos), const Color(0xFF4F46E5))),
      ],
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
