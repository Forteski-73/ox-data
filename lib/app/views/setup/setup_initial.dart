// -----------------------------------------------------------
// app/views/setup/setup_init_page.dart
// -----------------------------------------------------------
import 'dart:async';
import 'package:flutter/material.dart';

import 'package:oxdata/app/core/repositories/admin_repository.dart';
import 'package:oxdata/app/core/utils/device.dart';
import 'package:oxdata/app/core/services/inventory_service.dart';
import 'package:oxdata/app/core/sync/sync_api_client_impl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:oxdata/app/core/services/auth_service.dart';
import 'package:oxdata/app/core/utils/app_info.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

// ---------------------------------------------------------------------------
// Modelo de passo de configuração
// ---------------------------------------------------------------------------

enum StepState { pending, running, done, error }

class SetupStep {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;

  const SetupStep({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });
}

// ---------------------------------------------------------------------------
// SetupInitPage
// ---------------------------------------------------------------------------
//
// Igual ao SetupPage, porém SEM a etapa de "Baixando configurações"
// (máscaras/setores/parâmetros). Usado no gate de primeiro login:
// Verificando conexão -> Autenticando dispositivo -> Sincronizando
// produtos -> Finalizado.

class SetupInitPage extends StatefulWidget {
  /// Serviço principal: expõe inventoryRepository e database usados na
  /// etapa de "Sincronizando produtos".
  final InventoryService inventoryService;

  /// Necessário para o teste real de conexão (hasRealConnection),
  /// já que ele usa adminRepository.apiClient.getAuth('User/api').
  final AdminRepository adminRepository;

  /// Tamanho da página usado na sincronização de produtos.
  final int productPageSize;

  /// Callback opcional chamado ao clicar em "OK" na tela final.
  /// Se nulo, faz apenas Navigator.pop() (comportamento padrão).
  final VoidCallback? onFinished;

  const SetupInitPage({
    super.key,
    required this.inventoryService,
    required this.adminRepository,
    this.productPageSize = 10000,
    this.onFinished,
  });

  @override
  State<SetupInitPage> createState() => _SetupInitPageState();
}

class _SetupInitPageState extends State<SetupInitPage> {
  static const _steps = [
    SetupStep(
      icon:      Icons.wifi_rounded,
      iconBg:    Color(0xFFE6F1FB),
      iconColor: Color(0xFF185FA5),
      title:     'Verificando conexão',
      subtitle:  'Testando disponibilidade de rede',
    ),
    SetupStep(
      icon:      Icons.shield_rounded,
      iconBg:    Color(0xFFEEEDFE),
      iconColor: Color(0xFF534AB7),
      title:     'Autenticando dispositivo',
      subtitle:  'Registrando GUID único do aparelho',
    ),
    SetupStep(
      icon:       Icons.inventory_2_rounded,
      iconBg:   Color(0xFFE8F1FF),
      iconColor:Color(0xFF1E5EFF),
      title:     'Sincronizando produtos',
      subtitle:  'Importando lista completa',
    ),
    SetupStep(
      icon: Icons.check_circle_rounded,
      iconBg: const Color(0xFFE9F6EF),
      iconColor: const Color(0xFF1E6F3D),
      title: 'VAMOS COMEÇAR!',
      subtitle: 'Ambiente pronto para uso',
    ),
  ];

  final List<StepState> _states = List.filled(_steps.length, StepState.pending);
  double _progress = 0.0;
  bool _allDone = false;
  int _visibleCount = 0;
  String? _errorMessage;

