// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProductsTable extends Products with TableInfo<$ProductsTable, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 20,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<bool> status = GeneratedColumn<bool>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("status" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _lastSyncMeta = const VerificationMeta(
    'lastSync',
  );
  @override
  late final GeneratedColumn<DateTime> lastSync = GeneratedColumn<DateTime>(
    'last_sync',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    productId,
    barcode,
    productName,
    status,
    lastSync,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<Product> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    } else if (isInserting) {
      context.missing(_barcodeMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('last_sync')) {
      context.handle(
        _lastSyncMeta,
        lastSync.isAcceptableOrUnknown(data['last_sync']!, _lastSyncMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {productId};
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      )!,
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}status'],
      )!,
      lastSync: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync'],
      ),
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class Product extends DataClass implements Insertable<Product> {
  final String productId;
  final String barcode;
  final String productName;
  final bool status;
  final DateTime? lastSync;
  const Product({
    required this.productId,
    required this.barcode,
    required this.productName,
    required this.status,
    this.lastSync,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['product_id'] = Variable<String>(productId);
    map['barcode'] = Variable<String>(barcode);
    map['product_name'] = Variable<String>(productName);
    map['status'] = Variable<bool>(status);
    if (!nullToAbsent || lastSync != null) {
      map['last_sync'] = Variable<DateTime>(lastSync);
    }
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      productId: Value(productId),
      barcode: Value(barcode),
      productName: Value(productName),
      status: Value(status),
      lastSync: lastSync == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSync),
    );
  }

  factory Product.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      productId: serializer.fromJson<String>(json['productId']),
      barcode: serializer.fromJson<String>(json['barcode']),
      productName: serializer.fromJson<String>(json['productName']),
      status: serializer.fromJson<bool>(json['status']),
      lastSync: serializer.fromJson<DateTime?>(json['lastSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'productId': serializer.toJson<String>(productId),
      'barcode': serializer.toJson<String>(barcode),
      'productName': serializer.toJson<String>(productName),
      'status': serializer.toJson<bool>(status),
      'lastSync': serializer.toJson<DateTime?>(lastSync),
    };
  }

  Product copyWith({
    String? productId,
    String? barcode,
    String? productName,
    bool? status,
    Value<DateTime?> lastSync = const Value.absent(),
  }) => Product(
    productId: productId ?? this.productId,
    barcode: barcode ?? this.barcode,
    productName: productName ?? this.productName,
    status: status ?? this.status,
    lastSync: lastSync.present ? lastSync.value : this.lastSync,
  );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      productId: data.productId.present ? data.productId.value : this.productId,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      status: data.status.present ? data.status.value : this.status,
      lastSync: data.lastSync.present ? data.lastSync.value : this.lastSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('productId: $productId, ')
          ..write('barcode: $barcode, ')
          ..write('productName: $productName, ')
          ..write('status: $status, ')
          ..write('lastSync: $lastSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(productId, barcode, productName, status, lastSync);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.productId == this.productId &&
          other.barcode == this.barcode &&
          other.productName == this.productName &&
          other.status == this.status &&
          other.lastSync == this.lastSync);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<String> productId;
  final Value<String> barcode;
  final Value<String> productName;
  final Value<bool> status;
  final Value<DateTime?> lastSync;
  final Value<int> rowid;
  const ProductsCompanion({
    this.productId = const Value.absent(),
    this.barcode = const Value.absent(),
    this.productName = const Value.absent(),
    this.status = const Value.absent(),
    this.lastSync = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCompanion.insert({
    required String productId,
    required String barcode,
    required String productName,
    this.status = const Value.absent(),
    this.lastSync = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : productId = Value(productId),
       barcode = Value(barcode),
       productName = Value(productName);
  static Insertable<Product> custom({
    Expression<String>? productId,
    Expression<String>? barcode,
    Expression<String>? productName,
    Expression<bool>? status,
    Expression<DateTime>? lastSync,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (productId != null) 'product_id': productId,
      if (barcode != null) 'barcode': barcode,
      if (productName != null) 'product_name': productName,
      if (status != null) 'status': status,
      if (lastSync != null) 'last_sync': lastSync,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCompanion copyWith({
    Value<String>? productId,
    Value<String>? barcode,
    Value<String>? productName,
    Value<bool>? status,
    Value<DateTime?>? lastSync,
    Value<int>? rowid,
  }) {
    return ProductsCompanion(
      productId: productId ?? this.productId,
      barcode: barcode ?? this.barcode,
      productName: productName ?? this.productName,
      status: status ?? this.status,
      lastSync: lastSync ?? this.lastSync,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (status.present) {
      map['status'] = Variable<bool>(status.value);
    }
    if (lastSync.present) {
      map['last_sync'] = Variable<DateTime>(lastSync.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('productId: $productId, ')
          ..write('barcode: $barcode, ')
          ..write('productName: $productName, ')
          ..write('status: $status, ')
          ..write('lastSync: $lastSync, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeviceSyncTable extends DeviceSync
    with TableInfo<$DeviceSyncTable, DeviceSyncData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeviceSyncTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _guidMeta = const VerificationMeta('guid');
  @override
  late final GeneratedColumn<String> guid = GeneratedColumn<String>(
    'guid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TypeWork, String> typeWork =
      GeneratedColumn<String>(
        'type_work',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TypeWork>($DeviceSyncTable.$convertertypeWork);
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncMeta = const VerificationMeta(
    'lastSync',
  );
  @override
  late final GeneratedColumn<DateTime> lastSync = GeneratedColumn<DateTime>(
    'last_sync',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userMeta = const VerificationMeta('user');
  @override
  late final GeneratedColumn<String> user = GeneratedColumn<String>(
    'user',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    guid,
    typeWork,
    version,
    lastSync,
    user,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'device_sync';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeviceSyncData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('guid')) {
      context.handle(
        _guidMeta,
        guid.isAcceptableOrUnknown(data['guid']!, _guidMeta),
      );
    } else if (isInserting) {
      context.missing(_guidMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('last_sync')) {
      context.handle(
        _lastSyncMeta,
        lastSync.isAcceptableOrUnknown(data['last_sync']!, _lastSyncMeta),
      );
    }
    if (data.containsKey('user')) {
      context.handle(
        _userMeta,
        user.isAcceptableOrUnknown(data['user']!, _userMeta),
      );
    } else if (isInserting) {
      context.missing(_userMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {guid, typeWork};
  @override
  DeviceSyncData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeviceSyncData(
      guid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}guid'],
      )!,
      typeWork: $DeviceSyncTable.$convertertypeWork.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type_work'],
        )!,
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      lastSync: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync'],
      ),
      user: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user'],
      )!,
    );
  }

  @override
  $DeviceSyncTable createAlias(String alias) {
    return $DeviceSyncTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TypeWork, String, String> $convertertypeWork =
      const EnumNameConverter<TypeWork>(TypeWork.values);
}

class DeviceSyncData extends DataClass implements Insertable<DeviceSyncData> {
  final String guid;
  final TypeWork typeWork;
  final int version;
  final DateTime? lastSync;
  final String user;
  const DeviceSyncData({
    required this.guid,
    required this.typeWork,
    required this.version,
    this.lastSync,
    required this.user,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['guid'] = Variable<String>(guid);
    {
      map['type_work'] = Variable<String>(
        $DeviceSyncTable.$convertertypeWork.toSql(typeWork),
      );
    }
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || lastSync != null) {
      map['last_sync'] = Variable<DateTime>(lastSync);
    }
    map['user'] = Variable<String>(user);
    return map;
  }

  DeviceSyncCompanion toCompanion(bool nullToAbsent) {
    return DeviceSyncCompanion(
      guid: Value(guid),
      typeWork: Value(typeWork),
      version: Value(version),
      lastSync: lastSync == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSync),
      user: Value(user),
    );
  }

  factory DeviceSyncData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeviceSyncData(
      guid: serializer.fromJson<String>(json['guid']),
      typeWork: $DeviceSyncTable.$convertertypeWork.fromJson(
        serializer.fromJson<String>(json['typeWork']),
      ),
      version: serializer.fromJson<int>(json['version']),
      lastSync: serializer.fromJson<DateTime?>(json['lastSync']),
      user: serializer.fromJson<String>(json['user']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'guid': serializer.toJson<String>(guid),
      'typeWork': serializer.toJson<String>(
        $DeviceSyncTable.$convertertypeWork.toJson(typeWork),
      ),
      'version': serializer.toJson<int>(version),
      'lastSync': serializer.toJson<DateTime?>(lastSync),
      'user': serializer.toJson<String>(user),
    };
  }

  DeviceSyncData copyWith({
    String? guid,
    TypeWork? typeWork,
    int? version,
    Value<DateTime?> lastSync = const Value.absent(),
    String? user,
  }) => DeviceSyncData(
    guid: guid ?? this.guid,
    typeWork: typeWork ?? this.typeWork,
    version: version ?? this.version,
    lastSync: lastSync.present ? lastSync.value : this.lastSync,
    user: user ?? this.user,
  );
  DeviceSyncData copyWithCompanion(DeviceSyncCompanion data) {
    return DeviceSyncData(
      guid: data.guid.present ? data.guid.value : this.guid,
      typeWork: data.typeWork.present ? data.typeWork.value : this.typeWork,
      version: data.version.present ? data.version.value : this.version,
      lastSync: data.lastSync.present ? data.lastSync.value : this.lastSync,
      user: data.user.present ? data.user.value : this.user,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeviceSyncData(')
          ..write('guid: $guid, ')
          ..write('typeWork: $typeWork, ')
          ..write('version: $version, ')
          ..write('lastSync: $lastSync, ')
          ..write('user: $user')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(guid, typeWork, version, lastSync, user);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeviceSyncData &&
          other.guid == this.guid &&
          other.typeWork == this.typeWork &&
          other.version == this.version &&
          other.lastSync == this.lastSync &&
          other.user == this.user);
}

class DeviceSyncCompanion extends UpdateCompanion<DeviceSyncData> {
  final Value<String> guid;
  final Value<TypeWork> typeWork;
  final Value<int> version;
  final Value<DateTime?> lastSync;
  final Value<String> user;
  final Value<int> rowid;
  const DeviceSyncCompanion({
    this.guid = const Value.absent(),
    this.typeWork = const Value.absent(),
    this.version = const Value.absent(),
    this.lastSync = const Value.absent(),
    this.user = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeviceSyncCompanion.insert({
    required String guid,
    required TypeWork typeWork,
    required int version,
    this.lastSync = const Value.absent(),
    required String user,
    this.rowid = const Value.absent(),
  }) : guid = Value(guid),
       typeWork = Value(typeWork),
       version = Value(version),
       user = Value(user);
  static Insertable<DeviceSyncData> custom({
    Expression<String>? guid,
    Expression<String>? typeWork,
    Expression<int>? version,
    Expression<DateTime>? lastSync,
    Expression<String>? user,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (guid != null) 'guid': guid,
      if (typeWork != null) 'type_work': typeWork,
      if (version != null) 'version': version,
      if (lastSync != null) 'last_sync': lastSync,
      if (user != null) 'user': user,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeviceSyncCompanion copyWith({
    Value<String>? guid,
    Value<TypeWork>? typeWork,
    Value<int>? version,
    Value<DateTime?>? lastSync,
    Value<String>? user,
    Value<int>? rowid,
  }) {
    return DeviceSyncCompanion(
      guid: guid ?? this.guid,
      typeWork: typeWork ?? this.typeWork,
      version: version ?? this.version,
      lastSync: lastSync ?? this.lastSync,
      user: user ?? this.user,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (guid.present) {
      map['guid'] = Variable<String>(guid.value);
    }
    if (typeWork.present) {
      map['type_work'] = Variable<String>(
        $DeviceSyncTable.$convertertypeWork.toSql(typeWork.value),
      );
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (lastSync.present) {
      map['last_sync'] = Variable<DateTime>(lastSync.value);
    }
    if (user.present) {
      map['user'] = Variable<String>(user.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeviceSyncCompanion(')
          ..write('guid: $guid, ')
          ..write('typeWork: $typeWork, ')
          ..write('version: $version, ')
          ..write('lastSync: $lastSync, ')
          ..write('user: $user, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InventoryMaskTable extends InventoryMask
    with TableInfo<$InventoryMaskTable, InventoryMaskData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryMaskTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _maskIdMeta = const VerificationMeta('maskId');
  @override
  late final GeneratedColumn<int> maskId = GeneratedColumn<int>(
    'mask_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<MaskFieldName, String> fieldName =
      GeneratedColumn<String>(
        'field_name',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MaskFieldName>($InventoryMaskTable.$converterfieldName);
  static const VerificationMeta _fieldMaskMeta = const VerificationMeta(
    'fieldMask',
  );
  @override
  late final GeneratedColumn<String> fieldMask = GeneratedColumn<String>(
    'field_mask',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [maskId, fieldName, fieldMask];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_mask';
  @override
  VerificationContext validateIntegrity(
    Insertable<InventoryMaskData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('mask_id')) {
      context.handle(
        _maskIdMeta,
        maskId.isAcceptableOrUnknown(data['mask_id']!, _maskIdMeta),
      );
    }
    if (data.containsKey('field_mask')) {
      context.handle(
        _fieldMaskMeta,
        fieldMask.isAcceptableOrUnknown(data['field_mask']!, _fieldMaskMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldMaskMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {maskId};
  @override
  InventoryMaskData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryMaskData(
      maskId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mask_id'],
      )!,
      fieldName: $InventoryMaskTable.$converterfieldName.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}field_name'],
        )!,
      ),
      fieldMask: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_mask'],
      )!,
    );
  }

  @override
  $InventoryMaskTable createAlias(String alias) {
    return $InventoryMaskTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MaskFieldName, String, String> $converterfieldName =
      const EnumNameConverter<MaskFieldName>(MaskFieldName.values);
}

class InventoryMaskData extends DataClass
    implements Insertable<InventoryMaskData> {
  final int maskId;
  final MaskFieldName fieldName;
  final String fieldMask;
  const InventoryMaskData({
    required this.maskId,
    required this.fieldName,
    required this.fieldMask,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['mask_id'] = Variable<int>(maskId);
    {
      map['field_name'] = Variable<String>(
        $InventoryMaskTable.$converterfieldName.toSql(fieldName),
      );
    }
    map['field_mask'] = Variable<String>(fieldMask);
    return map;
  }

  InventoryMaskCompanion toCompanion(bool nullToAbsent) {
    return InventoryMaskCompanion(
      maskId: Value(maskId),
      fieldName: Value(fieldName),
      fieldMask: Value(fieldMask),
    );
  }

  factory InventoryMaskData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryMaskData(
      maskId: serializer.fromJson<int>(json['maskId']),
      fieldName: $InventoryMaskTable.$converterfieldName.fromJson(
        serializer.fromJson<String>(json['fieldName']),
      ),
      fieldMask: serializer.fromJson<String>(json['fieldMask']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'maskId': serializer.toJson<int>(maskId),
      'fieldName': serializer.toJson<String>(
        $InventoryMaskTable.$converterfieldName.toJson(fieldName),
      ),
      'fieldMask': serializer.toJson<String>(fieldMask),
    };
  }

  InventoryMaskData copyWith({
    int? maskId,
    MaskFieldName? fieldName,
    String? fieldMask,
  }) => InventoryMaskData(
    maskId: maskId ?? this.maskId,
    fieldName: fieldName ?? this.fieldName,
    fieldMask: fieldMask ?? this.fieldMask,
  );
  InventoryMaskData copyWithCompanion(InventoryMaskCompanion data) {
    return InventoryMaskData(
      maskId: data.maskId.present ? data.maskId.value : this.maskId,
      fieldName: data.fieldName.present ? data.fieldName.value : this.fieldName,
      fieldMask: data.fieldMask.present ? data.fieldMask.value : this.fieldMask,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryMaskData(')
          ..write('maskId: $maskId, ')
          ..write('fieldName: $fieldName, ')
          ..write('fieldMask: $fieldMask')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(maskId, fieldName, fieldMask);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryMaskData &&
          other.maskId == this.maskId &&
          other.fieldName == this.fieldName &&
          other.fieldMask == this.fieldMask);
}

class InventoryMaskCompanion extends UpdateCompanion<InventoryMaskData> {
  final Value<int> maskId;
  final Value<MaskFieldName> fieldName;
  final Value<String> fieldMask;
  const InventoryMaskCompanion({
    this.maskId = const Value.absent(),
    this.fieldName = const Value.absent(),
    this.fieldMask = const Value.absent(),
  });
  InventoryMaskCompanion.insert({
    this.maskId = const Value.absent(),
    required MaskFieldName fieldName,
    required String fieldMask,
  }) : fieldName = Value(fieldName),
       fieldMask = Value(fieldMask);
  static Insertable<InventoryMaskData> custom({
    Expression<int>? maskId,
    Expression<String>? fieldName,
    Expression<String>? fieldMask,
  }) {
    return RawValuesInsertable({
      if (maskId != null) 'mask_id': maskId,
      if (fieldName != null) 'field_name': fieldName,
      if (fieldMask != null) 'field_mask': fieldMask,
    });
  }

  InventoryMaskCompanion copyWith({
    Value<int>? maskId,
    Value<MaskFieldName>? fieldName,
    Value<String>? fieldMask,
  }) {
    return InventoryMaskCompanion(
      maskId: maskId ?? this.maskId,
      fieldName: fieldName ?? this.fieldName,
      fieldMask: fieldMask ?? this.fieldMask,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (maskId.present) {
      map['mask_id'] = Variable<int>(maskId.value);
    }
    if (fieldName.present) {
      map['field_name'] = Variable<String>(
        $InventoryMaskTable.$converterfieldName.toSql(fieldName.value),
      );
    }
    if (fieldMask.present) {
      map['field_mask'] = Variable<String>(fieldMask.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryMaskCompanion(')
          ..write('maskId: $maskId, ')
          ..write('fieldName: $fieldName, ')
          ..write('fieldMask: $fieldMask')
          ..write(')'))
        .toString();
  }
}

class $InventoryTable extends Inventory
    with TableInfo<$InventoryTable, InventoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _inventCodeMeta = const VerificationMeta(
    'inventCode',
  );
  @override
  late final GeneratedColumn<String> inventCode = GeneratedColumn<String>(
    'invent_code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inventNameMeta = const VerificationMeta(
    'inventName',
  );
  @override
  late final GeneratedColumn<String> inventName = GeneratedColumn<String>(
    'invent_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inventGuidMeta = const VerificationMeta(
    'inventGuid',
  );
  @override
  late final GeneratedColumn<String> inventGuid = GeneratedColumn<String>(
    'invent_guid',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inventSectorMeta = const VerificationMeta(
    'inventSector',
  );
  @override
  late final GeneratedColumn<String> inventSector = GeneratedColumn<String>(
    'invent_sector',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inventCreatedMeta = const VerificationMeta(
    'inventCreated',
  );
  @override
  late final GeneratedColumn<DateTime> inventCreated =
      GeneratedColumn<DateTime>(
        'invent_created',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _inventUserMeta = const VerificationMeta(
    'inventUser',
  );
  @override
  late final GeneratedColumn<String> inventUser = GeneratedColumn<String>(
    'invent_user',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<InventoryStatus, String>
  inventStatus = GeneratedColumn<String>(
    'invent_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<InventoryStatus>($InventoryTable.$converterinventStatus);
  static const VerificationMeta _inventTotalMeta = const VerificationMeta(
    'inventTotal',
  );
  @override
  late final GeneratedColumn<double> inventTotal = GeneratedColumn<double>(
    'invent_total',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastSyncAttemptMeta = const VerificationMeta(
    'lastSyncAttempt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAttempt =
      GeneratedColumn<DateTime>(
        'last_sync_attempt',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    inventCode,
    inventName,
    inventGuid,
    inventSector,
    inventCreated,
    inventUser,
    inventStatus,
    inventTotal,
    isSynced,
    lastSyncAttempt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory';
  @override
  VerificationContext validateIntegrity(
    Insertable<InventoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('invent_code')) {
      context.handle(
        _inventCodeMeta,
        inventCode.isAcceptableOrUnknown(data['invent_code']!, _inventCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_inventCodeMeta);
    }
    if (data.containsKey('invent_name')) {
      context.handle(
        _inventNameMeta,
        inventName.isAcceptableOrUnknown(data['invent_name']!, _inventNameMeta),
      );
    } else if (isInserting) {
      context.missing(_inventNameMeta);
    }
    if (data.containsKey('invent_guid')) {
      context.handle(
        _inventGuidMeta,
        inventGuid.isAcceptableOrUnknown(data['invent_guid']!, _inventGuidMeta),
      );
    } else if (isInserting) {
      context.missing(_inventGuidMeta);
    }
    if (data.containsKey('invent_sector')) {
      context.handle(
        _inventSectorMeta,
        inventSector.isAcceptableOrUnknown(
          data['invent_sector']!,
          _inventSectorMeta,
        ),
      );
    }
    if (data.containsKey('invent_created')) {
      context.handle(
        _inventCreatedMeta,
        inventCreated.isAcceptableOrUnknown(
          data['invent_created']!,
          _inventCreatedMeta,
        ),
      );
    }
    if (data.containsKey('invent_user')) {
      context.handle(
        _inventUserMeta,
        inventUser.isAcceptableOrUnknown(data['invent_user']!, _inventUserMeta),
      );
    }
    if (data.containsKey('invent_total')) {
      context.handle(
        _inventTotalMeta,
        inventTotal.isAcceptableOrUnknown(
          data['invent_total']!,
          _inventTotalMeta,
        ),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('last_sync_attempt')) {
      context.handle(
        _lastSyncAttemptMeta,
        lastSyncAttempt.isAcceptableOrUnknown(
          data['last_sync_attempt']!,
          _lastSyncAttemptMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {inventCode};
  @override
  InventoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryData(
      inventCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invent_code'],
      )!,
      inventName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invent_name'],
      )!,
      inventGuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invent_guid'],
      )!,
      inventSector: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invent_sector'],
      ),
      inventCreated: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}invent_created'],
      ),
      inventUser: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invent_user'],
      ),
      inventStatus: $InventoryTable.$converterinventStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}invent_status'],
        )!,
      ),
      inventTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}invent_total'],
      ),
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      lastSyncAttempt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_attempt'],
      ),
    );
  }

  @override
  $InventoryTable createAlias(String alias) {
    return $InventoryTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<InventoryStatus, String, String>
  $converterinventStatus = const EnumNameConverter<InventoryStatus>(
    InventoryStatus.values,
  );
}

class InventoryData extends DataClass implements Insertable<InventoryData> {
  /// Código do inventário (PK – igual API)
  final String inventCode;

  /// Nome do inventário
  final String inventName;

  /// GUID do dispositivo / inventário
  final String inventGuid;

  /// Setor
  final String? inventSector;

  /// Data de criação
  final DateTime? inventCreated;

  /// Usuário
  final String? inventUser;

  /// Status do inventário (ENUM)
  final InventoryStatus inventStatus;

  /// Total contado
  final double? inventTotal;

  /// 🔑 CONTROLE OFFLINE
  /// Indica se já foi sincronizado com a API
  final bool isSynced;

  /// Data da última tentativa de sync
  final DateTime? lastSyncAttempt;
  const InventoryData({
    required this.inventCode,
    required this.inventName,
    required this.inventGuid,
    this.inventSector,
    this.inventCreated,
    this.inventUser,
    required this.inventStatus,
    this.inventTotal,
    required this.isSynced,
    this.lastSyncAttempt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['invent_code'] = Variable<String>(inventCode);
    map['invent_name'] = Variable<String>(inventName);
    map['invent_guid'] = Variable<String>(inventGuid);
    if (!nullToAbsent || inventSector != null) {
      map['invent_sector'] = Variable<String>(inventSector);
    }
    if (!nullToAbsent || inventCreated != null) {
      map['invent_created'] = Variable<DateTime>(inventCreated);
    }
    if (!nullToAbsent || inventUser != null) {
      map['invent_user'] = Variable<String>(inventUser);
    }
    {
      map['invent_status'] = Variable<String>(
        $InventoryTable.$converterinventStatus.toSql(inventStatus),
      );
    }
    if (!nullToAbsent || inventTotal != null) {
      map['invent_total'] = Variable<double>(inventTotal);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    if (!nullToAbsent || lastSyncAttempt != null) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt);
    }
    return map;
  }

  InventoryCompanion toCompanion(bool nullToAbsent) {
    return InventoryCompanion(
      inventCode: Value(inventCode),
      inventName: Value(inventName),
      inventGuid: Value(inventGuid),
      inventSector: inventSector == null && nullToAbsent
          ? const Value.absent()
          : Value(inventSector),
      inventCreated: inventCreated == null && nullToAbsent
          ? const Value.absent()
          : Value(inventCreated),
      inventUser: inventUser == null && nullToAbsent
          ? const Value.absent()
          : Value(inventUser),
      inventStatus: Value(inventStatus),
      inventTotal: inventTotal == null && nullToAbsent
          ? const Value.absent()
          : Value(inventTotal),
      isSynced: Value(isSynced),
      lastSyncAttempt: lastSyncAttempt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAttempt),
    );
  }

  factory InventoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryData(
      inventCode: serializer.fromJson<String>(json['inventCode']),
      inventName: serializer.fromJson<String>(json['inventName']),
      inventGuid: serializer.fromJson<String>(json['inventGuid']),
      inventSector: serializer.fromJson<String?>(json['inventSector']),
      inventCreated: serializer.fromJson<DateTime?>(json['inventCreated']),
      inventUser: serializer.fromJson<String?>(json['inventUser']),
      inventStatus: $InventoryTable.$converterinventStatus.fromJson(
        serializer.fromJson<String>(json['inventStatus']),
      ),
      inventTotal: serializer.fromJson<double?>(json['inventTotal']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      lastSyncAttempt: serializer.fromJson<DateTime?>(json['lastSyncAttempt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'inventCode': serializer.toJson<String>(inventCode),
      'inventName': serializer.toJson<String>(inventName),
      'inventGuid': serializer.toJson<String>(inventGuid),
      'inventSector': serializer.toJson<String?>(inventSector),
      'inventCreated': serializer.toJson<DateTime?>(inventCreated),
      'inventUser': serializer.toJson<String?>(inventUser),
      'inventStatus': serializer.toJson<String>(
        $InventoryTable.$converterinventStatus.toJson(inventStatus),
      ),
      'inventTotal': serializer.toJson<double?>(inventTotal),
      'isSynced': serializer.toJson<bool>(isSynced),
      'lastSyncAttempt': serializer.toJson<DateTime?>(lastSyncAttempt),
    };
  }

  InventoryData copyWith({
    String? inventCode,
    String? inventName,
    String? inventGuid,
    Value<String?> inventSector = const Value.absent(),
    Value<DateTime?> inventCreated = const Value.absent(),
    Value<String?> inventUser = const Value.absent(),
    InventoryStatus? inventStatus,
    Value<double?> inventTotal = const Value.absent(),
    bool? isSynced,
    Value<DateTime?> lastSyncAttempt = const Value.absent(),
  }) => InventoryData(
    inventCode: inventCode ?? this.inventCode,
    inventName: inventName ?? this.inventName,
    inventGuid: inventGuid ?? this.inventGuid,
    inventSector: inventSector.present ? inventSector.value : this.inventSector,
    inventCreated: inventCreated.present
        ? inventCreated.value
        : this.inventCreated,
    inventUser: inventUser.present ? inventUser.value : this.inventUser,
    inventStatus: inventStatus ?? this.inventStatus,
    inventTotal: inventTotal.present ? inventTotal.value : this.inventTotal,
    isSynced: isSynced ?? this.isSynced,
    lastSyncAttempt: lastSyncAttempt.present
        ? lastSyncAttempt.value
        : this.lastSyncAttempt,
  );
  InventoryData copyWithCompanion(InventoryCompanion data) {
    return InventoryData(
      inventCode: data.inventCode.present
          ? data.inventCode.value
          : this.inventCode,
      inventName: data.inventName.present
          ? data.inventName.value
          : this.inventName,
      inventGuid: data.inventGuid.present
          ? data.inventGuid.value
          : this.inventGuid,
      inventSector: data.inventSector.present
          ? data.inventSector.value
          : this.inventSector,
      inventCreated: data.inventCreated.present
          ? data.inventCreated.value
          : this.inventCreated,
      inventUser: data.inventUser.present
          ? data.inventUser.value
          : this.inventUser,
      inventStatus: data.inventStatus.present
          ? data.inventStatus.value
          : this.inventStatus,
      inventTotal: data.inventTotal.present
          ? data.inventTotal.value
          : this.inventTotal,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      lastSyncAttempt: data.lastSyncAttempt.present
          ? data.lastSyncAttempt.value
          : this.lastSyncAttempt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryData(')
          ..write('inventCode: $inventCode, ')
          ..write('inventName: $inventName, ')
          ..write('inventGuid: $inventGuid, ')
          ..write('inventSector: $inventSector, ')
          ..write('inventCreated: $inventCreated, ')
          ..write('inventUser: $inventUser, ')
          ..write('inventStatus: $inventStatus, ')
          ..write('inventTotal: $inventTotal, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastSyncAttempt: $lastSyncAttempt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    inventCode,
    inventName,
    inventGuid,
    inventSector,
    inventCreated,
    inventUser,
    inventStatus,
    inventTotal,
    isSynced,
    lastSyncAttempt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryData &&
          other.inventCode == this.inventCode &&
          other.inventName == this.inventName &&
          other.inventGuid == this.inventGuid &&
          other.inventSector == this.inventSector &&
          other.inventCreated == this.inventCreated &&
          other.inventUser == this.inventUser &&
          other.inventStatus == this.inventStatus &&
          other.inventTotal == this.inventTotal &&
          other.isSynced == this.isSynced &&
          other.lastSyncAttempt == this.lastSyncAttempt);
}

class InventoryCompanion extends UpdateCompanion<InventoryData> {
  final Value<String> inventCode;
  final Value<String> inventName;
  final Value<String> inventGuid;
  final Value<String?> inventSector;
  final Value<DateTime?> inventCreated;
  final Value<String?> inventUser;
  final Value<InventoryStatus> inventStatus;
  final Value<double?> inventTotal;
  final Value<bool> isSynced;
  final Value<DateTime?> lastSyncAttempt;
  final Value<int> rowid;
  const InventoryCompanion({
    this.inventCode = const Value.absent(),
    this.inventName = const Value.absent(),
    this.inventGuid = const Value.absent(),
    this.inventSector = const Value.absent(),
    this.inventCreated = const Value.absent(),
    this.inventUser = const Value.absent(),
    this.inventStatus = const Value.absent(),
    this.inventTotal = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InventoryCompanion.insert({
    required String inventCode,
    required String inventName,
    required String inventGuid,
    this.inventSector = const Value.absent(),
    this.inventCreated = const Value.absent(),
    this.inventUser = const Value.absent(),
    required InventoryStatus inventStatus,
    this.inventTotal = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : inventCode = Value(inventCode),
       inventName = Value(inventName),
       inventGuid = Value(inventGuid),
       inventStatus = Value(inventStatus);
  static Insertable<InventoryData> custom({
    Expression<String>? inventCode,
    Expression<String>? inventName,
    Expression<String>? inventGuid,
    Expression<String>? inventSector,
    Expression<DateTime>? inventCreated,
    Expression<String>? inventUser,
    Expression<String>? inventStatus,
    Expression<double>? inventTotal,
    Expression<bool>? isSynced,
    Expression<DateTime>? lastSyncAttempt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (inventCode != null) 'invent_code': inventCode,
      if (inventName != null) 'invent_name': inventName,
      if (inventGuid != null) 'invent_guid': inventGuid,
      if (inventSector != null) 'invent_sector': inventSector,
      if (inventCreated != null) 'invent_created': inventCreated,
      if (inventUser != null) 'invent_user': inventUser,
      if (inventStatus != null) 'invent_status': inventStatus,
      if (inventTotal != null) 'invent_total': inventTotal,
      if (isSynced != null) 'is_synced': isSynced,
      if (lastSyncAttempt != null) 'last_sync_attempt': lastSyncAttempt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InventoryCompanion copyWith({
    Value<String>? inventCode,
    Value<String>? inventName,
    Value<String>? inventGuid,
    Value<String?>? inventSector,
    Value<DateTime?>? inventCreated,
    Value<String?>? inventUser,
    Value<InventoryStatus>? inventStatus,
    Value<double?>? inventTotal,
    Value<bool>? isSynced,
    Value<DateTime?>? lastSyncAttempt,
    Value<int>? rowid,
  }) {
    return InventoryCompanion(
      inventCode: inventCode ?? this.inventCode,
      inventName: inventName ?? this.inventName,
      inventGuid: inventGuid ?? this.inventGuid,
      inventSector: inventSector ?? this.inventSector,
      inventCreated: inventCreated ?? this.inventCreated,
      inventUser: inventUser ?? this.inventUser,
      inventStatus: inventStatus ?? this.inventStatus,
      inventTotal: inventTotal ?? this.inventTotal,
      isSynced: isSynced ?? this.isSynced,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (inventCode.present) {
      map['invent_code'] = Variable<String>(inventCode.value);
    }
    if (inventName.present) {
      map['invent_name'] = Variable<String>(inventName.value);
    }
    if (inventGuid.present) {
      map['invent_guid'] = Variable<String>(inventGuid.value);
    }
    if (inventSector.present) {
      map['invent_sector'] = Variable<String>(inventSector.value);
    }
    if (inventCreated.present) {
      map['invent_created'] = Variable<DateTime>(inventCreated.value);
    }
    if (inventUser.present) {
      map['invent_user'] = Variable<String>(inventUser.value);
    }
    if (inventStatus.present) {
      map['invent_status'] = Variable<String>(
        $InventoryTable.$converterinventStatus.toSql(inventStatus.value),
      );
    }
    if (inventTotal.present) {
      map['invent_total'] = Variable<double>(inventTotal.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (lastSyncAttempt.present) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryCompanion(')
          ..write('inventCode: $inventCode, ')
          ..write('inventName: $inventName, ')
          ..write('inventGuid: $inventGuid, ')
          ..write('inventSector: $inventSector, ')
          ..write('inventCreated: $inventCreated, ')
          ..write('inventUser: $inventUser, ')
          ..write('inventStatus: $inventStatus, ')
          ..write('inventTotal: $inventTotal, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastSyncAttempt: $lastSyncAttempt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InventoryRecordsTable extends InventoryRecords
    with TableInfo<$InventoryRecordsTable, InventoryRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _inventCodeMeta = const VerificationMeta(
    'inventCode',
  );
  @override
  late final GeneratedColumn<String> inventCode = GeneratedColumn<String>(
    'invent_code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES inventory (invent_code)',
    ),
  );
  static const VerificationMeta _inventCreatedMeta = const VerificationMeta(
    'inventCreated',
  );
  @override
  late final GeneratedColumn<DateTime> inventCreated =
      GeneratedColumn<DateTime>(
        'invent_created',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _inventUserMeta = const VerificationMeta(
    'inventUser',
  );
  @override
  late final GeneratedColumn<String> inventUser = GeneratedColumn<String>(
    'invent_user',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inventUnitizerMeta = const VerificationMeta(
    'inventUnitizer',
  );
  @override
  late final GeneratedColumn<String> inventUnitizer = GeneratedColumn<String>(
    'invent_unitizer',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inventLocationMeta = const VerificationMeta(
    'inventLocation',
  );
  @override
  late final GeneratedColumn<String> inventLocation = GeneratedColumn<String>(
    'invent_location',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inventProductMeta = const VerificationMeta(
    'inventProduct',
  );
  @override
  late final GeneratedColumn<String> inventProduct = GeneratedColumn<String>(
    'invent_product',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inventBarcodeMeta = const VerificationMeta(
    'inventBarcode',
  );
  @override
  late final GeneratedColumn<String> inventBarcode = GeneratedColumn<String>(
    'invent_barcode',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inventStandardStackMeta =
      const VerificationMeta('inventStandardStack');
  @override
  late final GeneratedColumn<int> inventStandardStack = GeneratedColumn<int>(
    'invent_standard_stack',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inventQtdStackMeta = const VerificationMeta(
    'inventQtdStack',
  );
  @override
  late final GeneratedColumn<int> inventQtdStack = GeneratedColumn<int>(
    'invent_qtd_stack',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inventQtdIndividualMeta =
      const VerificationMeta('inventQtdIndividual');
  @override
  late final GeneratedColumn<double> inventQtdIndividual =
      GeneratedColumn<double>(
        'invent_qtd_individual',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _inventTotalMeta = const VerificationMeta(
    'inventTotal',
  );
  @override
  late final GeneratedColumn<double> inventTotal = GeneratedColumn<double>(
    'invent_total',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastSyncAttemptMeta = const VerificationMeta(
    'lastSyncAttempt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAttempt =
      GeneratedColumn<DateTime>(
        'last_sync_attempt',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    inventCode,
    inventCreated,
    inventUser,
    inventUnitizer,
    inventLocation,
    inventProduct,
    inventBarcode,
    inventStandardStack,
    inventQtdStack,
    inventQtdIndividual,
    inventTotal,
    isSynced,
    lastSyncAttempt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<InventoryRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('invent_code')) {
      context.handle(
        _inventCodeMeta,
        inventCode.isAcceptableOrUnknown(data['invent_code']!, _inventCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_inventCodeMeta);
    }
    if (data.containsKey('invent_created')) {
      context.handle(
        _inventCreatedMeta,
        inventCreated.isAcceptableOrUnknown(
          data['invent_created']!,
          _inventCreatedMeta,
        ),
      );
    }
    if (data.containsKey('invent_user')) {
      context.handle(
        _inventUserMeta,
        inventUser.isAcceptableOrUnknown(data['invent_user']!, _inventUserMeta),
      );
    }
    if (data.containsKey('invent_unitizer')) {
      context.handle(
        _inventUnitizerMeta,
        inventUnitizer.isAcceptableOrUnknown(
          data['invent_unitizer']!,
          _inventUnitizerMeta,
        ),
      );
    }
    if (data.containsKey('invent_location')) {
      context.handle(
        _inventLocationMeta,
        inventLocation.isAcceptableOrUnknown(
          data['invent_location']!,
          _inventLocationMeta,
        ),
      );
    }
    if (data.containsKey('invent_product')) {
      context.handle(
        _inventProductMeta,
        inventProduct.isAcceptableOrUnknown(
          data['invent_product']!,
          _inventProductMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inventProductMeta);
    }
    if (data.containsKey('invent_barcode')) {
      context.handle(
        _inventBarcodeMeta,
        inventBarcode.isAcceptableOrUnknown(
          data['invent_barcode']!,
          _inventBarcodeMeta,
        ),
      );
    }
    if (data.containsKey('invent_standard_stack')) {
      context.handle(
        _inventStandardStackMeta,
        inventStandardStack.isAcceptableOrUnknown(
          data['invent_standard_stack']!,
          _inventStandardStackMeta,
        ),
      );
    }
    if (data.containsKey('invent_qtd_stack')) {
      context.handle(
        _inventQtdStackMeta,
        inventQtdStack.isAcceptableOrUnknown(
          data['invent_qtd_stack']!,
          _inventQtdStackMeta,
        ),
      );
    }
    if (data.containsKey('invent_qtd_individual')) {
      context.handle(
        _inventQtdIndividualMeta,
        inventQtdIndividual.isAcceptableOrUnknown(
          data['invent_qtd_individual']!,
          _inventQtdIndividualMeta,
        ),
      );
    }
    if (data.containsKey('invent_total')) {
      context.handle(
        _inventTotalMeta,
        inventTotal.isAcceptableOrUnknown(
          data['invent_total']!,
          _inventTotalMeta,
        ),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('last_sync_attempt')) {
      context.handle(
        _lastSyncAttemptMeta,
        lastSyncAttempt.isAcceptableOrUnknown(
          data['last_sync_attempt']!,
          _lastSyncAttemptMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventoryRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      inventCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invent_code'],
      )!,
      inventCreated: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}invent_created'],
      ),
      inventUser: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invent_user'],
      ),
      inventUnitizer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invent_unitizer'],
      ),
      inventLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invent_location'],
      ),
      inventProduct: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invent_product'],
      )!,
      inventBarcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invent_barcode'],
      ),
      inventStandardStack: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}invent_standard_stack'],
      ),
      inventQtdStack: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}invent_qtd_stack'],
      ),
      inventQtdIndividual: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}invent_qtd_individual'],
      ),
      inventTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}invent_total'],
      ),
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      lastSyncAttempt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_attempt'],
      ),
    );
  }

  @override
  $InventoryRecordsTable createAlias(String alias) {
    return $InventoryRecordsTable(attachedDatabase, alias);
  }
}

class InventoryRecord extends DataClass implements Insertable<InventoryRecord> {
  /// ID Autoincremento local
  final int id;

  /// FK para a tabela Inventory (inventCode)
  final String inventCode;
  final DateTime? inventCreated;
  final String? inventUser;
  final String? inventUnitizer;
  final String? inventLocation;

  /// Produto (FK ou Código)
  final String inventProduct;
  final String? inventBarcode;

  /// Quantidades
  final int? inventStandardStack;
  final int? inventQtdStack;
  final double? inventQtdIndividual;
  final double? inventTotal;

  /// 🔑 CONTROLE OFFLINE
  final bool isSynced;
  final DateTime? lastSyncAttempt;
  const InventoryRecord({
    required this.id,
    required this.inventCode,
    this.inventCreated,
    this.inventUser,
    this.inventUnitizer,
    this.inventLocation,
    required this.inventProduct,
    this.inventBarcode,
    this.inventStandardStack,
    this.inventQtdStack,
    this.inventQtdIndividual,
    this.inventTotal,
    required this.isSynced,
    this.lastSyncAttempt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['invent_code'] = Variable<String>(inventCode);
    if (!nullToAbsent || inventCreated != null) {
      map['invent_created'] = Variable<DateTime>(inventCreated);
    }
    if (!nullToAbsent || inventUser != null) {
      map['invent_user'] = Variable<String>(inventUser);
    }
    if (!nullToAbsent || inventUnitizer != null) {
      map['invent_unitizer'] = Variable<String>(inventUnitizer);
    }
    if (!nullToAbsent || inventLocation != null) {
      map['invent_location'] = Variable<String>(inventLocation);
    }
    map['invent_product'] = Variable<String>(inventProduct);
    if (!nullToAbsent || inventBarcode != null) {
      map['invent_barcode'] = Variable<String>(inventBarcode);
    }
    if (!nullToAbsent || inventStandardStack != null) {
      map['invent_standard_stack'] = Variable<int>(inventStandardStack);
    }
    if (!nullToAbsent || inventQtdStack != null) {
      map['invent_qtd_stack'] = Variable<int>(inventQtdStack);
    }
    if (!nullToAbsent || inventQtdIndividual != null) {
      map['invent_qtd_individual'] = Variable<double>(inventQtdIndividual);
    }
    if (!nullToAbsent || inventTotal != null) {
      map['invent_total'] = Variable<double>(inventTotal);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    if (!nullToAbsent || lastSyncAttempt != null) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt);
    }
    return map;
  }

  InventoryRecordsCompanion toCompanion(bool nullToAbsent) {
    return InventoryRecordsCompanion(
      id: Value(id),
      inventCode: Value(inventCode),
      inventCreated: inventCreated == null && nullToAbsent
          ? const Value.absent()
          : Value(inventCreated),
      inventUser: inventUser == null && nullToAbsent
          ? const Value.absent()
          : Value(inventUser),
      inventUnitizer: inventUnitizer == null && nullToAbsent
          ? const Value.absent()
          : Value(inventUnitizer),
      inventLocation: inventLocation == null && nullToAbsent
          ? const Value.absent()
          : Value(inventLocation),
      inventProduct: Value(inventProduct),
      inventBarcode: inventBarcode == null && nullToAbsent
          ? const Value.absent()
          : Value(inventBarcode),
      inventStandardStack: inventStandardStack == null && nullToAbsent
          ? const Value.absent()
          : Value(inventStandardStack),
      inventQtdStack: inventQtdStack == null && nullToAbsent
          ? const Value.absent()
          : Value(inventQtdStack),
      inventQtdIndividual: inventQtdIndividual == null && nullToAbsent
          ? const Value.absent()
          : Value(inventQtdIndividual),
      inventTotal: inventTotal == null && nullToAbsent
          ? const Value.absent()
          : Value(inventTotal),
      isSynced: Value(isSynced),
      lastSyncAttempt: lastSyncAttempt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAttempt),
    );
  }

  factory InventoryRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryRecord(
      id: serializer.fromJson<int>(json['id']),
      inventCode: serializer.fromJson<String>(json['inventCode']),
      inventCreated: serializer.fromJson<DateTime?>(json['inventCreated']),
      inventUser: serializer.fromJson<String?>(json['inventUser']),
      inventUnitizer: serializer.fromJson<String?>(json['inventUnitizer']),
      inventLocation: serializer.fromJson<String?>(json['inventLocation']),
      inventProduct: serializer.fromJson<String>(json['inventProduct']),
      inventBarcode: serializer.fromJson<String?>(json['inventBarcode']),
      inventStandardStack: serializer.fromJson<int?>(
        json['inventStandardStack'],
      ),
      inventQtdStack: serializer.fromJson<int?>(json['inventQtdStack']),
      inventQtdIndividual: serializer.fromJson<double?>(
        json['inventQtdIndividual'],
      ),
      inventTotal: serializer.fromJson<double?>(json['inventTotal']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      lastSyncAttempt: serializer.fromJson<DateTime?>(json['lastSyncAttempt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'inventCode': serializer.toJson<String>(inventCode),
      'inventCreated': serializer.toJson<DateTime?>(inventCreated),
      'inventUser': serializer.toJson<String?>(inventUser),
      'inventUnitizer': serializer.toJson<String?>(inventUnitizer),
      'inventLocation': serializer.toJson<String?>(inventLocation),
      'inventProduct': serializer.toJson<String>(inventProduct),
      'inventBarcode': serializer.toJson<String?>(inventBarcode),
      'inventStandardStack': serializer.toJson<int?>(inventStandardStack),
      'inventQtdStack': serializer.toJson<int?>(inventQtdStack),
      'inventQtdIndividual': serializer.toJson<double?>(inventQtdIndividual),
      'inventTotal': serializer.toJson<double?>(inventTotal),
      'isSynced': serializer.toJson<bool>(isSynced),
      'lastSyncAttempt': serializer.toJson<DateTime?>(lastSyncAttempt),
    };
  }

  InventoryRecord copyWith({
    int? id,
    String? inventCode,
    Value<DateTime?> inventCreated = const Value.absent(),
    Value<String?> inventUser = const Value.absent(),
    Value<String?> inventUnitizer = const Value.absent(),
    Value<String?> inventLocation = const Value.absent(),
    String? inventProduct,
    Value<String?> inventBarcode = const Value.absent(),
    Value<int?> inventStandardStack = const Value.absent(),
    Value<int?> inventQtdStack = const Value.absent(),
    Value<double?> inventQtdIndividual = const Value.absent(),
    Value<double?> inventTotal = const Value.absent(),
    bool? isSynced,
    Value<DateTime?> lastSyncAttempt = const Value.absent(),
  }) => InventoryRecord(
    id: id ?? this.id,
    inventCode: inventCode ?? this.inventCode,
    inventCreated: inventCreated.present
        ? inventCreated.value
        : this.inventCreated,
    inventUser: inventUser.present ? inventUser.value : this.inventUser,
    inventUnitizer: inventUnitizer.present
        ? inventUnitizer.value
        : this.inventUnitizer,
    inventLocation: inventLocation.present
        ? inventLocation.value
        : this.inventLocation,
    inventProduct: inventProduct ?? this.inventProduct,
    inventBarcode: inventBarcode.present
        ? inventBarcode.value
        : this.inventBarcode,
    inventStandardStack: inventStandardStack.present
        ? inventStandardStack.value
        : this.inventStandardStack,
    inventQtdStack: inventQtdStack.present
        ? inventQtdStack.value
        : this.inventQtdStack,
    inventQtdIndividual: inventQtdIndividual.present
        ? inventQtdIndividual.value
        : this.inventQtdIndividual,
    inventTotal: inventTotal.present ? inventTotal.value : this.inventTotal,
    isSynced: isSynced ?? this.isSynced,
    lastSyncAttempt: lastSyncAttempt.present
        ? lastSyncAttempt.value
        : this.lastSyncAttempt,
  );
  InventoryRecord copyWithCompanion(InventoryRecordsCompanion data) {
    return InventoryRecord(
      id: data.id.present ? data.id.value : this.id,
      inventCode: data.inventCode.present
          ? data.inventCode.value
          : this.inventCode,
      inventCreated: data.inventCreated.present
          ? data.inventCreated.value
          : this.inventCreated,
      inventUser: data.inventUser.present
          ? data.inventUser.value
          : this.inventUser,
      inventUnitizer: data.inventUnitizer.present
          ? data.inventUnitizer.value
          : this.inventUnitizer,
      inventLocation: data.inventLocation.present
          ? data.inventLocation.value
          : this.inventLocation,
      inventProduct: data.inventProduct.present
          ? data.inventProduct.value
          : this.inventProduct,
      inventBarcode: data.inventBarcode.present
          ? data.inventBarcode.value
          : this.inventBarcode,
      inventStandardStack: data.inventStandardStack.present
          ? data.inventStandardStack.value
          : this.inventStandardStack,
      inventQtdStack: data.inventQtdStack.present
          ? data.inventQtdStack.value
          : this.inventQtdStack,
      inventQtdIndividual: data.inventQtdIndividual.present
          ? data.inventQtdIndividual.value
          : this.inventQtdIndividual,
      inventTotal: data.inventTotal.present
          ? data.inventTotal.value
          : this.inventTotal,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      lastSyncAttempt: data.lastSyncAttempt.present
          ? data.lastSyncAttempt.value
          : this.lastSyncAttempt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryRecord(')
          ..write('id: $id, ')
          ..write('inventCode: $inventCode, ')
          ..write('inventCreated: $inventCreated, ')
          ..write('inventUser: $inventUser, ')
          ..write('inventUnitizer: $inventUnitizer, ')
          ..write('inventLocation: $inventLocation, ')
          ..write('inventProduct: $inventProduct, ')
          ..write('inventBarcode: $inventBarcode, ')
          ..write('inventStandardStack: $inventStandardStack, ')
          ..write('inventQtdStack: $inventQtdStack, ')
          ..write('inventQtdIndividual: $inventQtdIndividual, ')
          ..write('inventTotal: $inventTotal, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastSyncAttempt: $lastSyncAttempt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    inventCode,
    inventCreated,
    inventUser,
    inventUnitizer,
    inventLocation,
    inventProduct,
    inventBarcode,
    inventStandardStack,
    inventQtdStack,
    inventQtdIndividual,
    inventTotal,
    isSynced,
    lastSyncAttempt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryRecord &&
          other.id == this.id &&
          other.inventCode == this.inventCode &&
          other.inventCreated == this.inventCreated &&
          other.inventUser == this.inventUser &&
          other.inventUnitizer == this.inventUnitizer &&
          other.inventLocation == this.inventLocation &&
          other.inventProduct == this.inventProduct &&
          other.inventBarcode == this.inventBarcode &&
          other.inventStandardStack == this.inventStandardStack &&
          other.inventQtdStack == this.inventQtdStack &&
          other.inventQtdIndividual == this.inventQtdIndividual &&
          other.inventTotal == this.inventTotal &&
          other.isSynced == this.isSynced &&
          other.lastSyncAttempt == this.lastSyncAttempt);
}

class InventoryRecordsCompanion extends UpdateCompanion<InventoryRecord> {
  final Value<int> id;
  final Value<String> inventCode;
  final Value<DateTime?> inventCreated;
  final Value<String?> inventUser;
  final Value<String?> inventUnitizer;
  final Value<String?> inventLocation;
  final Value<String> inventProduct;
  final Value<String?> inventBarcode;
  final Value<int?> inventStandardStack;
  final Value<int?> inventQtdStack;
  final Value<double?> inventQtdIndividual;
  final Value<double?> inventTotal;
  final Value<bool> isSynced;
  final Value<DateTime?> lastSyncAttempt;
  const InventoryRecordsCompanion({
    this.id = const Value.absent(),
    this.inventCode = const Value.absent(),
    this.inventCreated = const Value.absent(),
    this.inventUser = const Value.absent(),
    this.inventUnitizer = const Value.absent(),
    this.inventLocation = const Value.absent(),
    this.inventProduct = const Value.absent(),
    this.inventBarcode = const Value.absent(),
    this.inventStandardStack = const Value.absent(),
    this.inventQtdStack = const Value.absent(),
    this.inventQtdIndividual = const Value.absent(),
    this.inventTotal = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
  });
  InventoryRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String inventCode,
    this.inventCreated = const Value.absent(),
    this.inventUser = const Value.absent(),
    this.inventUnitizer = const Value.absent(),
    this.inventLocation = const Value.absent(),
    required String inventProduct,
    this.inventBarcode = const Value.absent(),
    this.inventStandardStack = const Value.absent(),
    this.inventQtdStack = const Value.absent(),
    this.inventQtdIndividual = const Value.absent(),
    this.inventTotal = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
  }) : inventCode = Value(inventCode),
       inventProduct = Value(inventProduct);
  static Insertable<InventoryRecord> custom({
    Expression<int>? id,
    Expression<String>? inventCode,
    Expression<DateTime>? inventCreated,
    Expression<String>? inventUser,
    Expression<String>? inventUnitizer,
    Expression<String>? inventLocation,
    Expression<String>? inventProduct,
    Expression<String>? inventBarcode,
    Expression<int>? inventStandardStack,
    Expression<int>? inventQtdStack,
    Expression<double>? inventQtdIndividual,
    Expression<double>? inventTotal,
    Expression<bool>? isSynced,
    Expression<DateTime>? lastSyncAttempt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (inventCode != null) 'invent_code': inventCode,
      if (inventCreated != null) 'invent_created': inventCreated,
      if (inventUser != null) 'invent_user': inventUser,
      if (inventUnitizer != null) 'invent_unitizer': inventUnitizer,
      if (inventLocation != null) 'invent_location': inventLocation,
      if (inventProduct != null) 'invent_product': inventProduct,
      if (inventBarcode != null) 'invent_barcode': inventBarcode,
      if (inventStandardStack != null)
        'invent_standard_stack': inventStandardStack,
      if (inventQtdStack != null) 'invent_qtd_stack': inventQtdStack,
      if (inventQtdIndividual != null)
        'invent_qtd_individual': inventQtdIndividual,
      if (inventTotal != null) 'invent_total': inventTotal,
      if (isSynced != null) 'is_synced': isSynced,
      if (lastSyncAttempt != null) 'last_sync_attempt': lastSyncAttempt,
    });
  }

  InventoryRecordsCompanion copyWith({
    Value<int>? id,
    Value<String>? inventCode,
    Value<DateTime?>? inventCreated,
    Value<String?>? inventUser,
    Value<String?>? inventUnitizer,
    Value<String?>? inventLocation,
    Value<String>? inventProduct,
    Value<String?>? inventBarcode,
    Value<int?>? inventStandardStack,
    Value<int?>? inventQtdStack,
    Value<double?>? inventQtdIndividual,
    Value<double?>? inventTotal,
    Value<bool>? isSynced,
    Value<DateTime?>? lastSyncAttempt,
  }) {
    return InventoryRecordsCompanion(
      id: id ?? this.id,
      inventCode: inventCode ?? this.inventCode,
      inventCreated: inventCreated ?? this.inventCreated,
      inventUser: inventUser ?? this.inventUser,
      inventUnitizer: inventUnitizer ?? this.inventUnitizer,
      inventLocation: inventLocation ?? this.inventLocation,
      inventProduct: inventProduct ?? this.inventProduct,
      inventBarcode: inventBarcode ?? this.inventBarcode,
      inventStandardStack: inventStandardStack ?? this.inventStandardStack,
      inventQtdStack: inventQtdStack ?? this.inventQtdStack,
      inventQtdIndividual: inventQtdIndividual ?? this.inventQtdIndividual,
      inventTotal: inventTotal ?? this.inventTotal,
      isSynced: isSynced ?? this.isSynced,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (inventCode.present) {
      map['invent_code'] = Variable<String>(inventCode.value);
    }
    if (inventCreated.present) {
      map['invent_created'] = Variable<DateTime>(inventCreated.value);
    }
    if (inventUser.present) {
      map['invent_user'] = Variable<String>(inventUser.value);
    }
    if (inventUnitizer.present) {
      map['invent_unitizer'] = Variable<String>(inventUnitizer.value);
    }
    if (inventLocation.present) {
      map['invent_location'] = Variable<String>(inventLocation.value);
    }
    if (inventProduct.present) {
      map['invent_product'] = Variable<String>(inventProduct.value);
    }
    if (inventBarcode.present) {
      map['invent_barcode'] = Variable<String>(inventBarcode.value);
    }
    if (inventStandardStack.present) {
      map['invent_standard_stack'] = Variable<int>(inventStandardStack.value);
    }
    if (inventQtdStack.present) {
      map['invent_qtd_stack'] = Variable<int>(inventQtdStack.value);
    }
    if (inventQtdIndividual.present) {
      map['invent_qtd_individual'] = Variable<double>(
        inventQtdIndividual.value,
      );
    }
    if (inventTotal.present) {
      map['invent_total'] = Variable<double>(inventTotal.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (lastSyncAttempt.present) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryRecordsCompanion(')
          ..write('id: $id, ')
          ..write('inventCode: $inventCode, ')
          ..write('inventCreated: $inventCreated, ')
          ..write('inventUser: $inventUser, ')
          ..write('inventUnitizer: $inventUnitizer, ')
          ..write('inventLocation: $inventLocation, ')
          ..write('inventProduct: $inventProduct, ')
          ..write('inventBarcode: $inventBarcode, ')
          ..write('inventStandardStack: $inventStandardStack, ')
          ..write('inventQtdStack: $inventQtdStack, ')
          ..write('inventQtdIndividual: $inventQtdIndividual, ')
          ..write('inventTotal: $inventTotal, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastSyncAttempt: $lastSyncAttempt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $DeviceSyncTable deviceSync = $DeviceSyncTable(this);
  late final $InventoryMaskTable inventoryMask = $InventoryMaskTable(this);
  late final $InventoryTable inventory = $InventoryTable(this);
  late final $InventoryRecordsTable inventoryRecords = $InventoryRecordsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    products,
    deviceSync,
    inventoryMask,
    inventory,
    inventoryRecords,
  ];
}

typedef $$ProductsTableCreateCompanionBuilder =
    ProductsCompanion Function({
      required String productId,
      required String barcode,
      required String productName,
      Value<bool> status,
      Value<DateTime?> lastSync,
      Value<int> rowid,
    });
typedef $$ProductsTableUpdateCompanionBuilder =
    ProductsCompanion Function({
      Value<String> productId,
      Value<String> barcode,
      Value<String> productName,
      Value<bool> status,
      Value<DateTime?> lastSync,
      Value<int> rowid,
    });

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSync => $composableBuilder(
    column: $table.lastSync,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSync => $composableBuilder(
    column: $table.lastSync,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSync =>
      $composableBuilder(column: $table.lastSync, builder: (column) => column);
}

class $$ProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTable,
          Product,
          $$ProductsTableFilterComposer,
          $$ProductsTableOrderingComposer,
          $$ProductsTableAnnotationComposer,
          $$ProductsTableCreateCompanionBuilder,
          $$ProductsTableUpdateCompanionBuilder,
          (Product, BaseReferences<_$AppDatabase, $ProductsTable, Product>),
          Product,
          PrefetchHooks Function()
        > {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> productId = const Value.absent(),
                Value<String> barcode = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<bool> status = const Value.absent(),
                Value<DateTime?> lastSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion(
                productId: productId,
                barcode: barcode,
                productName: productName,
                status: status,
                lastSync: lastSync,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String productId,
                required String barcode,
                required String productName,
                Value<bool> status = const Value.absent(),
                Value<DateTime?> lastSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion.insert(
                productId: productId,
                barcode: barcode,
                productName: productName,
                status: status,
                lastSync: lastSync,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTable,
      Product,
      $$ProductsTableFilterComposer,
      $$ProductsTableOrderingComposer,
      $$ProductsTableAnnotationComposer,
      $$ProductsTableCreateCompanionBuilder,
      $$ProductsTableUpdateCompanionBuilder,
      (Product, BaseReferences<_$AppDatabase, $ProductsTable, Product>),
      Product,
      PrefetchHooks Function()
    >;
typedef $$DeviceSyncTableCreateCompanionBuilder =
    DeviceSyncCompanion Function({
      required String guid,
      required TypeWork typeWork,
      required int version,
      Value<DateTime?> lastSync,
      required String user,
      Value<int> rowid,
    });
typedef $$DeviceSyncTableUpdateCompanionBuilder =
    DeviceSyncCompanion Function({
      Value<String> guid,
      Value<TypeWork> typeWork,
      Value<int> version,
      Value<DateTime?> lastSync,
      Value<String> user,
      Value<int> rowid,
    });

class $$DeviceSyncTableFilterComposer
    extends Composer<_$AppDatabase, $DeviceSyncTable> {
  $$DeviceSyncTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get guid => $composableBuilder(
    column: $table.guid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TypeWork, TypeWork, String> get typeWork =>
      $composableBuilder(
        column: $table.typeWork,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSync => $composableBuilder(
    column: $table.lastSync,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get user => $composableBuilder(
    column: $table.user,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DeviceSyncTableOrderingComposer
    extends Composer<_$AppDatabase, $DeviceSyncTable> {
  $$DeviceSyncTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get guid => $composableBuilder(
    column: $table.guid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get typeWork => $composableBuilder(
    column: $table.typeWork,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSync => $composableBuilder(
    column: $table.lastSync,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get user => $composableBuilder(
    column: $table.user,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeviceSyncTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeviceSyncTable> {
  $$DeviceSyncTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get guid =>
      $composableBuilder(column: $table.guid, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TypeWork, String> get typeWork =>
      $composableBuilder(column: $table.typeWork, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSync =>
      $composableBuilder(column: $table.lastSync, builder: (column) => column);

  GeneratedColumn<String> get user =>
      $composableBuilder(column: $table.user, builder: (column) => column);
}

class $$DeviceSyncTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DeviceSyncTable,
          DeviceSyncData,
          $$DeviceSyncTableFilterComposer,
          $$DeviceSyncTableOrderingComposer,
          $$DeviceSyncTableAnnotationComposer,
          $$DeviceSyncTableCreateCompanionBuilder,
          $$DeviceSyncTableUpdateCompanionBuilder,
          (
            DeviceSyncData,
            BaseReferences<_$AppDatabase, $DeviceSyncTable, DeviceSyncData>,
          ),
          DeviceSyncData,
          PrefetchHooks Function()
        > {
  $$DeviceSyncTableTableManager(_$AppDatabase db, $DeviceSyncTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeviceSyncTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeviceSyncTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeviceSyncTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> guid = const Value.absent(),
                Value<TypeWork> typeWork = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime?> lastSync = const Value.absent(),
                Value<String> user = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeviceSyncCompanion(
                guid: guid,
                typeWork: typeWork,
                version: version,
                lastSync: lastSync,
                user: user,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String guid,
                required TypeWork typeWork,
                required int version,
                Value<DateTime?> lastSync = const Value.absent(),
                required String user,
                Value<int> rowid = const Value.absent(),
              }) => DeviceSyncCompanion.insert(
                guid: guid,
                typeWork: typeWork,
                version: version,
                lastSync: lastSync,
                user: user,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DeviceSyncTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DeviceSyncTable,
      DeviceSyncData,
      $$DeviceSyncTableFilterComposer,
      $$DeviceSyncTableOrderingComposer,
      $$DeviceSyncTableAnnotationComposer,
      $$DeviceSyncTableCreateCompanionBuilder,
      $$DeviceSyncTableUpdateCompanionBuilder,
      (
        DeviceSyncData,
        BaseReferences<_$AppDatabase, $DeviceSyncTable, DeviceSyncData>,
      ),
      DeviceSyncData,
      PrefetchHooks Function()
    >;
typedef $$InventoryMaskTableCreateCompanionBuilder =
    InventoryMaskCompanion Function({
      Value<int> maskId,
      required MaskFieldName fieldName,
      required String fieldMask,
    });
typedef $$InventoryMaskTableUpdateCompanionBuilder =
    InventoryMaskCompanion Function({
      Value<int> maskId,
      Value<MaskFieldName> fieldName,
      Value<String> fieldMask,
    });

class $$InventoryMaskTableFilterComposer
    extends Composer<_$AppDatabase, $InventoryMaskTable> {
  $$InventoryMaskTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get maskId => $composableBuilder(
    column: $table.maskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MaskFieldName, MaskFieldName, String>
  get fieldName => $composableBuilder(
    column: $table.fieldName,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get fieldMask => $composableBuilder(
    column: $table.fieldMask,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InventoryMaskTableOrderingComposer
    extends Composer<_$AppDatabase, $InventoryMaskTable> {
  $$InventoryMaskTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get maskId => $composableBuilder(
    column: $table.maskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldName => $composableBuilder(
    column: $table.fieldName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldMask => $composableBuilder(
    column: $table.fieldMask,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InventoryMaskTableAnnotationComposer
    extends Composer<_$AppDatabase, $InventoryMaskTable> {
  $$InventoryMaskTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get maskId =>
      $composableBuilder(column: $table.maskId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MaskFieldName, String> get fieldName =>
      $composableBuilder(column: $table.fieldName, builder: (column) => column);

  GeneratedColumn<String> get fieldMask =>
      $composableBuilder(column: $table.fieldMask, builder: (column) => column);
}

class $$InventoryMaskTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InventoryMaskTable,
          InventoryMaskData,
          $$InventoryMaskTableFilterComposer,
          $$InventoryMaskTableOrderingComposer,
          $$InventoryMaskTableAnnotationComposer,
          $$InventoryMaskTableCreateCompanionBuilder,
          $$InventoryMaskTableUpdateCompanionBuilder,
          (
            InventoryMaskData,
            BaseReferences<
              _$AppDatabase,
              $InventoryMaskTable,
              InventoryMaskData
            >,
          ),
          InventoryMaskData,
          PrefetchHooks Function()
        > {
  $$InventoryMaskTableTableManager(_$AppDatabase db, $InventoryMaskTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoryMaskTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventoryMaskTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InventoryMaskTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> maskId = const Value.absent(),
                Value<MaskFieldName> fieldName = const Value.absent(),
                Value<String> fieldMask = const Value.absent(),
              }) => InventoryMaskCompanion(
                maskId: maskId,
                fieldName: fieldName,
                fieldMask: fieldMask,
              ),
          createCompanionCallback:
              ({
                Value<int> maskId = const Value.absent(),
                required MaskFieldName fieldName,
                required String fieldMask,
              }) => InventoryMaskCompanion.insert(
                maskId: maskId,
                fieldName: fieldName,
                fieldMask: fieldMask,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InventoryMaskTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InventoryMaskTable,
      InventoryMaskData,
      $$InventoryMaskTableFilterComposer,
      $$InventoryMaskTableOrderingComposer,
      $$InventoryMaskTableAnnotationComposer,
      $$InventoryMaskTableCreateCompanionBuilder,
      $$InventoryMaskTableUpdateCompanionBuilder,
      (
        InventoryMaskData,
        BaseReferences<_$AppDatabase, $InventoryMaskTable, InventoryMaskData>,
      ),
      InventoryMaskData,
      PrefetchHooks Function()
    >;
typedef $$InventoryTableCreateCompanionBuilder =
    InventoryCompanion Function({
      required String inventCode,
      required String inventName,
      required String inventGuid,
      Value<String?> inventSector,
      Value<DateTime?> inventCreated,
      Value<String?> inventUser,
      required InventoryStatus inventStatus,
      Value<double?> inventTotal,
      Value<bool> isSynced,
      Value<DateTime?> lastSyncAttempt,
      Value<int> rowid,
    });
typedef $$InventoryTableUpdateCompanionBuilder =
    InventoryCompanion Function({
      Value<String> inventCode,
      Value<String> inventName,
      Value<String> inventGuid,
      Value<String?> inventSector,
      Value<DateTime?> inventCreated,
      Value<String?> inventUser,
      Value<InventoryStatus> inventStatus,
      Value<double?> inventTotal,
      Value<bool> isSynced,
      Value<DateTime?> lastSyncAttempt,
      Value<int> rowid,
    });

final class $$InventoryTableReferences
    extends BaseReferences<_$AppDatabase, $InventoryTable, InventoryData> {
  $$InventoryTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$InventoryRecordsTable, List<InventoryRecord>>
  _inventoryRecordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.inventoryRecords,
    aliasName: $_aliasNameGenerator(
      db.inventory.inventCode,
      db.inventoryRecords.inventCode,
    ),
  );

  $$InventoryRecordsTableProcessedTableManager get inventoryRecordsRefs {
    final manager =
        $$InventoryRecordsTableTableManager($_db, $_db.inventoryRecords).filter(
          (f) => f.inventCode.inventCode.sqlEquals(
            $_itemColumn<String>('invent_code')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _inventoryRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$InventoryTableFilterComposer
    extends Composer<_$AppDatabase, $InventoryTable> {
  $$InventoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get inventCode => $composableBuilder(
    column: $table.inventCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inventName => $composableBuilder(
    column: $table.inventName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inventGuid => $composableBuilder(
    column: $table.inventGuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inventSector => $composableBuilder(
    column: $table.inventSector,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get inventCreated => $composableBuilder(
    column: $table.inventCreated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inventUser => $composableBuilder(
    column: $table.inventUser,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<InventoryStatus, InventoryStatus, String>
  get inventStatus => $composableBuilder(
    column: $table.inventStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get inventTotal => $composableBuilder(
    column: $table.inventTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> inventoryRecordsRefs(
    Expression<bool> Function($$InventoryRecordsTableFilterComposer f) f,
  ) {
    final $$InventoryRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inventCode,
      referencedTable: $db.inventoryRecords,
      getReferencedColumn: (t) => t.inventCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoryRecordsTableFilterComposer(
            $db: $db,
            $table: $db.inventoryRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InventoryTableOrderingComposer
    extends Composer<_$AppDatabase, $InventoryTable> {
  $$InventoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get inventCode => $composableBuilder(
    column: $table.inventCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inventName => $composableBuilder(
    column: $table.inventName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inventGuid => $composableBuilder(
    column: $table.inventGuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inventSector => $composableBuilder(
    column: $table.inventSector,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get inventCreated => $composableBuilder(
    column: $table.inventCreated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inventUser => $composableBuilder(
    column: $table.inventUser,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inventStatus => $composableBuilder(
    column: $table.inventStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get inventTotal => $composableBuilder(
    column: $table.inventTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InventoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $InventoryTable> {
  $$InventoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get inventCode => $composableBuilder(
    column: $table.inventCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get inventName => $composableBuilder(
    column: $table.inventName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get inventGuid => $composableBuilder(
    column: $table.inventGuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get inventSector => $composableBuilder(
    column: $table.inventSector,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get inventCreated => $composableBuilder(
    column: $table.inventCreated,
    builder: (column) => column,
  );

  GeneratedColumn<String> get inventUser => $composableBuilder(
    column: $table.inventUser,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<InventoryStatus, String> get inventStatus =>
      $composableBuilder(
        column: $table.inventStatus,
        builder: (column) => column,
      );

  GeneratedColumn<double> get inventTotal => $composableBuilder(
    column: $table.inventTotal,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => column,
  );

  Expression<T> inventoryRecordsRefs<T extends Object>(
    Expression<T> Function($$InventoryRecordsTableAnnotationComposer a) f,
  ) {
    final $$InventoryRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inventCode,
      referencedTable: $db.inventoryRecords,
      getReferencedColumn: (t) => t.inventCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoryRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.inventoryRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InventoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InventoryTable,
          InventoryData,
          $$InventoryTableFilterComposer,
          $$InventoryTableOrderingComposer,
          $$InventoryTableAnnotationComposer,
          $$InventoryTableCreateCompanionBuilder,
          $$InventoryTableUpdateCompanionBuilder,
          (InventoryData, $$InventoryTableReferences),
          InventoryData,
          PrefetchHooks Function({bool inventoryRecordsRefs})
        > {
  $$InventoryTableTableManager(_$AppDatabase db, $InventoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InventoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> inventCode = const Value.absent(),
                Value<String> inventName = const Value.absent(),
                Value<String> inventGuid = const Value.absent(),
                Value<String?> inventSector = const Value.absent(),
                Value<DateTime?> inventCreated = const Value.absent(),
                Value<String?> inventUser = const Value.absent(),
                Value<InventoryStatus> inventStatus = const Value.absent(),
                Value<double?> inventTotal = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InventoryCompanion(
                inventCode: inventCode,
                inventName: inventName,
                inventGuid: inventGuid,
                inventSector: inventSector,
                inventCreated: inventCreated,
                inventUser: inventUser,
                inventStatus: inventStatus,
                inventTotal: inventTotal,
                isSynced: isSynced,
                lastSyncAttempt: lastSyncAttempt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String inventCode,
                required String inventName,
                required String inventGuid,
                Value<String?> inventSector = const Value.absent(),
                Value<DateTime?> inventCreated = const Value.absent(),
                Value<String?> inventUser = const Value.absent(),
                required InventoryStatus inventStatus,
                Value<double?> inventTotal = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InventoryCompanion.insert(
                inventCode: inventCode,
                inventName: inventName,
                inventGuid: inventGuid,
                inventSector: inventSector,
                inventCreated: inventCreated,
                inventUser: inventUser,
                inventStatus: inventStatus,
                inventTotal: inventTotal,
                isSynced: isSynced,
                lastSyncAttempt: lastSyncAttempt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InventoryTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({inventoryRecordsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (inventoryRecordsRefs) db.inventoryRecords,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (inventoryRecordsRefs)
                    await $_getPrefetchedData<
                      InventoryData,
                      $InventoryTable,
                      InventoryRecord
                    >(
                      currentTable: table,
                      referencedTable: $$InventoryTableReferences
                          ._inventoryRecordsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$InventoryTableReferences(
                            db,
                            table,
                            p0,
                          ).inventoryRecordsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.inventCode == item.inventCode,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$InventoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InventoryTable,
      InventoryData,
      $$InventoryTableFilterComposer,
      $$InventoryTableOrderingComposer,
      $$InventoryTableAnnotationComposer,
      $$InventoryTableCreateCompanionBuilder,
      $$InventoryTableUpdateCompanionBuilder,
      (InventoryData, $$InventoryTableReferences),
      InventoryData,
      PrefetchHooks Function({bool inventoryRecordsRefs})
    >;
typedef $$InventoryRecordsTableCreateCompanionBuilder =
    InventoryRecordsCompanion Function({
      Value<int> id,
      required String inventCode,
      Value<DateTime?> inventCreated,
      Value<String?> inventUser,
      Value<String?> inventUnitizer,
      Value<String?> inventLocation,
      required String inventProduct,
      Value<String?> inventBarcode,
      Value<int?> inventStandardStack,
      Value<int?> inventQtdStack,
      Value<double?> inventQtdIndividual,
      Value<double?> inventTotal,
      Value<bool> isSynced,
      Value<DateTime?> lastSyncAttempt,
    });
typedef $$InventoryRecordsTableUpdateCompanionBuilder =
    InventoryRecordsCompanion Function({
      Value<int> id,
      Value<String> inventCode,
      Value<DateTime?> inventCreated,
      Value<String?> inventUser,
      Value<String?> inventUnitizer,
      Value<String?> inventLocation,
      Value<String> inventProduct,
      Value<String?> inventBarcode,
      Value<int?> inventStandardStack,
      Value<int?> inventQtdStack,
      Value<double?> inventQtdIndividual,
      Value<double?> inventTotal,
      Value<bool> isSynced,
      Value<DateTime?> lastSyncAttempt,
    });

final class $$InventoryRecordsTableReferences
    extends
        BaseReferences<_$AppDatabase, $InventoryRecordsTable, InventoryRecord> {
  $$InventoryRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $InventoryTable _inventCodeTable(_$AppDatabase db) =>
      db.inventory.createAlias(
        $_aliasNameGenerator(
          db.inventoryRecords.inventCode,
          db.inventory.inventCode,
        ),
      );

  $$InventoryTableProcessedTableManager get inventCode {
    final $_column = $_itemColumn<String>('invent_code')!;

    final manager = $$InventoryTableTableManager(
      $_db,
      $_db.inventory,
    ).filter((f) => f.inventCode.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_inventCodeTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InventoryRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $InventoryRecordsTable> {
  $$InventoryRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get inventCreated => $composableBuilder(
    column: $table.inventCreated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inventUser => $composableBuilder(
    column: $table.inventUser,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inventUnitizer => $composableBuilder(
    column: $table.inventUnitizer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inventLocation => $composableBuilder(
    column: $table.inventLocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inventProduct => $composableBuilder(
    column: $table.inventProduct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inventBarcode => $composableBuilder(
    column: $table.inventBarcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get inventStandardStack => $composableBuilder(
    column: $table.inventStandardStack,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get inventQtdStack => $composableBuilder(
    column: $table.inventQtdStack,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get inventQtdIndividual => $composableBuilder(
    column: $table.inventQtdIndividual,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get inventTotal => $composableBuilder(
    column: $table.inventTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => ColumnFilters(column),
  );

  $$InventoryTableFilterComposer get inventCode {
    final $$InventoryTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inventCode,
      referencedTable: $db.inventory,
      getReferencedColumn: (t) => t.inventCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoryTableFilterComposer(
            $db: $db,
            $table: $db.inventory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InventoryRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $InventoryRecordsTable> {
  $$InventoryRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get inventCreated => $composableBuilder(
    column: $table.inventCreated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inventUser => $composableBuilder(
    column: $table.inventUser,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inventUnitizer => $composableBuilder(
    column: $table.inventUnitizer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inventLocation => $composableBuilder(
    column: $table.inventLocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inventProduct => $composableBuilder(
    column: $table.inventProduct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inventBarcode => $composableBuilder(
    column: $table.inventBarcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get inventStandardStack => $composableBuilder(
    column: $table.inventStandardStack,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get inventQtdStack => $composableBuilder(
    column: $table.inventQtdStack,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get inventQtdIndividual => $composableBuilder(
    column: $table.inventQtdIndividual,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get inventTotal => $composableBuilder(
    column: $table.inventTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => ColumnOrderings(column),
  );

  $$InventoryTableOrderingComposer get inventCode {
    final $$InventoryTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inventCode,
      referencedTable: $db.inventory,
      getReferencedColumn: (t) => t.inventCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoryTableOrderingComposer(
            $db: $db,
            $table: $db.inventory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InventoryRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InventoryRecordsTable> {
  $$InventoryRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get inventCreated => $composableBuilder(
    column: $table.inventCreated,
    builder: (column) => column,
  );

  GeneratedColumn<String> get inventUser => $composableBuilder(
    column: $table.inventUser,
    builder: (column) => column,
  );

  GeneratedColumn<String> get inventUnitizer => $composableBuilder(
    column: $table.inventUnitizer,
    builder: (column) => column,
  );

  GeneratedColumn<String> get inventLocation => $composableBuilder(
    column: $table.inventLocation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get inventProduct => $composableBuilder(
    column: $table.inventProduct,
    builder: (column) => column,
  );

  GeneratedColumn<String> get inventBarcode => $composableBuilder(
    column: $table.inventBarcode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get inventStandardStack => $composableBuilder(
    column: $table.inventStandardStack,
    builder: (column) => column,
  );

  GeneratedColumn<int> get inventQtdStack => $composableBuilder(
    column: $table.inventQtdStack,
    builder: (column) => column,
  );

  GeneratedColumn<double> get inventQtdIndividual => $composableBuilder(
    column: $table.inventQtdIndividual,
    builder: (column) => column,
  );

  GeneratedColumn<double> get inventTotal => $composableBuilder(
    column: $table.inventTotal,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => column,
  );

  $$InventoryTableAnnotationComposer get inventCode {
    final $$InventoryTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inventCode,
      referencedTable: $db.inventory,
      getReferencedColumn: (t) => t.inventCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoryTableAnnotationComposer(
            $db: $db,
            $table: $db.inventory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InventoryRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InventoryRecordsTable,
          InventoryRecord,
          $$InventoryRecordsTableFilterComposer,
          $$InventoryRecordsTableOrderingComposer,
          $$InventoryRecordsTableAnnotationComposer,
          $$InventoryRecordsTableCreateCompanionBuilder,
          $$InventoryRecordsTableUpdateCompanionBuilder,
          (InventoryRecord, $$InventoryRecordsTableReferences),
          InventoryRecord,
          PrefetchHooks Function({bool inventCode})
        > {
  $$InventoryRecordsTableTableManager(
    _$AppDatabase db,
    $InventoryRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoryRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventoryRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InventoryRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> inventCode = const Value.absent(),
                Value<DateTime?> inventCreated = const Value.absent(),
                Value<String?> inventUser = const Value.absent(),
                Value<String?> inventUnitizer = const Value.absent(),
                Value<String?> inventLocation = const Value.absent(),
                Value<String> inventProduct = const Value.absent(),
                Value<String?> inventBarcode = const Value.absent(),
                Value<int?> inventStandardStack = const Value.absent(),
                Value<int?> inventQtdStack = const Value.absent(),
                Value<double?> inventQtdIndividual = const Value.absent(),
                Value<double?> inventTotal = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
              }) => InventoryRecordsCompanion(
                id: id,
                inventCode: inventCode,
                inventCreated: inventCreated,
                inventUser: inventUser,
                inventUnitizer: inventUnitizer,
                inventLocation: inventLocation,
                inventProduct: inventProduct,
                inventBarcode: inventBarcode,
                inventStandardStack: inventStandardStack,
                inventQtdStack: inventQtdStack,
                inventQtdIndividual: inventQtdIndividual,
                inventTotal: inventTotal,
                isSynced: isSynced,
                lastSyncAttempt: lastSyncAttempt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String inventCode,
                Value<DateTime?> inventCreated = const Value.absent(),
                Value<String?> inventUser = const Value.absent(),
                Value<String?> inventUnitizer = const Value.absent(),
                Value<String?> inventLocation = const Value.absent(),
                required String inventProduct,
                Value<String?> inventBarcode = const Value.absent(),
                Value<int?> inventStandardStack = const Value.absent(),
                Value<int?> inventQtdStack = const Value.absent(),
                Value<double?> inventQtdIndividual = const Value.absent(),
                Value<double?> inventTotal = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
              }) => InventoryRecordsCompanion.insert(
                id: id,
                inventCode: inventCode,
                inventCreated: inventCreated,
                inventUser: inventUser,
                inventUnitizer: inventUnitizer,
                inventLocation: inventLocation,
                inventProduct: inventProduct,
                inventBarcode: inventBarcode,
                inventStandardStack: inventStandardStack,
                inventQtdStack: inventQtdStack,
                inventQtdIndividual: inventQtdIndividual,
                inventTotal: inventTotal,
                isSynced: isSynced,
                lastSyncAttempt: lastSyncAttempt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InventoryRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({inventCode = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (inventCode) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.inventCode,
                                referencedTable:
                                    $$InventoryRecordsTableReferences
                                        ._inventCodeTable(db),
                                referencedColumn:
                                    $$InventoryRecordsTableReferences
                                        ._inventCodeTable(db)
                                        .inventCode,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$InventoryRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InventoryRecordsTable,
      InventoryRecord,
      $$InventoryRecordsTableFilterComposer,
      $$InventoryRecordsTableOrderingComposer,
      $$InventoryRecordsTableAnnotationComposer,
      $$InventoryRecordsTableCreateCompanionBuilder,
      $$InventoryRecordsTableUpdateCompanionBuilder,
      (InventoryRecord, $$InventoryRecordsTableReferences),
      InventoryRecord,
      PrefetchHooks Function({bool inventCode})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$DeviceSyncTableTableManager get deviceSync =>
      $$DeviceSyncTableTableManager(_db, _db.deviceSync);
  $$InventoryMaskTableTableManager get inventoryMask =>
      $$InventoryMaskTableTableManager(_db, _db.inventoryMask);
  $$InventoryTableTableManager get inventory =>
      $$InventoryTableTableManager(_db, _db.inventory);
  $$InventoryRecordsTableTableManager get inventoryRecords =>
      $$InventoryRecordsTableTableManager(_db, _db.inventoryRecords);
}
