import 'package:drift/drift.dart';

/// Tipos de entidade rastreados pela fila de sincronização.
/// Ao adicionar uma nova tabela sincronizável, adicione um valor aqui.
enum SyncEntityType {
  inventory,
  inventoryRecord,
}

/// Operação que originou a entrada na fila.
/// Importante para o backend saber se deve fazer INSERT, UPDATE ou DELETE.
enum SyncOperation {
  insert,
  update,
  delete,
}

/// SyncQueue — fila de saída (Outbox Pattern).
///
/// Toda alteração feita localmente (insert/update/delete) em uma tabela
/// sincronizável gera (ou atualiza) uma linha aqui. Um worker em background
/// lê essa fila quando há internet e envia para a API.
///
/// Regra de ouro: a escrita na tabela de domínio (Inventory, InventoryRecords)
/// e a escrita aqui DEVEM ocorrer na mesma transação do banco local.
/// Isso garante que não existe estado "gravei localmente mas esqueci de
/// marcar para sync" — são atômicos por construção.
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Qual tabela de domínio esse registro representa.
  TextColumn get entityType => textEnum<SyncEntityType>()();

  /// PK local da entidade (id do InventoryRecords, rowid do Inventory, etc.)
  IntColumn get entityId => integer()();

  /// GUID do dispositivo/inventário — útil para particionar a fila por
  /// dispositivo e para o backend identificar a origem do dado.
  TextColumn get inventGuid => text().withLength(min: 1, max: 36)();

  /// Código do inventário — útil para filtrar/agrupar a fila por inventário.
  TextColumn get inventCode => text().withLength(min: 1, max: 50)();

  /// Operação que gerou esta entrada (insert/update/delete).
  TextColumn get operation =>
      textEnum<SyncOperation>().withDefault(const Constant('insert'))();

  /// Snapshot do registro em JSON no momento da alteração.
  /// Evita ter que reconsultar a entidade original na hora do envio,
  /// e garante que o que é enviado é exatamente o estado que gerou a fila
  /// (mesmo que a entidade já tenha mudado novamente localmente).
  TextColumn get payload => text().nullable()();

  /// Marca exclusão lógica: o registro foi removido localmente e a API
  /// precisa ser notificada para remover (ou inativar) do lado dela.
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  /// Já foi confirmado pela API?
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  /// Quantas tentativas de envio já falharam (usado para backoff exponencial
  /// e para "desistir" de um item problemático sem travar a fila inteira).
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  DateTimeColumn get lastSyncAttempt => dateTime().nullable()();

  /// Última mensagem de erro — essencial para depurar sync silenciosamente
  /// quebrado em produção.
  TextColumn get lastError => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Garante UMA linha pendente por entidade: se o usuário editar o mesmo
  /// registro 5x antes de ter internet, a fila não cresce 5x — ela colapsa
  /// para o estado mais recente (UPSERT no DAO, ver sync_queue_dao.dart).
  @override
  List<Set<Column>> get uniqueKeys => [
        {entityType, entityId},
      ];
}