  late SyncApiClientImpl _syncApiClient;

  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();
    _syncApiClient = SyncApiClientImpl(
      inventoryRepository: widget.inventoryService.inventoryRepository,
      adminRepository: widget.adminRepository,
      database: widget.inventoryService.database,
    );
    _runSetup();
  }

  // ── Callbacks reais de cada etapa ───────────────────────────────────────

  /// Etapa 1 — Verificando conexão
  Future<void> _checkConnection() async {
    final ok = await _syncApiClient.hasRealConnection();
    if (!ok) {
      throw Exception('Sem conexão com o servidor. Verifique sua internet.');
    }
  }

  /// Etapa 2 — Autenticando dispositivo
  /// Gera (ou recupera) o GUID único do aparelho.
  Future<void> _authenticateDevice() async {
    final deviceId = await DeviceService.getDeviceId();
    final authService = context.read<AuthService>();

    final appVersion = await AppInfo.getAppVersion();
    final deviceName = await AppInfo.getDeviceName();

    final response = await authService.registerDevice(
      guid: deviceId,
      platform: currentPlatform(),
      appVersion: appVersion,
      deviceName: deviceName,
    );

    debugPrint('📱 GUID do dispositivo: $deviceId');
  }

    static String currentPlatform() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.linux:
        return 'linux';
      default:
        return 'unknown';
    }
  }

  /// Etapa 3 — Sincronizando produtos
  /// Busca a contagem total, limpa a base local e baixa o catálogo
  /// completo em páginas, salvando lote a lote.
  Future<void> _syncProducts() async {
    final repo = widget.inventoryService.inventoryRepository;
    final database = widget.inventoryService.database;

    final countResponse = await repo.getProductCount();
    if (!countResponse.success || countResponse.data == null) {
      throw Exception(countResponse.message ?? 'Falha ao obter contagem de produtos.');
    }

    final totalProducts = countResponse.data!;
    final pageSize = widget.productPageSize;
    final totalPages = (totalProducts / pageSize).ceil();

    if (totalPages == 0) return;

    await database.clearProducts();

    for (var page = 1; page <= totalPages; page++) {
      final response = await repo.getProductsPaged(page: page, pageSize: pageSize);
      if (!response.success || response.data == null) {
        throw Exception('Erro no lote $page: ${response.message}');
      }

      final error = await database.saveProductsBatch(response.data!);
      if (error != null) throw Exception('Falha ao gravar lote $page: $error');

      setState(() {
        // progresso parcial dentro da própria etapa de produtos
        // (índice 2 nesta versão de 4 etapas)
        _progress = (2 + (page / totalPages)) / _steps.length;
      });
    }
  }

  /// Etapa 4 — Finalizado
  /// Apenas visual, nenhuma chamada real é feita.
  Future<void> _finishVisualOnly() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  List<Future<void> Function()> get _callbacks => [
        _checkConnection,
        _authenticateDevice,
        _syncProducts,
        _finishVisualOnly,
      ];

  // ── Execução do fluxo ────────────────────────────────────────────────────

  Future<void> _runSetup() async {
    setState(() {
      _errorMessage = null;
      _allDone = false;
    });

    final callbacks = _callbacks;

    for (int i = 0; i < _steps.length; i++) {
      setState(() {
        _currentStepIndex = i;
        if (_visibleCount <= i) _visibleCount = i + 1;
        _states[i] = StepState.running;
      });

      try {
        await callbacks[i]();
        setState(() {
          _states[i] = StepState.done;
          _progress = (i + 1) / _steps.length;
        });
      } catch (e) {
        setState(() {
          _states[i] = StepState.error;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
        return;
      }
    }

    setState(() => _allDone = true);
  }

  void _retry() {
    setState(() {
      for (int i = 0; i < _states.length; i++) {
        _states[i] = StepState.pending;
      }
      _progress = 0.0;
      _visibleCount = 0;
      _allDone = false;
      _errorMessage = null;
    });
    _runSetup();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasError = _states.contains(StepState.error);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildProgressBar(),
              const SizedBox(height: 20),
              ..._buildStepRows(),
              if (hasError) ...[
                const SizedBox(height: 20),
                _buildErrorBanner(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                ),
              ],
              if (_allDone) ...[
                const SizedBox(height: 20),
                _buildDoneBanner(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (widget.onFinished != null) {
                        widget.onFinished!();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('OK'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final step = _steps[_currentStepIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: step.iconBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              step.icon,
              key: ValueKey(step.icon),
              color: step.iconColor,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 16),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            step.title,
            key: ValueKey(step.title),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
              letterSpacing: -0.3,
            ),
          ),
        ),

        const SizedBox(height: 4),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            step.subtitle,
            key: ValueKey(step.subtitle),
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _progress),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            builder: (_, value, __) => LinearProgressIndicator(
              value: value,
              minHeight: 4,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF4A6CF7)),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${(_progress * 100).round()}%',
          style: const TextStyle(fontSize: 15, color: Color(0xFF646870)),
        ),
      ],
    );
  }

  List<Widget> _buildStepRows() {
    final rows = <Widget>[];
    for (int i = 0; i < _visibleCount; i++) {
      rows.add(
        _AnimatedStepRow(
          key: ValueKey(i),
          step: _steps[i],
          state: _states[i],
        ),
      );
      rows.add(const SizedBox(height: 8));
    }
    return rows;
  }

  Widget _buildErrorBanner() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 12 * (1 - v)), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFAECE7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0A87E), width: 0.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFF993C1D), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage ?? 'Ocorreu um erro durante a configuração.',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF993C1D),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoneBanner() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - v)),
          child: child,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFE9F6EF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF34A853),
            width: 0.6,
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF1E6F3D),
              size: 22,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Dispositivo Sincronizado!',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E6F3D),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _AnimatedStepRow — linha individual com shimmer e fade-in
