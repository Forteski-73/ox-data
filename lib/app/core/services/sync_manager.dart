import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:oxdata/db/app_database.dart';
import 'package:oxdata/db/daos/sync_queue_dao.dart';
import 'package:oxdata/db/tables/sync_queue.dart';
import 'package:flutter/foundation.dart';

/// Contrato com a API. Implemente isso usando seu cliente HTTP (Dio, http, etc).
/// Mantê-lo abstrato aqui permite testar o SyncManager com um fake/mock.
abstract class SyncApiClient {
  /// Envia uma entidade (insert/update/delete) para a API.
  /// Deve lançar uma exceção em caso de falha de rede ou erro do servidor
  /// — o SyncManager trata o retry, você não precisa.
  Future<void> pushEntity({
    required SyncEntityType entityType,
    required SyncOperation operation,
    required Map<String, dynamic> payload,
  });
  

  /// Verificação "de verdade" de internet (não apenas se há wifi/dados).
  /// Recomendo um HEAD request rápido para o seu próprio backend (ex.:
  /// GET /health) em vez de depender só do connectivity_plus, que só
  /// informa o tipo de interface de rede, não se ela tem internet de fato.
  Future<bool> hasRealConnection();
}

/// Orquestra a sincronização offline-first:
/// - escuta mudanças de conectividade
/// - ao detectar internet, processa a SyncQueue (push)
/// - aplica backoff exponencial e circuit breaker por item
/// - processa um item por vez, na ordem em que foram criados (FIFO),
///   mas a falha de um item NÃO bloqueia os demais
class SyncManager {
  final AppDatabase db;
  final SyncQueueDao queueDao;
  final SyncApiClient api;
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _periodicTimer;
  bool _isSyncing = false;

  final _statusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusController.stream;

  SyncManager({
    required this.db,
    required this.queueDao,
    required this.api,
    Connectivity? connectivity,
  }) : _connectivity = connectivity ?? Connectivity();

  /// Chame uma vez na inicialização do app (ex.: no main() ou em um provider).
  void start({Duration periodicCheck = const Duration(seconds: 30)}) { // <DIO> TEMPORIZADOR </DIO> 
    // sincroniza assim que muda de offline -> online
    _connectivitySub =
        _connectivity.onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) syncNow();
    });

    // rede de segurança: tenta periodicamente mesmo sem evento de
    // conectividade (cobre casos como wifi "conectado" mas sem internet
    // real que depois se resolve sozinho
    _periodicTimer = Timer.periodic(periodicCheck, (_) => syncNow());

    // tenta uma vez ao iniciar o app
    syncNow();
  }

  void dispose() {
    _connectivitySub?.cancel();
    _periodicTimer?.cancel();
    _statusController.close();
  }

  /// Pode ser chamado manualmente também (ex.: botão "sincronizar agora"
  /// ou pull-to-refresh na UI).
  Future<void> syncNow() async {
    
    
    debugPrint('📦 📦 📦 📦 📦 📦 📦 | ${DateTime.now()} -- SINCRONIZANDO: $_isSyncing');

    if (_isSyncing) return; // evita execuções concorrentes
    if (!await api.hasRealConnection()) {
      debugPrint('📦 📦 📦 📦 📦 📦 📦 TESTE DE INTERNET: $_isSyncing');
      return;
    }
    _isSyncing = true;
    _statusController.add(SyncStatus.syncing);
    try {
      final pendingBefore = await queueDao.getReadyToSync(limit: 200);
      int success = 0, failed = 0;

      // --- PRINT PARA LISTAS ---
      debugPrint('=================================================================');
      debugPrint('📦 [SyncQueueData] Total pendente: ${pendingBefore.length}');
      debugPrint('📦 Conteúdo da Lista: ${pendingBefore.map((item) => item.toJson()).toList()}');
      debugPrint('=================================================================');
      // -------------------------------------

      for (final item in pendingBefore) {
        final ok = await _processItem(item);
        ok ? success++ : failed++;
      }

      _statusController.add(
        failed == 0 ? SyncStatus.success : SyncStatus.partialFailure,
      );
    } catch (e) {
      _statusController.add(SyncStatus.error);
    } finally {
      _isSyncing = false;
    }
  }

  Future<bool> _processItem(SyncQueueData item) async {
    
    debugPrint('📦 📦 📦 [SyncQueueData] *************** Conteúdo completo do Item: ${item.toJson()}');

    try {
      // Monta o payload base
      Map<String, dynamic> payload = item.payload != null && item.payload != '{}'
          ? jsonDecode(item.payload!) as Map<String, dynamic>
          : {};

      // Para inventory, garante que inventCode e inventGuid estão no payload
      if (item.entityType == SyncEntityType.inventory) {
        payload = {
          ...payload,
          'inventCode': item.inventCode,
          'inventGuid': item.inventGuid,
        };
      }

      await api.pushEntity(
        entityType: item.entityType,
        operation:  item.operation,
        payload:    payload,
      );

      await db.transaction(() async {
        await queueDao.markSynced(item.id);
        if (item.operation != SyncOperation.delete) {
          await _markDomainRowSynced(item);
        }
      });
      return true;
    } catch (e) {
      await queueDao.markFailed(item.id, e.toString());
      return false;
    }
  }

Future<void> _markDomainRowSynced(SyncQueueData item) async {
    switch (item.entityType) {
      case SyncEntityType.inventory:
        // 1. Executa a atualização no banco
        await (db.update(db.inventory)
              ..where((t) => t.inventCode.equals(item.inventCode)))
            .write(const InventoryCompanion(isSynced: Value(true)));

        // 2. BUSCA O REGISTRO ATUALIZADO DO BANCO
        try {
          final updatedInventory = await (db.select(db.inventory)
                ..where((t) => t.inventCode.equals(item.inventCode)))
              .getSingleOrNull();

          if (updatedInventory != null) {
            debugPrint('📝 [DB_INVENTORY_ALTERADO] -> Código: ${item.inventCode}');
            debugPrint('📦 Dados Completos: ${updatedInventory.toJson()}');
          } else {
            debugPrint('⚠️ [DB_INVENTORY_ALTERADO] Registro não encontrado após o update para o código: ${item.inventCode}');
          }
        } catch (e) {
          debugPrint('❌ Erro ao tentar ler o inventário alterado para debug: $e');
        }
        break;

      case SyncEntityType.inventoryRecord:
        await (db.update(db.inventoryRecords)
              ..where((t) => t.id.equals(item.entityId)))
            .write(const InventoryRecordsCompanion(isSynced: Value(true)));
        break;
    }
  }

}

enum SyncStatus { idle, syncing, success, partialFailure, error }