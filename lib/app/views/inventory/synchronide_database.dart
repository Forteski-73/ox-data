import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:oxdata/app/core/services/inventory_service.dart';

// ----------------------------------------------------------------------
// FUNÇÃO PARA OBTER O ID ÚNICO DO DISPOSITIVO
// ----------------------------------------------------------------------
Future<String> getDeviceId() async {
  final prefs = await SharedPreferences.getInstance();
  String? id = prefs.getString("device_uuid");

  if (id == null) {
    id = const Uuid().v4();
    await prefs.setString("device_uuid", id);
  }

  return id;
}

// ----------------------------------------------------------------------
// WIDGET PRINCIPAL
// ----------------------------------------------------------------------
class SynchronizeDBPage extends StatelessWidget {
  const SynchronizeDBPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(8),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ================= TOPO FIXO (NÃO RECONSTRÓI) =================
            const _DeviceIdentification(),

            const SizedBox(height: 16),

            // ================= CONTEÚDO CENTRAL (REAGE AO PROVIDER) =================
            Expanded(
              child: Center(
                child: Consumer<InventoryService>(
                  builder: (context, service, _) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_sync, size: 65, color: Colors.indigo),
                        const SizedBox(height: 10),

                        const Text(
                          "Sincronizar Banco de Dados",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),

                        const SizedBox(height: 30),

                        if (service.isSyncing) ...[
                          LinearProgressIndicator(
                            value: service.progressSynchronize,
                            minHeight: 8,
                            color: Colors.indigo,
                            backgroundColor: Colors.indigo.shade100,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            service.infoSynchronize,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
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
}

// ----------------------------------------------------------------------
// WIDGET ISOLADO → NÃO ESCUTA PROVIDER
// ----------------------------------------------------------------------
class _DeviceIdentification extends StatelessWidget {
  const _DeviceIdentification();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          "Identificação do Dispositivo",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        FutureBuilder<String>(
          future: getDeviceId(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator(color: Colors.indigo);
            } else if (snapshot.hasError) {
              return Text(
                'Erro: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              );
            } else if (snapshot.hasData) {
              return SelectableText(
                snapshot.data!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                  fontFamily: 'monospace',
                ),
              );
            } else {
              return const Text(
                "Nenhum ID disponível.",
                style: TextStyle(color: Colors.black54),
              );
            }
          },
        ),
      ],
    );
  }
}