// ---------------------------------------------------------------------------

class _AnimatedStepRow extends StatefulWidget {
  final SetupStep step;
  final StepState state;

  const _AnimatedStepRow({super.key, required this.step, required this.state});

  @override
  State<_AnimatedStepRow> createState() => _AnimatedStepRowState();
}

class _AnimatedStepRowState extends State<_AnimatedStepRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;
  late final Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _shimmerAnim = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isRunning = widget.state == StepState.running;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 10 * (1 - v)), child: child),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            // Fundo principal
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isRunning
                      ? const Color(0xFF4A6CF7).withOpacity(0.3)
                      : const Color(0xFFE5E7EB),
                  width: isRunning ? 1 : 0.5,
                ),
              ),
              child: Row(
                children: [
                  // Ícone
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: widget.step.iconBg,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(widget.step.icon, color: widget.step.iconColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  // Texto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.step.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.step.subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Status
                  _buildStatus(),
                ],
              ),
            ),

            // Shimmer overlay quando running
            if (isRunning)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _shimmerAnim,
                  builder: (_, __) {
                    return ShaderMask(
                      blendMode: BlendMode.srcATop,
                      shaderCallback: (bounds) => LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: const [
                          Colors.transparent,
                          Color(0x22FFFFFF),
                          Colors.transparent,
                        ],
                        stops: [
                          (_shimmerAnim.value - 0.3).clamp(0.0, 1.0),
                          _shimmerAnim.value.clamp(0.0, 1.0),
                          (_shimmerAnim.value + 0.3).clamp(0.0, 1.0),
                        ],
                      ).createShader(bounds),
                      child: Container(color: Colors.white),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatus() {
    switch (widget.state) {
      case StepState.pending:
        return Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFFD1D5DB),
            shape: BoxShape.circle,
          ),
        );

      case StepState.running:
        return const SizedBox(
          width: 18,
          height: 18,
          child: SpinKitThreeBounce(color: Colors.white, size: 30.0),
        );

      case StepState.done:
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 300),
          builder: (_, v, __) => Transform.scale(
            scale: v,
            child: const Icon(Icons.check_circle_rounded,
                color: Color(0xFF1D9E75), size: 20),
          ),
        );

      case StepState.error:
        return const Icon(Icons.cancel_rounded, color: Color(0xFFE24B4A), size: 20);
    }
  }
}