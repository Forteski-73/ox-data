import 'dart:math';
import 'package:drift/drift.dart';
import 'package:oxdata/db/tables/sync_queue.dart';
import 'package:oxdata/db/app_database.dart';

part 'sync_queue_dao.g.dart';

@DriftAccessor(tables: [SyncQueue])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {
  SyncQueueDao(AppDatabase db) : super(db);

  static const Duration baseBackoff = Duration(seconds: 5);
  static const int maxRetries = 6; // ~5s,10s,20s,40s,80s,160s antes de desistir

  /// Insere ou atualiza (upsert) uma entrada pendente para a entidade.
  ///
  /// Se já existir uma entrada NÃO sincronizada para a mesma
  /// (entityType, entityId), ela é sobrescrita — assim múltiplas edições
  /// locais antes do próximo sync resultam em UMA única chamada de API
  /// com o estado mais recente, e a tentativa "reabre" (isSynced = false,
  /// retryCount = 0) mesmo que a entrada anterior já tivesse falhado.
  Future<void> enqueue({
    required SyncEntityType entityType,
    required int entityId,
    required String inventGuid,
    required String inventCode,
    required SyncOperation operation,
    String? payload,
    bool deleted = false,
  }) async {
    final existing = await (select(syncQueue)
          ..where((t) =>
              t.entityType.equalsValue(entityType) &
              t.entityId.equals(entityId)))
        .getSingleOrNull();

    if (existing == null) {
      await into(syncQueue).insert(SyncQueueCompanion.insert(
        entityType: entityType,
        entityId: entityId,
        inventGuid: inventGuid,
        inventCode: inventCode,
        operation: Value(operation),
        payload: Value(payload),
        deleted: Value(deleted),
      ));
    } else {
      await (update(syncQueue)..where((t) => t.id.equals(existing.id))).write(
        SyncQueueCompanion(
          operation: Value(operation),
          payload: Value(payload),
          deleted: Value(deleted),
          isSynced: const Value(false),
          retryCount: const Value(0),
          lastError: const Value(null),
          lastSyncAttempt: const Value(null),
        ),
      );
    }
  }

  /// Itens pendentes, em ordem de criação (FIFO), já filtrando os que
  /// estourou o número máximo de tentativas (circuit breaker) e os que
  /// ainda estão "esperando" o backoff exponencial.
  Future<List<SyncQueueData>> getReadyToSync({int limit = 50}) async {
    final all = await (select(syncQueue)
          ..where((t) =>
              t.isSynced.equals(false) & t.retryCount.isSmallerThanValue(maxRetries))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(limit))
        .get();

    return all.where(_isBackoffElapsed).toList();
  }

  bool _isBackoffElapsed(SyncQueueData item) {
    if (item.lastSyncAttempt == null) return true;
    final waitTime = baseBackoff * pow(2, item.retryCount).toInt();
    return DateTime.now().difference(item.lastSyncAttempt!) >= waitTime;
  }

  Future<void> markSynced(int id) {
    return (update(syncQueue)..where((t) => t.id.equals(id))).write(
      const SyncQueueCompanion(isSynced: Value(true), lastError: Value(null)),
    );
  }

  /// Registra falha de envio: incrementa retryCount e guarda o erro.
  /// Usa SQL direto pois Drift não tem "increment" nativo no Companion.
  Future<void> markFailed(int id, String error) async {
    await customStatement(
      'UPDATE sync_queue SET retry_count = retry_count + 1, '
      'last_sync_attempt = ?, last_error = ? WHERE id = ?',
      [DateTime.now().millisecondsSinceEpoch, error, id],
    );
  }

  /// Itens que esgotaram as tentativas — precisam de atenção manual
  /// (ex.: exibir um aviso na UI "3 itens não conseguiram sincronizar").
  Future<List<SyncQueueData>> getStuckItems() {
    return (select(syncQueue)
          ..where((t) =>
              t.isSynced.equals(false) &
              t.retryCount.isBiggerOrEqualValue(maxRetries)))
        .get();
  }

  /// Limpeza periódica: remove entradas já sincronizadas e antigas,
  /// para a tabela de fila não crescer indefinidamente.
  Future<int> purgeSynced({Duration olderThan = const Duration(days: 7)}) {
    final cutoff = DateTime.now().subtract(olderThan);
    return (delete(syncQueue)
          ..where((t) =>
              t.isSynced.equals(true) & t.createdAt.isSmallerThanValue(cutoff)))
        .go();
  }

  /// Stream para badge de UI ("3 itens pendentes de sincronização").
  Stream<int> watchPendingCount() {
    final countExp = syncQueue.id.count();
    final query = selectOnly(syncQueue)
      ..addColumns([countExp])
      ..where(syncQueue.isSynced.equals(false));
    return query.map((row) => row.read(countExp)!).watchSingle();
  }
}