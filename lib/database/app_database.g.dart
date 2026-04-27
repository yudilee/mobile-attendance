// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $OfflinePunchesTable extends OfflinePunches
    with TableInfo<$OfflinePunchesTable, OfflinePunche> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfflinePunchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _clientPunchIdMeta =
      const VerificationMeta('clientPunchId');
  @override
  late final GeneratedColumn<String> clientPunchId = GeneratedColumn<String>(
      'client_punch_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _employeeIdMeta =
      const VerificationMeta('employeeId');
  @override
  late final GeneratedColumn<String> employeeId = GeneratedColumn<String>(
      'employee_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deviceUuidMeta =
      const VerificationMeta('deviceUuid');
  @override
  late final GeneratedColumn<String> deviceUuid = GeneratedColumn<String>(
      'device_uuid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _latitudeMeta =
      const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
      'latitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _longitudeMeta =
      const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
      'longitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _isMockLocationMeta =
      const VerificationMeta('isMockLocation');
  @override
  late final GeneratedColumn<bool> isMockLocation = GeneratedColumn<bool>(
      'is_mock_location', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_mock_location" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _biometricVerifiedMeta =
      const VerificationMeta('biometricVerified');
  @override
  late final GeneratedColumn<bool> biometricVerified = GeneratedColumn<bool>(
      'biometric_verified', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("biometric_verified" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _punchTypeMeta =
      const VerificationMeta('punchType');
  @override
  late final GeneratedColumn<String> punchType = GeneratedColumn<String>(
      'punch_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<String> timestamp = GeneratedColumn<String>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tzOffsetMinutesMeta =
      const VerificationMeta('tzOffsetMinutes');
  @override
  late final GeneratedColumn<int> tzOffsetMinutes = GeneratedColumn<int>(
      'tz_offset_minutes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(420));
  static const VerificationMeta _gpsTimeValidatedMeta =
      const VerificationMeta('gpsTimeValidated');
  @override
  late final GeneratedColumn<bool> gpsTimeValidated = GeneratedColumn<bool>(
      'gps_time_validated', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("gps_time_validated" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _errorMessageMeta =
      const VerificationMeta('errorMessage');
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
      'error_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _serverLogIdMeta =
      const VerificationMeta('serverLogId');
  @override
  late final GeneratedColumn<int> serverLogId = GeneratedColumn<int>(
      'server_log_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        clientPunchId,
        employeeId,
        deviceUuid,
        latitude,
        longitude,
        isMockLocation,
        biometricVerified,
        punchType,
        timestamp,
        tzOffsetMinutes,
        gpsTimeValidated,
        syncStatus,
        retryCount,
        errorMessage,
        serverLogId,
        createdAt,
        syncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offline_punches';
  @override
  VerificationContext validateIntegrity(Insertable<OfflinePunche> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_punch_id')) {
      context.handle(
          _clientPunchIdMeta,
          clientPunchId.isAcceptableOrUnknown(
              data['client_punch_id']!, _clientPunchIdMeta));
    } else if (isInserting) {
      context.missing(_clientPunchIdMeta);
    }
    if (data.containsKey('employee_id')) {
      context.handle(
          _employeeIdMeta,
          employeeId.isAcceptableOrUnknown(
              data['employee_id']!, _employeeIdMeta));
    } else if (isInserting) {
      context.missing(_employeeIdMeta);
    }
    if (data.containsKey('device_uuid')) {
      context.handle(
          _deviceUuidMeta,
          deviceUuid.isAcceptableOrUnknown(
              data['device_uuid']!, _deviceUuidMeta));
    } else if (isInserting) {
      context.missing(_deviceUuidMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('is_mock_location')) {
      context.handle(
          _isMockLocationMeta,
          isMockLocation.isAcceptableOrUnknown(
              data['is_mock_location']!, _isMockLocationMeta));
    }
    if (data.containsKey('biometric_verified')) {
      context.handle(
          _biometricVerifiedMeta,
          biometricVerified.isAcceptableOrUnknown(
              data['biometric_verified']!, _biometricVerifiedMeta));
    }
    if (data.containsKey('punch_type')) {
      context.handle(_punchTypeMeta,
          punchType.isAcceptableOrUnknown(data['punch_type']!, _punchTypeMeta));
    } else if (isInserting) {
      context.missing(_punchTypeMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('tz_offset_minutes')) {
      context.handle(
          _tzOffsetMinutesMeta,
          tzOffsetMinutes.isAcceptableOrUnknown(
              data['tz_offset_minutes']!, _tzOffsetMinutesMeta));
    }
    if (data.containsKey('gps_time_validated')) {
      context.handle(
          _gpsTimeValidatedMeta,
          gpsTimeValidated.isAcceptableOrUnknown(
              data['gps_time_validated']!, _gpsTimeValidatedMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    if (data.containsKey('error_message')) {
      context.handle(
          _errorMessageMeta,
          errorMessage.isAcceptableOrUnknown(
              data['error_message']!, _errorMessageMeta));
    }
    if (data.containsKey('server_log_id')) {
      context.handle(
          _serverLogIdMeta,
          serverLogId.isAcceptableOrUnknown(
              data['server_log_id']!, _serverLogIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OfflinePunche map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfflinePunche(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      clientPunchId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}client_punch_id'])!,
      employeeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}employee_id'])!,
      deviceUuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_uuid'])!,
      latitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude'])!,
      longitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude'])!,
      isMockLocation: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_mock_location'])!,
      biometricVerified: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}biometric_verified'])!,
      punchType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}punch_type'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}timestamp'])!,
      tzOffsetMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tz_offset_minutes'])!,
      gpsTimeValidated: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}gps_time_validated'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      errorMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error_message']),
      serverLogId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_log_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $OfflinePunchesTable createAlias(String alias) {
    return $OfflinePunchesTable(attachedDatabase, alias);
  }
}

class OfflinePunche extends DataClass implements Insertable<OfflinePunche> {
  final int id;
  final String clientPunchId;
  final String employeeId;
  final String deviceUuid;
  final double latitude;
  final double longitude;
  final bool isMockLocation;
  final bool biometricVerified;
  final String punchType;
  final String timestamp;
  final int tzOffsetMinutes;
  final bool gpsTimeValidated;
  final String syncStatus;
  final int retryCount;
  final String? errorMessage;
  final int? serverLogId;
  final DateTime createdAt;
  final DateTime? syncedAt;
  const OfflinePunche(
      {required this.id,
      required this.clientPunchId,
      required this.employeeId,
      required this.deviceUuid,
      required this.latitude,
      required this.longitude,
      required this.isMockLocation,
      required this.biometricVerified,
      required this.punchType,
      required this.timestamp,
      required this.tzOffsetMinutes,
      required this.gpsTimeValidated,
      required this.syncStatus,
      required this.retryCount,
      this.errorMessage,
      this.serverLogId,
      required this.createdAt,
      this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['client_punch_id'] = Variable<String>(clientPunchId);
    map['employee_id'] = Variable<String>(employeeId);
    map['device_uuid'] = Variable<String>(deviceUuid);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['is_mock_location'] = Variable<bool>(isMockLocation);
    map['biometric_verified'] = Variable<bool>(biometricVerified);
    map['punch_type'] = Variable<String>(punchType);
    map['timestamp'] = Variable<String>(timestamp);
    map['tz_offset_minutes'] = Variable<int>(tzOffsetMinutes);
    map['gps_time_validated'] = Variable<bool>(gpsTimeValidated);
    map['sync_status'] = Variable<String>(syncStatus);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    if (!nullToAbsent || serverLogId != null) {
      map['server_log_id'] = Variable<int>(serverLogId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  OfflinePunchesCompanion toCompanion(bool nullToAbsent) {
    return OfflinePunchesCompanion(
      id: Value(id),
      clientPunchId: Value(clientPunchId),
      employeeId: Value(employeeId),
      deviceUuid: Value(deviceUuid),
      latitude: Value(latitude),
      longitude: Value(longitude),
      isMockLocation: Value(isMockLocation),
      biometricVerified: Value(biometricVerified),
      punchType: Value(punchType),
      timestamp: Value(timestamp),
      tzOffsetMinutes: Value(tzOffsetMinutes),
      gpsTimeValidated: Value(gpsTimeValidated),
      syncStatus: Value(syncStatus),
      retryCount: Value(retryCount),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      serverLogId: serverLogId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverLogId),
      createdAt: Value(createdAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory OfflinePunche.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfflinePunche(
      id: serializer.fromJson<int>(json['id']),
      clientPunchId: serializer.fromJson<String>(json['clientPunchId']),
      employeeId: serializer.fromJson<String>(json['employeeId']),
      deviceUuid: serializer.fromJson<String>(json['deviceUuid']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      isMockLocation: serializer.fromJson<bool>(json['isMockLocation']),
      biometricVerified: serializer.fromJson<bool>(json['biometricVerified']),
      punchType: serializer.fromJson<String>(json['punchType']),
      timestamp: serializer.fromJson<String>(json['timestamp']),
      tzOffsetMinutes: serializer.fromJson<int>(json['tzOffsetMinutes']),
      gpsTimeValidated: serializer.fromJson<bool>(json['gpsTimeValidated']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      serverLogId: serializer.fromJson<int?>(json['serverLogId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientPunchId': serializer.toJson<String>(clientPunchId),
      'employeeId': serializer.toJson<String>(employeeId),
      'deviceUuid': serializer.toJson<String>(deviceUuid),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'isMockLocation': serializer.toJson<bool>(isMockLocation),
      'biometricVerified': serializer.toJson<bool>(biometricVerified),
      'punchType': serializer.toJson<String>(punchType),
      'timestamp': serializer.toJson<String>(timestamp),
      'tzOffsetMinutes': serializer.toJson<int>(tzOffsetMinutes),
      'gpsTimeValidated': serializer.toJson<bool>(gpsTimeValidated),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'retryCount': serializer.toJson<int>(retryCount),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'serverLogId': serializer.toJson<int?>(serverLogId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  OfflinePunche copyWith(
          {int? id,
          String? clientPunchId,
          String? employeeId,
          String? deviceUuid,
          double? latitude,
          double? longitude,
          bool? isMockLocation,
          bool? biometricVerified,
          String? punchType,
          String? timestamp,
          int? tzOffsetMinutes,
          bool? gpsTimeValidated,
          String? syncStatus,
          int? retryCount,
          Value<String?> errorMessage = const Value.absent(),
          Value<int?> serverLogId = const Value.absent(),
          DateTime? createdAt,
          Value<DateTime?> syncedAt = const Value.absent()}) =>
      OfflinePunche(
        id: id ?? this.id,
        clientPunchId: clientPunchId ?? this.clientPunchId,
        employeeId: employeeId ?? this.employeeId,
        deviceUuid: deviceUuid ?? this.deviceUuid,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        isMockLocation: isMockLocation ?? this.isMockLocation,
        biometricVerified: biometricVerified ?? this.biometricVerified,
        punchType: punchType ?? this.punchType,
        timestamp: timestamp ?? this.timestamp,
        tzOffsetMinutes: tzOffsetMinutes ?? this.tzOffsetMinutes,
        gpsTimeValidated: gpsTimeValidated ?? this.gpsTimeValidated,
        syncStatus: syncStatus ?? this.syncStatus,
        retryCount: retryCount ?? this.retryCount,
        errorMessage:
            errorMessage.present ? errorMessage.value : this.errorMessage,
        serverLogId: serverLogId.present ? serverLogId.value : this.serverLogId,
        createdAt: createdAt ?? this.createdAt,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
      );
  OfflinePunche copyWithCompanion(OfflinePunchesCompanion data) {
    return OfflinePunche(
      id: data.id.present ? data.id.value : this.id,
      clientPunchId: data.clientPunchId.present
          ? data.clientPunchId.value
          : this.clientPunchId,
      employeeId:
          data.employeeId.present ? data.employeeId.value : this.employeeId,
      deviceUuid:
          data.deviceUuid.present ? data.deviceUuid.value : this.deviceUuid,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      isMockLocation: data.isMockLocation.present
          ? data.isMockLocation.value
          : this.isMockLocation,
      biometricVerified: data.biometricVerified.present
          ? data.biometricVerified.value
          : this.biometricVerified,
      punchType: data.punchType.present ? data.punchType.value : this.punchType,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      tzOffsetMinutes: data.tzOffsetMinutes.present
          ? data.tzOffsetMinutes.value
          : this.tzOffsetMinutes,
      gpsTimeValidated: data.gpsTimeValidated.present
          ? data.gpsTimeValidated.value
          : this.gpsTimeValidated,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      serverLogId:
          data.serverLogId.present ? data.serverLogId.value : this.serverLogId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfflinePunche(')
          ..write('id: $id, ')
          ..write('clientPunchId: $clientPunchId, ')
          ..write('employeeId: $employeeId, ')
          ..write('deviceUuid: $deviceUuid, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('isMockLocation: $isMockLocation, ')
          ..write('biometricVerified: $biometricVerified, ')
          ..write('punchType: $punchType, ')
          ..write('timestamp: $timestamp, ')
          ..write('tzOffsetMinutes: $tzOffsetMinutes, ')
          ..write('gpsTimeValidated: $gpsTimeValidated, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('retryCount: $retryCount, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('serverLogId: $serverLogId, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      clientPunchId,
      employeeId,
      deviceUuid,
      latitude,
      longitude,
      isMockLocation,
      biometricVerified,
      punchType,
      timestamp,
      tzOffsetMinutes,
      gpsTimeValidated,
      syncStatus,
      retryCount,
      errorMessage,
      serverLogId,
      createdAt,
      syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfflinePunche &&
          other.id == this.id &&
          other.clientPunchId == this.clientPunchId &&
          other.employeeId == this.employeeId &&
          other.deviceUuid == this.deviceUuid &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.isMockLocation == this.isMockLocation &&
          other.biometricVerified == this.biometricVerified &&
          other.punchType == this.punchType &&
          other.timestamp == this.timestamp &&
          other.tzOffsetMinutes == this.tzOffsetMinutes &&
          other.gpsTimeValidated == this.gpsTimeValidated &&
          other.syncStatus == this.syncStatus &&
          other.retryCount == this.retryCount &&
          other.errorMessage == this.errorMessage &&
          other.serverLogId == this.serverLogId &&
          other.createdAt == this.createdAt &&
          other.syncedAt == this.syncedAt);
}

class OfflinePunchesCompanion extends UpdateCompanion<OfflinePunche> {
  final Value<int> id;
  final Value<String> clientPunchId;
  final Value<String> employeeId;
  final Value<String> deviceUuid;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<bool> isMockLocation;
  final Value<bool> biometricVerified;
  final Value<String> punchType;
  final Value<String> timestamp;
  final Value<int> tzOffsetMinutes;
  final Value<bool> gpsTimeValidated;
  final Value<String> syncStatus;
  final Value<int> retryCount;
  final Value<String?> errorMessage;
  final Value<int?> serverLogId;
  final Value<DateTime> createdAt;
  final Value<DateTime?> syncedAt;
  const OfflinePunchesCompanion({
    this.id = const Value.absent(),
    this.clientPunchId = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.deviceUuid = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.isMockLocation = const Value.absent(),
    this.biometricVerified = const Value.absent(),
    this.punchType = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.tzOffsetMinutes = const Value.absent(),
    this.gpsTimeValidated = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.serverLogId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  OfflinePunchesCompanion.insert({
    this.id = const Value.absent(),
    required String clientPunchId,
    required String employeeId,
    required String deviceUuid,
    required double latitude,
    required double longitude,
    this.isMockLocation = const Value.absent(),
    this.biometricVerified = const Value.absent(),
    required String punchType,
    required String timestamp,
    this.tzOffsetMinutes = const Value.absent(),
    this.gpsTimeValidated = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.serverLogId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
  })  : clientPunchId = Value(clientPunchId),
        employeeId = Value(employeeId),
        deviceUuid = Value(deviceUuid),
        latitude = Value(latitude),
        longitude = Value(longitude),
        punchType = Value(punchType),
        timestamp = Value(timestamp);
  static Insertable<OfflinePunche> custom({
    Expression<int>? id,
    Expression<String>? clientPunchId,
    Expression<String>? employeeId,
    Expression<String>? deviceUuid,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<bool>? isMockLocation,
    Expression<bool>? biometricVerified,
    Expression<String>? punchType,
    Expression<String>? timestamp,
    Expression<int>? tzOffsetMinutes,
    Expression<bool>? gpsTimeValidated,
    Expression<String>? syncStatus,
    Expression<int>? retryCount,
    Expression<String>? errorMessage,
    Expression<int>? serverLogId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientPunchId != null) 'client_punch_id': clientPunchId,
      if (employeeId != null) 'employee_id': employeeId,
      if (deviceUuid != null) 'device_uuid': deviceUuid,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (isMockLocation != null) 'is_mock_location': isMockLocation,
      if (biometricVerified != null) 'biometric_verified': biometricVerified,
      if (punchType != null) 'punch_type': punchType,
      if (timestamp != null) 'timestamp': timestamp,
      if (tzOffsetMinutes != null) 'tz_offset_minutes': tzOffsetMinutes,
      if (gpsTimeValidated != null) 'gps_time_validated': gpsTimeValidated,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (retryCount != null) 'retry_count': retryCount,
      if (errorMessage != null) 'error_message': errorMessage,
      if (serverLogId != null) 'server_log_id': serverLogId,
      if (createdAt != null) 'created_at': createdAt,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  OfflinePunchesCompanion copyWith(
      {Value<int>? id,
      Value<String>? clientPunchId,
      Value<String>? employeeId,
      Value<String>? deviceUuid,
      Value<double>? latitude,
      Value<double>? longitude,
      Value<bool>? isMockLocation,
      Value<bool>? biometricVerified,
      Value<String>? punchType,
      Value<String>? timestamp,
      Value<int>? tzOffsetMinutes,
      Value<bool>? gpsTimeValidated,
      Value<String>? syncStatus,
      Value<int>? retryCount,
      Value<String?>? errorMessage,
      Value<int?>? serverLogId,
      Value<DateTime>? createdAt,
      Value<DateTime?>? syncedAt}) {
    return OfflinePunchesCompanion(
      id: id ?? this.id,
      clientPunchId: clientPunchId ?? this.clientPunchId,
      employeeId: employeeId ?? this.employeeId,
      deviceUuid: deviceUuid ?? this.deviceUuid,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isMockLocation: isMockLocation ?? this.isMockLocation,
      biometricVerified: biometricVerified ?? this.biometricVerified,
      punchType: punchType ?? this.punchType,
      timestamp: timestamp ?? this.timestamp,
      tzOffsetMinutes: tzOffsetMinutes ?? this.tzOffsetMinutes,
      gpsTimeValidated: gpsTimeValidated ?? this.gpsTimeValidated,
      syncStatus: syncStatus ?? this.syncStatus,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage ?? this.errorMessage,
      serverLogId: serverLogId ?? this.serverLogId,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (clientPunchId.present) {
      map['client_punch_id'] = Variable<String>(clientPunchId.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<String>(employeeId.value);
    }
    if (deviceUuid.present) {
      map['device_uuid'] = Variable<String>(deviceUuid.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (isMockLocation.present) {
      map['is_mock_location'] = Variable<bool>(isMockLocation.value);
    }
    if (biometricVerified.present) {
      map['biometric_verified'] = Variable<bool>(biometricVerified.value);
    }
    if (punchType.present) {
      map['punch_type'] = Variable<String>(punchType.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<String>(timestamp.value);
    }
    if (tzOffsetMinutes.present) {
      map['tz_offset_minutes'] = Variable<int>(tzOffsetMinutes.value);
    }
    if (gpsTimeValidated.present) {
      map['gps_time_validated'] = Variable<bool>(gpsTimeValidated.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (serverLogId.present) {
      map['server_log_id'] = Variable<int>(serverLogId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfflinePunchesCompanion(')
          ..write('id: $id, ')
          ..write('clientPunchId: $clientPunchId, ')
          ..write('employeeId: $employeeId, ')
          ..write('deviceUuid: $deviceUuid, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('isMockLocation: $isMockLocation, ')
          ..write('biometricVerified: $biometricVerified, ')
          ..write('punchType: $punchType, ')
          ..write('timestamp: $timestamp, ')
          ..write('tzOffsetMinutes: $tzOffsetMinutes, ')
          ..write('gpsTimeValidated: $gpsTimeValidated, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('retryCount: $retryCount, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('serverLogId: $serverLogId, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }
}

class $PunchHistoryTable extends PunchHistory
    with TableInfo<$PunchHistoryTable, PunchHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PunchHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _clientPunchIdMeta =
      const VerificationMeta('clientPunchId');
  @override
  late final GeneratedColumn<String> clientPunchId = GeneratedColumn<String>(
      'client_punch_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _employeeIdMeta =
      const VerificationMeta('employeeId');
  @override
  late final GeneratedColumn<String> employeeId = GeneratedColumn<String>(
      'employee_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _punchTypeMeta =
      const VerificationMeta('punchType');
  @override
  late final GeneratedColumn<String> punchType = GeneratedColumn<String>(
      'punch_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<String> timestamp = GeneratedColumn<String>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _serverLogIdMeta =
      const VerificationMeta('serverLogId');
  @override
  late final GeneratedColumn<int> serverLogId = GeneratedColumn<int>(
      'server_log_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        clientPunchId,
        employeeId,
        punchType,
        timestamp,
        syncStatus,
        serverLogId,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'punch_history';
  @override
  VerificationContext validateIntegrity(Insertable<PunchHistoryData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_punch_id')) {
      context.handle(
          _clientPunchIdMeta,
          clientPunchId.isAcceptableOrUnknown(
              data['client_punch_id']!, _clientPunchIdMeta));
    } else if (isInserting) {
      context.missing(_clientPunchIdMeta);
    }
    if (data.containsKey('employee_id')) {
      context.handle(
          _employeeIdMeta,
          employeeId.isAcceptableOrUnknown(
              data['employee_id']!, _employeeIdMeta));
    } else if (isInserting) {
      context.missing(_employeeIdMeta);
    }
    if (data.containsKey('punch_type')) {
      context.handle(_punchTypeMeta,
          punchType.isAcceptableOrUnknown(data['punch_type']!, _punchTypeMeta));
    } else if (isInserting) {
      context.missing(_punchTypeMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    if (data.containsKey('server_log_id')) {
      context.handle(
          _serverLogIdMeta,
          serverLogId.isAcceptableOrUnknown(
              data['server_log_id']!, _serverLogIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PunchHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PunchHistoryData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      clientPunchId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}client_punch_id'])!,
      employeeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}employee_id'])!,
      punchType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}punch_type'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}timestamp'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      serverLogId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_log_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $PunchHistoryTable createAlias(String alias) {
    return $PunchHistoryTable(attachedDatabase, alias);
  }
}

class PunchHistoryData extends DataClass
    implements Insertable<PunchHistoryData> {
  final int id;
  final String clientPunchId;
  final String employeeId;
  final String punchType;
  final String timestamp;
  final String syncStatus;
  final int? serverLogId;
  final DateTime createdAt;
  const PunchHistoryData(
      {required this.id,
      required this.clientPunchId,
      required this.employeeId,
      required this.punchType,
      required this.timestamp,
      required this.syncStatus,
      this.serverLogId,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['client_punch_id'] = Variable<String>(clientPunchId);
    map['employee_id'] = Variable<String>(employeeId);
    map['punch_type'] = Variable<String>(punchType);
    map['timestamp'] = Variable<String>(timestamp);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || serverLogId != null) {
      map['server_log_id'] = Variable<int>(serverLogId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PunchHistoryCompanion toCompanion(bool nullToAbsent) {
    return PunchHistoryCompanion(
      id: Value(id),
      clientPunchId: Value(clientPunchId),
      employeeId: Value(employeeId),
      punchType: Value(punchType),
      timestamp: Value(timestamp),
      syncStatus: Value(syncStatus),
      serverLogId: serverLogId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverLogId),
      createdAt: Value(createdAt),
    );
  }

  factory PunchHistoryData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PunchHistoryData(
      id: serializer.fromJson<int>(json['id']),
      clientPunchId: serializer.fromJson<String>(json['clientPunchId']),
      employeeId: serializer.fromJson<String>(json['employeeId']),
      punchType: serializer.fromJson<String>(json['punchType']),
      timestamp: serializer.fromJson<String>(json['timestamp']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      serverLogId: serializer.fromJson<int?>(json['serverLogId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientPunchId': serializer.toJson<String>(clientPunchId),
      'employeeId': serializer.toJson<String>(employeeId),
      'punchType': serializer.toJson<String>(punchType),
      'timestamp': serializer.toJson<String>(timestamp),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'serverLogId': serializer.toJson<int?>(serverLogId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PunchHistoryData copyWith(
          {int? id,
          String? clientPunchId,
          String? employeeId,
          String? punchType,
          String? timestamp,
          String? syncStatus,
          Value<int?> serverLogId = const Value.absent(),
          DateTime? createdAt}) =>
      PunchHistoryData(
        id: id ?? this.id,
        clientPunchId: clientPunchId ?? this.clientPunchId,
        employeeId: employeeId ?? this.employeeId,
        punchType: punchType ?? this.punchType,
        timestamp: timestamp ?? this.timestamp,
        syncStatus: syncStatus ?? this.syncStatus,
        serverLogId: serverLogId.present ? serverLogId.value : this.serverLogId,
        createdAt: createdAt ?? this.createdAt,
      );
  PunchHistoryData copyWithCompanion(PunchHistoryCompanion data) {
    return PunchHistoryData(
      id: data.id.present ? data.id.value : this.id,
      clientPunchId: data.clientPunchId.present
          ? data.clientPunchId.value
          : this.clientPunchId,
      employeeId:
          data.employeeId.present ? data.employeeId.value : this.employeeId,
      punchType: data.punchType.present ? data.punchType.value : this.punchType,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      serverLogId:
          data.serverLogId.present ? data.serverLogId.value : this.serverLogId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PunchHistoryData(')
          ..write('id: $id, ')
          ..write('clientPunchId: $clientPunchId, ')
          ..write('employeeId: $employeeId, ')
          ..write('punchType: $punchType, ')
          ..write('timestamp: $timestamp, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverLogId: $serverLogId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, clientPunchId, employeeId, punchType,
      timestamp, syncStatus, serverLogId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PunchHistoryData &&
          other.id == this.id &&
          other.clientPunchId == this.clientPunchId &&
          other.employeeId == this.employeeId &&
          other.punchType == this.punchType &&
          other.timestamp == this.timestamp &&
          other.syncStatus == this.syncStatus &&
          other.serverLogId == this.serverLogId &&
          other.createdAt == this.createdAt);
}

class PunchHistoryCompanion extends UpdateCompanion<PunchHistoryData> {
  final Value<int> id;
  final Value<String> clientPunchId;
  final Value<String> employeeId;
  final Value<String> punchType;
  final Value<String> timestamp;
  final Value<String> syncStatus;
  final Value<int?> serverLogId;
  final Value<DateTime> createdAt;
  const PunchHistoryCompanion({
    this.id = const Value.absent(),
    this.clientPunchId = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.punchType = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverLogId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PunchHistoryCompanion.insert({
    this.id = const Value.absent(),
    required String clientPunchId,
    required String employeeId,
    required String punchType,
    required String timestamp,
    required String syncStatus,
    this.serverLogId = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : clientPunchId = Value(clientPunchId),
        employeeId = Value(employeeId),
        punchType = Value(punchType),
        timestamp = Value(timestamp),
        syncStatus = Value(syncStatus);
  static Insertable<PunchHistoryData> custom({
    Expression<int>? id,
    Expression<String>? clientPunchId,
    Expression<String>? employeeId,
    Expression<String>? punchType,
    Expression<String>? timestamp,
    Expression<String>? syncStatus,
    Expression<int>? serverLogId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientPunchId != null) 'client_punch_id': clientPunchId,
      if (employeeId != null) 'employee_id': employeeId,
      if (punchType != null) 'punch_type': punchType,
      if (timestamp != null) 'timestamp': timestamp,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (serverLogId != null) 'server_log_id': serverLogId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PunchHistoryCompanion copyWith(
      {Value<int>? id,
      Value<String>? clientPunchId,
      Value<String>? employeeId,
      Value<String>? punchType,
      Value<String>? timestamp,
      Value<String>? syncStatus,
      Value<int?>? serverLogId,
      Value<DateTime>? createdAt}) {
    return PunchHistoryCompanion(
      id: id ?? this.id,
      clientPunchId: clientPunchId ?? this.clientPunchId,
      employeeId: employeeId ?? this.employeeId,
      punchType: punchType ?? this.punchType,
      timestamp: timestamp ?? this.timestamp,
      syncStatus: syncStatus ?? this.syncStatus,
      serverLogId: serverLogId ?? this.serverLogId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (clientPunchId.present) {
      map['client_punch_id'] = Variable<String>(clientPunchId.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<String>(employeeId.value);
    }
    if (punchType.present) {
      map['punch_type'] = Variable<String>(punchType.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<String>(timestamp.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (serverLogId.present) {
      map['server_log_id'] = Variable<int>(serverLogId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PunchHistoryCompanion(')
          ..write('id: $id, ')
          ..write('clientPunchId: $clientPunchId, ')
          ..write('employeeId: $employeeId, ')
          ..write('punchType: $punchType, ')
          ..write('timestamp: $timestamp, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverLogId: $serverLogId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CachedConfigTable extends CachedConfig
    with TableInfo<$CachedConfigTable, CachedConfigData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedConfigTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _branchNameMeta =
      const VerificationMeta('branchName');
  @override
  late final GeneratedColumn<String> branchName = GeneratedColumn<String>(
      'branch_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _latitudeMeta =
      const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
      'latitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _longitudeMeta =
      const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
      'longitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _radiusMetersMeta =
      const VerificationMeta('radiusMeters');
  @override
  late final GeneratedColumn<double> radiusMeters = GeneratedColumn<double>(
      'radius_meters', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _registrationStatusMeta =
      const VerificationMeta('registrationStatus');
  @override
  late final GeneratedColumn<String> registrationStatus =
      GeneratedColumn<String>('registration_status', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('pending'));
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        branchName,
        latitude,
        longitude,
        radiusMeters,
        registrationStatus,
        cachedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_config';
  @override
  VerificationContext validateIntegrity(Insertable<CachedConfigData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('branch_name')) {
      context.handle(
          _branchNameMeta,
          branchName.isAcceptableOrUnknown(
              data['branch_name']!, _branchNameMeta));
    } else if (isInserting) {
      context.missing(_branchNameMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('radius_meters')) {
      context.handle(
          _radiusMetersMeta,
          radiusMeters.isAcceptableOrUnknown(
              data['radius_meters']!, _radiusMetersMeta));
    } else if (isInserting) {
      context.missing(_radiusMetersMeta);
    }
    if (data.containsKey('registration_status')) {
      context.handle(
          _registrationStatusMeta,
          registrationStatus.isAcceptableOrUnknown(
              data['registration_status']!, _registrationStatusMeta));
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedConfigData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedConfigData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      branchName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}branch_name'])!,
      latitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude'])!,
      longitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude'])!,
      radiusMeters: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}radius_meters'])!,
      registrationStatus: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}registration_status'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $CachedConfigTable createAlias(String alias) {
    return $CachedConfigTable(attachedDatabase, alias);
  }
}

class CachedConfigData extends DataClass
    implements Insertable<CachedConfigData> {
  final int id;
  final String branchName;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String registrationStatus;
  final DateTime cachedAt;
  const CachedConfigData(
      {required this.id,
      required this.branchName,
      required this.latitude,
      required this.longitude,
      required this.radiusMeters,
      required this.registrationStatus,
      required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['branch_name'] = Variable<String>(branchName);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['radius_meters'] = Variable<double>(radiusMeters);
    map['registration_status'] = Variable<String>(registrationStatus);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedConfigCompanion toCompanion(bool nullToAbsent) {
    return CachedConfigCompanion(
      id: Value(id),
      branchName: Value(branchName),
      latitude: Value(latitude),
      longitude: Value(longitude),
      radiusMeters: Value(radiusMeters),
      registrationStatus: Value(registrationStatus),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedConfigData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedConfigData(
      id: serializer.fromJson<int>(json['id']),
      branchName: serializer.fromJson<String>(json['branchName']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      radiusMeters: serializer.fromJson<double>(json['radiusMeters']),
      registrationStatus:
          serializer.fromJson<String>(json['registrationStatus']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'branchName': serializer.toJson<String>(branchName),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'radiusMeters': serializer.toJson<double>(radiusMeters),
      'registrationStatus': serializer.toJson<String>(registrationStatus),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedConfigData copyWith(
          {int? id,
          String? branchName,
          double? latitude,
          double? longitude,
          double? radiusMeters,
          String? registrationStatus,
          DateTime? cachedAt}) =>
      CachedConfigData(
        id: id ?? this.id,
        branchName: branchName ?? this.branchName,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        radiusMeters: radiusMeters ?? this.radiusMeters,
        registrationStatus: registrationStatus ?? this.registrationStatus,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  CachedConfigData copyWithCompanion(CachedConfigCompanion data) {
    return CachedConfigData(
      id: data.id.present ? data.id.value : this.id,
      branchName:
          data.branchName.present ? data.branchName.value : this.branchName,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      radiusMeters: data.radiusMeters.present
          ? data.radiusMeters.value
          : this.radiusMeters,
      registrationStatus: data.registrationStatus.present
          ? data.registrationStatus.value
          : this.registrationStatus,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedConfigData(')
          ..write('id: $id, ')
          ..write('branchName: $branchName, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('radiusMeters: $radiusMeters, ')
          ..write('registrationStatus: $registrationStatus, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, branchName, latitude, longitude,
      radiusMeters, registrationStatus, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedConfigData &&
          other.id == this.id &&
          other.branchName == this.branchName &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.radiusMeters == this.radiusMeters &&
          other.registrationStatus == this.registrationStatus &&
          other.cachedAt == this.cachedAt);
}

class CachedConfigCompanion extends UpdateCompanion<CachedConfigData> {
  final Value<int> id;
  final Value<String> branchName;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<double> radiusMeters;
  final Value<String> registrationStatus;
  final Value<DateTime> cachedAt;
  const CachedConfigCompanion({
    this.id = const Value.absent(),
    this.branchName = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.radiusMeters = const Value.absent(),
    this.registrationStatus = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  CachedConfigCompanion.insert({
    this.id = const Value.absent(),
    required String branchName,
    required double latitude,
    required double longitude,
    required double radiusMeters,
    this.registrationStatus = const Value.absent(),
    this.cachedAt = const Value.absent(),
  })  : branchName = Value(branchName),
        latitude = Value(latitude),
        longitude = Value(longitude),
        radiusMeters = Value(radiusMeters);
  static Insertable<CachedConfigData> custom({
    Expression<int>? id,
    Expression<String>? branchName,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? radiusMeters,
    Expression<String>? registrationStatus,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (branchName != null) 'branch_name': branchName,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (radiusMeters != null) 'radius_meters': radiusMeters,
      if (registrationStatus != null) 'registration_status': registrationStatus,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  CachedConfigCompanion copyWith(
      {Value<int>? id,
      Value<String>? branchName,
      Value<double>? latitude,
      Value<double>? longitude,
      Value<double>? radiusMeters,
      Value<String>? registrationStatus,
      Value<DateTime>? cachedAt}) {
    return CachedConfigCompanion(
      id: id ?? this.id,
      branchName: branchName ?? this.branchName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      registrationStatus: registrationStatus ?? this.registrationStatus,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (branchName.present) {
      map['branch_name'] = Variable<String>(branchName.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (radiusMeters.present) {
      map['radius_meters'] = Variable<double>(radiusMeters.value);
    }
    if (registrationStatus.present) {
      map['registration_status'] = Variable<String>(registrationStatus.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedConfigCompanion(')
          ..write('id: $id, ')
          ..write('branchName: $branchName, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('radiusMeters: $radiusMeters, ')
          ..write('registrationStatus: $registrationStatus, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $CachedPunchTypesTable extends CachedPunchTypes
    with TableInfo<$CachedPunchTypesTable, CachedPunchType> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedPunchTypesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorHexMeta =
      const VerificationMeta('colorHex');
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
      'color_hex', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('#009CA6'));
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('schedule'));
  static const VerificationMeta _displayOrderMeta =
      const VerificationMeta('displayOrder');
  @override
  late final GeneratedColumn<int> displayOrder = GeneratedColumn<int>(
      'display_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _requiresGeofenceMeta =
      const VerificationMeta('requiresGeofence');
  @override
  late final GeneratedColumn<bool> requiresGeofence = GeneratedColumn<bool>(
      'requires_geofence', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("requires_geofence" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns =>
      [id, code, label, colorHex, icon, displayOrder, requiresGeofence];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_punch_types';
  @override
  VerificationContext validateIntegrity(Insertable<CachedPunchType> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('color_hex')) {
      context.handle(_colorHexMeta,
          colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta));
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('display_order')) {
      context.handle(
          _displayOrderMeta,
          displayOrder.isAcceptableOrUnknown(
              data['display_order']!, _displayOrderMeta));
    }
    if (data.containsKey('requires_geofence')) {
      context.handle(
          _requiresGeofenceMeta,
          requiresGeofence.isAcceptableOrUnknown(
              data['requires_geofence']!, _requiresGeofenceMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedPunchType map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedPunchType(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code'])!,
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label'])!,
      colorHex: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color_hex'])!,
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon'])!,
      displayOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}display_order'])!,
      requiresGeofence: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}requires_geofence'])!,
    );
  }

  @override
  $CachedPunchTypesTable createAlias(String alias) {
    return $CachedPunchTypesTable(attachedDatabase, alias);
  }
}

class CachedPunchType extends DataClass implements Insertable<CachedPunchType> {
  final int id;
  final String code;
  final String label;
  final String colorHex;
  final String icon;
  final int displayOrder;
  final bool requiresGeofence;
  const CachedPunchType(
      {required this.id,
      required this.code,
      required this.label,
      required this.colorHex,
      required this.icon,
      required this.displayOrder,
      required this.requiresGeofence});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['code'] = Variable<String>(code);
    map['label'] = Variable<String>(label);
    map['color_hex'] = Variable<String>(colorHex);
    map['icon'] = Variable<String>(icon);
    map['display_order'] = Variable<int>(displayOrder);
    map['requires_geofence'] = Variable<bool>(requiresGeofence);
    return map;
  }

  CachedPunchTypesCompanion toCompanion(bool nullToAbsent) {
    return CachedPunchTypesCompanion(
      id: Value(id),
      code: Value(code),
      label: Value(label),
      colorHex: Value(colorHex),
      icon: Value(icon),
      displayOrder: Value(displayOrder),
      requiresGeofence: Value(requiresGeofence),
    );
  }

  factory CachedPunchType.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedPunchType(
      id: serializer.fromJson<int>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      label: serializer.fromJson<String>(json['label']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
      icon: serializer.fromJson<String>(json['icon']),
      displayOrder: serializer.fromJson<int>(json['displayOrder']),
      requiresGeofence: serializer.fromJson<bool>(json['requiresGeofence']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'code': serializer.toJson<String>(code),
      'label': serializer.toJson<String>(label),
      'colorHex': serializer.toJson<String>(colorHex),
      'icon': serializer.toJson<String>(icon),
      'displayOrder': serializer.toJson<int>(displayOrder),
      'requiresGeofence': serializer.toJson<bool>(requiresGeofence),
    };
  }

  CachedPunchType copyWith(
          {int? id,
          String? code,
          String? label,
          String? colorHex,
          String? icon,
          int? displayOrder,
          bool? requiresGeofence}) =>
      CachedPunchType(
        id: id ?? this.id,
        code: code ?? this.code,
        label: label ?? this.label,
        colorHex: colorHex ?? this.colorHex,
        icon: icon ?? this.icon,
        displayOrder: displayOrder ?? this.displayOrder,
        requiresGeofence: requiresGeofence ?? this.requiresGeofence,
      );
  CachedPunchType copyWithCompanion(CachedPunchTypesCompanion data) {
    return CachedPunchType(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      label: data.label.present ? data.label.value : this.label,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      icon: data.icon.present ? data.icon.value : this.icon,
      displayOrder: data.displayOrder.present
          ? data.displayOrder.value
          : this.displayOrder,
      requiresGeofence: data.requiresGeofence.present
          ? data.requiresGeofence.value
          : this.requiresGeofence,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedPunchType(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('label: $label, ')
          ..write('colorHex: $colorHex, ')
          ..write('icon: $icon, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('requiresGeofence: $requiresGeofence')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, code, label, colorHex, icon, displayOrder, requiresGeofence);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedPunchType &&
          other.id == this.id &&
          other.code == this.code &&
          other.label == this.label &&
          other.colorHex == this.colorHex &&
          other.icon == this.icon &&
          other.displayOrder == this.displayOrder &&
          other.requiresGeofence == this.requiresGeofence);
}

class CachedPunchTypesCompanion extends UpdateCompanion<CachedPunchType> {
  final Value<int> id;
  final Value<String> code;
  final Value<String> label;
  final Value<String> colorHex;
  final Value<String> icon;
  final Value<int> displayOrder;
  final Value<bool> requiresGeofence;
  const CachedPunchTypesCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.label = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.icon = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.requiresGeofence = const Value.absent(),
  });
  CachedPunchTypesCompanion.insert({
    this.id = const Value.absent(),
    required String code,
    required String label,
    this.colorHex = const Value.absent(),
    this.icon = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.requiresGeofence = const Value.absent(),
  })  : code = Value(code),
        label = Value(label);
  static Insertable<CachedPunchType> custom({
    Expression<int>? id,
    Expression<String>? code,
    Expression<String>? label,
    Expression<String>? colorHex,
    Expression<String>? icon,
    Expression<int>? displayOrder,
    Expression<bool>? requiresGeofence,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (label != null) 'label': label,
      if (colorHex != null) 'color_hex': colorHex,
      if (icon != null) 'icon': icon,
      if (displayOrder != null) 'display_order': displayOrder,
      if (requiresGeofence != null) 'requires_geofence': requiresGeofence,
    });
  }

  CachedPunchTypesCompanion copyWith(
      {Value<int>? id,
      Value<String>? code,
      Value<String>? label,
      Value<String>? colorHex,
      Value<String>? icon,
      Value<int>? displayOrder,
      Value<bool>? requiresGeofence}) {
    return CachedPunchTypesCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      label: label ?? this.label,
      colorHex: colorHex ?? this.colorHex,
      icon: icon ?? this.icon,
      displayOrder: displayOrder ?? this.displayOrder,
      requiresGeofence: requiresGeofence ?? this.requiresGeofence,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (displayOrder.present) {
      map['display_order'] = Variable<int>(displayOrder.value);
    }
    if (requiresGeofence.present) {
      map['requires_geofence'] = Variable<bool>(requiresGeofence.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedPunchTypesCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('label: $label, ')
          ..write('colorHex: $colorHex, ')
          ..write('icon: $icon, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('requiresGeofence: $requiresGeofence')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $OfflinePunchesTable offlinePunches = $OfflinePunchesTable(this);
  late final $PunchHistoryTable punchHistory = $PunchHistoryTable(this);
  late final $CachedConfigTable cachedConfig = $CachedConfigTable(this);
  late final $CachedPunchTypesTable cachedPunchTypes =
      $CachedPunchTypesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [offlinePunches, punchHistory, cachedConfig, cachedPunchTypes];
}

typedef $$OfflinePunchesTableCreateCompanionBuilder = OfflinePunchesCompanion
    Function({
  Value<int> id,
  required String clientPunchId,
  required String employeeId,
  required String deviceUuid,
  required double latitude,
  required double longitude,
  Value<bool> isMockLocation,
  Value<bool> biometricVerified,
  required String punchType,
  required String timestamp,
  Value<int> tzOffsetMinutes,
  Value<bool> gpsTimeValidated,
  Value<String> syncStatus,
  Value<int> retryCount,
  Value<String?> errorMessage,
  Value<int?> serverLogId,
  Value<DateTime> createdAt,
  Value<DateTime?> syncedAt,
});
typedef $$OfflinePunchesTableUpdateCompanionBuilder = OfflinePunchesCompanion
    Function({
  Value<int> id,
  Value<String> clientPunchId,
  Value<String> employeeId,
  Value<String> deviceUuid,
  Value<double> latitude,
  Value<double> longitude,
  Value<bool> isMockLocation,
  Value<bool> biometricVerified,
  Value<String> punchType,
  Value<String> timestamp,
  Value<int> tzOffsetMinutes,
  Value<bool> gpsTimeValidated,
  Value<String> syncStatus,
  Value<int> retryCount,
  Value<String?> errorMessage,
  Value<int?> serverLogId,
  Value<DateTime> createdAt,
  Value<DateTime?> syncedAt,
});

class $$OfflinePunchesTableFilterComposer
    extends Composer<_$AppDatabase, $OfflinePunchesTable> {
  $$OfflinePunchesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientPunchId => $composableBuilder(
      column: $table.clientPunchId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get employeeId => $composableBuilder(
      column: $table.employeeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceUuid => $composableBuilder(
      column: $table.deviceUuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isMockLocation => $composableBuilder(
      column: $table.isMockLocation,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get biometricVerified => $composableBuilder(
      column: $table.biometricVerified,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get punchType => $composableBuilder(
      column: $table.punchType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tzOffsetMinutes => $composableBuilder(
      column: $table.tzOffsetMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get gpsTimeValidated => $composableBuilder(
      column: $table.gpsTimeValidated,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverLogId => $composableBuilder(
      column: $table.serverLogId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$OfflinePunchesTableOrderingComposer
    extends Composer<_$AppDatabase, $OfflinePunchesTable> {
  $$OfflinePunchesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientPunchId => $composableBuilder(
      column: $table.clientPunchId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get employeeId => $composableBuilder(
      column: $table.employeeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceUuid => $composableBuilder(
      column: $table.deviceUuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isMockLocation => $composableBuilder(
      column: $table.isMockLocation,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get biometricVerified => $composableBuilder(
      column: $table.biometricVerified,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get punchType => $composableBuilder(
      column: $table.punchType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tzOffsetMinutes => $composableBuilder(
      column: $table.tzOffsetMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get gpsTimeValidated => $composableBuilder(
      column: $table.gpsTimeValidated,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverLogId => $composableBuilder(
      column: $table.serverLogId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$OfflinePunchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OfflinePunchesTable> {
  $$OfflinePunchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientPunchId => $composableBuilder(
      column: $table.clientPunchId, builder: (column) => column);

  GeneratedColumn<String> get employeeId => $composableBuilder(
      column: $table.employeeId, builder: (column) => column);

  GeneratedColumn<String> get deviceUuid => $composableBuilder(
      column: $table.deviceUuid, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<bool> get isMockLocation => $composableBuilder(
      column: $table.isMockLocation, builder: (column) => column);

  GeneratedColumn<bool> get biometricVerified => $composableBuilder(
      column: $table.biometricVerified, builder: (column) => column);

  GeneratedColumn<String> get punchType =>
      $composableBuilder(column: $table.punchType, builder: (column) => column);

  GeneratedColumn<String> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get tzOffsetMinutes => $composableBuilder(
      column: $table.tzOffsetMinutes, builder: (column) => column);

  GeneratedColumn<bool> get gpsTimeValidated => $composableBuilder(
      column: $table.gpsTimeValidated, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => column);

  GeneratedColumn<int> get serverLogId => $composableBuilder(
      column: $table.serverLogId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$OfflinePunchesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OfflinePunchesTable,
    OfflinePunche,
    $$OfflinePunchesTableFilterComposer,
    $$OfflinePunchesTableOrderingComposer,
    $$OfflinePunchesTableAnnotationComposer,
    $$OfflinePunchesTableCreateCompanionBuilder,
    $$OfflinePunchesTableUpdateCompanionBuilder,
    (
      OfflinePunche,
      BaseReferences<_$AppDatabase, $OfflinePunchesTable, OfflinePunche>
    ),
    OfflinePunche,
    PrefetchHooks Function()> {
  $$OfflinePunchesTableTableManager(
      _$AppDatabase db, $OfflinePunchesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OfflinePunchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OfflinePunchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OfflinePunchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> clientPunchId = const Value.absent(),
            Value<String> employeeId = const Value.absent(),
            Value<String> deviceUuid = const Value.absent(),
            Value<double> latitude = const Value.absent(),
            Value<double> longitude = const Value.absent(),
            Value<bool> isMockLocation = const Value.absent(),
            Value<bool> biometricVerified = const Value.absent(),
            Value<String> punchType = const Value.absent(),
            Value<String> timestamp = const Value.absent(),
            Value<int> tzOffsetMinutes = const Value.absent(),
            Value<bool> gpsTimeValidated = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<int?> serverLogId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
          }) =>
              OfflinePunchesCompanion(
            id: id,
            clientPunchId: clientPunchId,
            employeeId: employeeId,
            deviceUuid: deviceUuid,
            latitude: latitude,
            longitude: longitude,
            isMockLocation: isMockLocation,
            biometricVerified: biometricVerified,
            punchType: punchType,
            timestamp: timestamp,
            tzOffsetMinutes: tzOffsetMinutes,
            gpsTimeValidated: gpsTimeValidated,
            syncStatus: syncStatus,
            retryCount: retryCount,
            errorMessage: errorMessage,
            serverLogId: serverLogId,
            createdAt: createdAt,
            syncedAt: syncedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String clientPunchId,
            required String employeeId,
            required String deviceUuid,
            required double latitude,
            required double longitude,
            Value<bool> isMockLocation = const Value.absent(),
            Value<bool> biometricVerified = const Value.absent(),
            required String punchType,
            required String timestamp,
            Value<int> tzOffsetMinutes = const Value.absent(),
            Value<bool> gpsTimeValidated = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<int?> serverLogId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
          }) =>
              OfflinePunchesCompanion.insert(
            id: id,
            clientPunchId: clientPunchId,
            employeeId: employeeId,
            deviceUuid: deviceUuid,
            latitude: latitude,
            longitude: longitude,
            isMockLocation: isMockLocation,
            biometricVerified: biometricVerified,
            punchType: punchType,
            timestamp: timestamp,
            tzOffsetMinutes: tzOffsetMinutes,
            gpsTimeValidated: gpsTimeValidated,
            syncStatus: syncStatus,
            retryCount: retryCount,
            errorMessage: errorMessage,
            serverLogId: serverLogId,
            createdAt: createdAt,
            syncedAt: syncedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OfflinePunchesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OfflinePunchesTable,
    OfflinePunche,
    $$OfflinePunchesTableFilterComposer,
    $$OfflinePunchesTableOrderingComposer,
    $$OfflinePunchesTableAnnotationComposer,
    $$OfflinePunchesTableCreateCompanionBuilder,
    $$OfflinePunchesTableUpdateCompanionBuilder,
    (
      OfflinePunche,
      BaseReferences<_$AppDatabase, $OfflinePunchesTable, OfflinePunche>
    ),
    OfflinePunche,
    PrefetchHooks Function()>;
typedef $$PunchHistoryTableCreateCompanionBuilder = PunchHistoryCompanion
    Function({
  Value<int> id,
  required String clientPunchId,
  required String employeeId,
  required String punchType,
  required String timestamp,
  required String syncStatus,
  Value<int?> serverLogId,
  Value<DateTime> createdAt,
});
typedef $$PunchHistoryTableUpdateCompanionBuilder = PunchHistoryCompanion
    Function({
  Value<int> id,
  Value<String> clientPunchId,
  Value<String> employeeId,
  Value<String> punchType,
  Value<String> timestamp,
  Value<String> syncStatus,
  Value<int?> serverLogId,
  Value<DateTime> createdAt,
});

class $$PunchHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $PunchHistoryTable> {
  $$PunchHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientPunchId => $composableBuilder(
      column: $table.clientPunchId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get employeeId => $composableBuilder(
      column: $table.employeeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get punchType => $composableBuilder(
      column: $table.punchType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverLogId => $composableBuilder(
      column: $table.serverLogId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$PunchHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $PunchHistoryTable> {
  $$PunchHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientPunchId => $composableBuilder(
      column: $table.clientPunchId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get employeeId => $composableBuilder(
      column: $table.employeeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get punchType => $composableBuilder(
      column: $table.punchType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverLogId => $composableBuilder(
      column: $table.serverLogId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$PunchHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $PunchHistoryTable> {
  $$PunchHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientPunchId => $composableBuilder(
      column: $table.clientPunchId, builder: (column) => column);

  GeneratedColumn<String> get employeeId => $composableBuilder(
      column: $table.employeeId, builder: (column) => column);

  GeneratedColumn<String> get punchType =>
      $composableBuilder(column: $table.punchType, builder: (column) => column);

  GeneratedColumn<String> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<int> get serverLogId => $composableBuilder(
      column: $table.serverLogId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PunchHistoryTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PunchHistoryTable,
    PunchHistoryData,
    $$PunchHistoryTableFilterComposer,
    $$PunchHistoryTableOrderingComposer,
    $$PunchHistoryTableAnnotationComposer,
    $$PunchHistoryTableCreateCompanionBuilder,
    $$PunchHistoryTableUpdateCompanionBuilder,
    (
      PunchHistoryData,
      BaseReferences<_$AppDatabase, $PunchHistoryTable, PunchHistoryData>
    ),
    PunchHistoryData,
    PrefetchHooks Function()> {
  $$PunchHistoryTableTableManager(_$AppDatabase db, $PunchHistoryTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PunchHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PunchHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PunchHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> clientPunchId = const Value.absent(),
            Value<String> employeeId = const Value.absent(),
            Value<String> punchType = const Value.absent(),
            Value<String> timestamp = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<int?> serverLogId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              PunchHistoryCompanion(
            id: id,
            clientPunchId: clientPunchId,
            employeeId: employeeId,
            punchType: punchType,
            timestamp: timestamp,
            syncStatus: syncStatus,
            serverLogId: serverLogId,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String clientPunchId,
            required String employeeId,
            required String punchType,
            required String timestamp,
            required String syncStatus,
            Value<int?> serverLogId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              PunchHistoryCompanion.insert(
            id: id,
            clientPunchId: clientPunchId,
            employeeId: employeeId,
            punchType: punchType,
            timestamp: timestamp,
            syncStatus: syncStatus,
            serverLogId: serverLogId,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PunchHistoryTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PunchHistoryTable,
    PunchHistoryData,
    $$PunchHistoryTableFilterComposer,
    $$PunchHistoryTableOrderingComposer,
    $$PunchHistoryTableAnnotationComposer,
    $$PunchHistoryTableCreateCompanionBuilder,
    $$PunchHistoryTableUpdateCompanionBuilder,
    (
      PunchHistoryData,
      BaseReferences<_$AppDatabase, $PunchHistoryTable, PunchHistoryData>
    ),
    PunchHistoryData,
    PrefetchHooks Function()>;
typedef $$CachedConfigTableCreateCompanionBuilder = CachedConfigCompanion
    Function({
  Value<int> id,
  required String branchName,
  required double latitude,
  required double longitude,
  required double radiusMeters,
  Value<String> registrationStatus,
  Value<DateTime> cachedAt,
});
typedef $$CachedConfigTableUpdateCompanionBuilder = CachedConfigCompanion
    Function({
  Value<int> id,
  Value<String> branchName,
  Value<double> latitude,
  Value<double> longitude,
  Value<double> radiusMeters,
  Value<String> registrationStatus,
  Value<DateTime> cachedAt,
});

class $$CachedConfigTableFilterComposer
    extends Composer<_$AppDatabase, $CachedConfigTable> {
  $$CachedConfigTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get branchName => $composableBuilder(
      column: $table.branchName, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get radiusMeters => $composableBuilder(
      column: $table.radiusMeters, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get registrationStatus => $composableBuilder(
      column: $table.registrationStatus,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$CachedConfigTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedConfigTable> {
  $$CachedConfigTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get branchName => $composableBuilder(
      column: $table.branchName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get radiusMeters => $composableBuilder(
      column: $table.radiusMeters,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get registrationStatus => $composableBuilder(
      column: $table.registrationStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$CachedConfigTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedConfigTable> {
  $$CachedConfigTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get branchName => $composableBuilder(
      column: $table.branchName, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get radiusMeters => $composableBuilder(
      column: $table.radiusMeters, builder: (column) => column);

  GeneratedColumn<String> get registrationStatus => $composableBuilder(
      column: $table.registrationStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedConfigTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedConfigTable,
    CachedConfigData,
    $$CachedConfigTableFilterComposer,
    $$CachedConfigTableOrderingComposer,
    $$CachedConfigTableAnnotationComposer,
    $$CachedConfigTableCreateCompanionBuilder,
    $$CachedConfigTableUpdateCompanionBuilder,
    (
      CachedConfigData,
      BaseReferences<_$AppDatabase, $CachedConfigTable, CachedConfigData>
    ),
    CachedConfigData,
    PrefetchHooks Function()> {
  $$CachedConfigTableTableManager(_$AppDatabase db, $CachedConfigTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedConfigTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedConfigTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedConfigTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> branchName = const Value.absent(),
            Value<double> latitude = const Value.absent(),
            Value<double> longitude = const Value.absent(),
            Value<double> radiusMeters = const Value.absent(),
            Value<String> registrationStatus = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
          }) =>
              CachedConfigCompanion(
            id: id,
            branchName: branchName,
            latitude: latitude,
            longitude: longitude,
            radiusMeters: radiusMeters,
            registrationStatus: registrationStatus,
            cachedAt: cachedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String branchName,
            required double latitude,
            required double longitude,
            required double radiusMeters,
            Value<String> registrationStatus = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
          }) =>
              CachedConfigCompanion.insert(
            id: id,
            branchName: branchName,
            latitude: latitude,
            longitude: longitude,
            radiusMeters: radiusMeters,
            registrationStatus: registrationStatus,
            cachedAt: cachedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedConfigTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedConfigTable,
    CachedConfigData,
    $$CachedConfigTableFilterComposer,
    $$CachedConfigTableOrderingComposer,
    $$CachedConfigTableAnnotationComposer,
    $$CachedConfigTableCreateCompanionBuilder,
    $$CachedConfigTableUpdateCompanionBuilder,
    (
      CachedConfigData,
      BaseReferences<_$AppDatabase, $CachedConfigTable, CachedConfigData>
    ),
    CachedConfigData,
    PrefetchHooks Function()>;
typedef $$CachedPunchTypesTableCreateCompanionBuilder
    = CachedPunchTypesCompanion Function({
  Value<int> id,
  required String code,
  required String label,
  Value<String> colorHex,
  Value<String> icon,
  Value<int> displayOrder,
  Value<bool> requiresGeofence,
});
typedef $$CachedPunchTypesTableUpdateCompanionBuilder
    = CachedPunchTypesCompanion Function({
  Value<int> id,
  Value<String> code,
  Value<String> label,
  Value<String> colorHex,
  Value<String> icon,
  Value<int> displayOrder,
  Value<bool> requiresGeofence,
});

class $$CachedPunchTypesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedPunchTypesTable> {
  $$CachedPunchTypesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get displayOrder => $composableBuilder(
      column: $table.displayOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get requiresGeofence => $composableBuilder(
      column: $table.requiresGeofence,
      builder: (column) => ColumnFilters(column));
}

class $$CachedPunchTypesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedPunchTypesTable> {
  $$CachedPunchTypesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get displayOrder => $composableBuilder(
      column: $table.displayOrder,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get requiresGeofence => $composableBuilder(
      column: $table.requiresGeofence,
      builder: (column) => ColumnOrderings(column));
}

class $$CachedPunchTypesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedPunchTypesTable> {
  $$CachedPunchTypesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get displayOrder => $composableBuilder(
      column: $table.displayOrder, builder: (column) => column);

  GeneratedColumn<bool> get requiresGeofence => $composableBuilder(
      column: $table.requiresGeofence, builder: (column) => column);
}

class $$CachedPunchTypesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedPunchTypesTable,
    CachedPunchType,
    $$CachedPunchTypesTableFilterComposer,
    $$CachedPunchTypesTableOrderingComposer,
    $$CachedPunchTypesTableAnnotationComposer,
    $$CachedPunchTypesTableCreateCompanionBuilder,
    $$CachedPunchTypesTableUpdateCompanionBuilder,
    (
      CachedPunchType,
      BaseReferences<_$AppDatabase, $CachedPunchTypesTable, CachedPunchType>
    ),
    CachedPunchType,
    PrefetchHooks Function()> {
  $$CachedPunchTypesTableTableManager(
      _$AppDatabase db, $CachedPunchTypesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedPunchTypesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedPunchTypesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedPunchTypesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> code = const Value.absent(),
            Value<String> label = const Value.absent(),
            Value<String> colorHex = const Value.absent(),
            Value<String> icon = const Value.absent(),
            Value<int> displayOrder = const Value.absent(),
            Value<bool> requiresGeofence = const Value.absent(),
          }) =>
              CachedPunchTypesCompanion(
            id: id,
            code: code,
            label: label,
            colorHex: colorHex,
            icon: icon,
            displayOrder: displayOrder,
            requiresGeofence: requiresGeofence,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String code,
            required String label,
            Value<String> colorHex = const Value.absent(),
            Value<String> icon = const Value.absent(),
            Value<int> displayOrder = const Value.absent(),
            Value<bool> requiresGeofence = const Value.absent(),
          }) =>
              CachedPunchTypesCompanion.insert(
            id: id,
            code: code,
            label: label,
            colorHex: colorHex,
            icon: icon,
            displayOrder: displayOrder,
            requiresGeofence: requiresGeofence,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedPunchTypesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedPunchTypesTable,
    CachedPunchType,
    $$CachedPunchTypesTableFilterComposer,
    $$CachedPunchTypesTableOrderingComposer,
    $$CachedPunchTypesTableAnnotationComposer,
    $$CachedPunchTypesTableCreateCompanionBuilder,
    $$CachedPunchTypesTableUpdateCompanionBuilder,
    (
      CachedPunchType,
      BaseReferences<_$AppDatabase, $CachedPunchTypesTable, CachedPunchType>
    ),
    CachedPunchType,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$OfflinePunchesTableTableManager get offlinePunches =>
      $$OfflinePunchesTableTableManager(_db, _db.offlinePunches);
  $$PunchHistoryTableTableManager get punchHistory =>
      $$PunchHistoryTableTableManager(_db, _db.punchHistory);
  $$CachedConfigTableTableManager get cachedConfig =>
      $$CachedConfigTableTableManager(_db, _db.cachedConfig);
  $$CachedPunchTypesTableTableManager get cachedPunchTypes =>
      $$CachedPunchTypesTableTableManager(_db, _db.cachedPunchTypes);
}
