import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/widgets/app_bar.dart';
import 'package:oxdata/app/core/widgets/pulse_icon.dart';
import 'package:oxdata/app/core/utils/call_action.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  @override
  Widget build(BuildContext context) {
    final loadingService = context.read<LoadingService>();

    return Scaffold(
      // Mantendo o padrão de AppBarCustom com o título dinâmico se necessário
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppBarCustom(title: 'Painel Administrativo'),
      ),
      body: Stack(
        children: [
          // Área de conteúdo central seguindo o espaçamento da sua SearchProductsPage
          Padding(
            padding: const EdgeInsets.only(top: 80.0, left: 10.0, right: 10.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.admin_panel_settings_outlined,
                    size: 85,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bem-vindo ao Admin',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Exemplo de botão seguindo o padrão de ação do seu app
                  PulseIconButton(
                    icon: Icons.refresh,
                    color: Colors.indigo,
                    onPressed: () async {
                      await CallAction.run(
                        action: () async {
                          loadingService.show();
                          // Simulação de uma carga administrativa
                          await Future.delayed(const Duration(seconds: 1));
                        },
                        onFinally: () {
                          loadingService.hide();
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // Barra de ações superior fixada (Header) similar à de busca
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: PulseIconButton(
                      icon: Icons.settings_outlined,
                      color: Colors.indigo,
                      onPressed: () {
                        // Navegação ou ação
                      },
                    ),
                  ),
                  Expanded(
                    child: PulseIconButton(
                      icon: Icons.group_outlined,
                      color: Colors.indigo,
                      onPressed: () {
                        // Navegação ou ação
                      },
                    ),
                  ),
                  Expanded(
                    child: PulseIconButton(
                      icon: Icons.analytics_outlined,
                      color: Colors.indigo,
                      onPressed: () {
                        // Navegação ou ação
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}