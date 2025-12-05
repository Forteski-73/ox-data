import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// ----------------------------------------------------------------------
// FUNÇÃO PARA OBTER O ID ÚNICO DO DISPOSITIVO
// ----------------------------------------------------------------------
Future<String> getDeviceId() async {
  final prefs = await SharedPreferences.getInstance();
  String? id = prefs.getString("device_uuid");

  if (id == null) {
    id = const Uuid().v4(); // Gera um UUID novo
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
      appBar: AppBar(
        title: const Text("Sincronização de Dados"),
        backgroundColor: Colors.indigo,
      ),
      body: Container(
        padding: const EdgeInsets.all(24.0),
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_sync, size: 80, color: Colors.indigo),
              const SizedBox(height: 10),
              const Text(
                "Sincronizar Banco de Dados",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
              const SizedBox(height: 30),
              
              const Text(
                "ID:",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              // === FUTUREBUILDER: Exibe o ID Único ===
              FutureBuilder<String>(
                future: getDeviceId(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator(color: Colors.indigo);
                  } else if (snapshot.hasError) {
                    return Text('Erro: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                  } else if (snapshot.hasData) {
                    return SelectableText(
                      snapshot.data!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.deepOrange,
                        fontFamily: 'monospace'
                      ),
                    );
                  } else {
                    return const Text("Nenhum ID disponível.", style: TextStyle(color: Colors.black54));
                  }
                },
              ),

              const SizedBox(height: 50),
              ElevatedButton.icon(
                onPressed: () {
                  print('Iniciando sincronização...');
                },
                icon: const Icon(Icons.refresh),
                label: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Text("Iniciar Sincronização", style: TextStyle(fontSize: 18)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
