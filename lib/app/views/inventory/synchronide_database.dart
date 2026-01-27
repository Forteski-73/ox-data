import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/services/inventory_service.dart';
import 'package:oxdata/app/core/utils/device.dart';

// ----------------------------------------------------------------------
// FUNÇÃO PARA OBTER O ID ÚNICO DO DISPOSITIVO
// ----------------------------------------------------------------------
Future<String> getDevice() async {
  String idNumerico = await DeviceService.getDeviceId();
  return idNumerico;
}

// ----------------------------------------------------------------------
// WIDGET PRINCIPAL
// ----------------------------------------------------------------------
class SynchronizeDBPage extends StatefulWidget {
  const SynchronizeDBPage({super.key});

  @override
  State<SynchronizeDBPage> createState() => _SynchronizeDBPageState();
}

class _SynchronizeDBPageState extends State<SynchronizeDBPage> {

  @override
  Widget build(BuildContext context) {
    final service = context.watch<InventoryService>();
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            // ================= TOPO FIXO =================
            const _DeviceIdentification(),
            
            const SizedBox(height: 20),

            // ================= SEÇÃO DE FLAGS (CHAVES) =================
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildSwitchTile(
                    title: "Configuração / Setup",
                    subtitle: "Sincronizar parâmetros do sistema",
                    value: service.isSetupEnabled,
                    icon: Icons.settings_suggest,
                    onChanged: (val) => service.setSetupEnabled(val),
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    title: "Contagem",
                    subtitle: "Sincronizar dados de inventário",
                    value: service.isContagemEnabled,
                    icon: Icons.inventory_2_outlined,
                    onChanged: (val) => service.setContagemEnabled(val),
                  ),
                ],
              ),
            ),

            // ================= CONTEÚDO CENTRAL =================
            Expanded(
              child: Center(
                child: Consumer<InventoryService>(
                  builder: (context, service, _) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        //const Icon(Icons.cloud_sync, size: 65, color: Colors.indigo),
                        /*const SizedBox(height: 10),
                        const Text(
                          "Sincronizar Banco de Dados",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                        ),*/
                        
                        // Criamos um container de altura fixa para os indicadores
                        //const SizedBox(height: 30),
                        SizedBox(
                          height: 60, // Altura suficiente para a barra + texto de info
                          child: service.isSyncing 
                            ? Column(
                                children: [
                                  LinearProgressIndicator(
                                    value: service.progressSynchronize,
                                    minHeight: 8,
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.indigo,
                                    backgroundColor: Colors.indigo.shade100,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    service.infoSynchronize,
                                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(), // Fica vazio, mas o espaço acima já foi definido
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para as chaves liga/desliga
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon, color: value ? Colors.indigo : Colors.grey),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      activeColor: Colors.indigo,
      contentPadding: EdgeInsets.zero,
    );
  }
}

// ----------------------------------------------------------------------
// WIDGET ISOLADO → NÃO ESCUTA PROVIDER
// ----------------------------------------------------------------------
class _DeviceIdentification extends StatelessWidget {
  const _DeviceIdentification();

  @override
  Widget build(BuildContext context) {
    return Container(
      // Estilização do entorno (Card)
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Ícone lateral para dar contexto visual
          Icon(Icons.developer_board, color: Colors.indigo.shade400, size: 28),
          const SizedBox(width: 10),
          
          // Informações de ID
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "IDENTIFICAÇÃO DO DISPOSITIVO",
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.2,
                    color: Colors.black87,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                FutureBuilder<String>(
                  future: getDevice(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 2,
                        width: 100,
                        child: LinearProgressIndicator(minHeight: 2),
                      );
                    } else if (snapshot.hasData) {
                      return SelectableText(
                        snapshot.data!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange, // Mantive o destaque que você pediu
                          fontFamily: 'monospace',
                        ),
                      );
                    } else {
                      return const Text("ID não localizado");
                    }
                  },
                ),
              ],
            ),
          ),
          
          // Badge "Ativo" ou Ícone de Status
          /*Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "ATIVO",
              style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ),*/
        ],
      ),
    );
  }
}
