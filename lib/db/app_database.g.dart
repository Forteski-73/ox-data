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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $DeviceSyncTable deviceSync = $DeviceSyncTable(this);
  late final $InventoryMaskTable inventoryMask = $InventoryMaskTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    products,
    deviceSync,
    inventoryMask,
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$DeviceSyncTableTableManager get deviceSync =>
      $$DeviceSyncTableTableManager(_db, _db.deviceSync);
  $$InventoryMaskTableTableManager get inventoryMask =>
      $$InventoryMaskTableTableManager(_db, _db.inventoryMask);
}
