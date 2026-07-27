import 'dart:convert';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app_flutter/domain/geo_location.dart';
import 'package:app_flutter/domain/geo_location_repository.dart';

class SqliteGeoLocationRepository implements GeoLocationRepository {
  SqliteGeoLocationRepository(this._db);
  final Database _db;

  @override
  Future<bool> storeGeoLocation(String entityId, {String? timestamp, String? validUntil}) async {
    try {
      final dataMap = <String, dynamic>{
        if (timestamp != null) 'timestamp': timestamp,
        if (validUntil != null) 'valid_until': validUntil,
      };
      final dataJson = jsonEncode(dataMap);
      await _db.rawInsert('''
        INSERT INTO properties (node_id, data_json)
        VALUES (?, ?)
        ON CONFLICT(node_id) DO UPDATE SET
          data_json = excluded.data_json
      ''', [entityId, dataJson]);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<GeoLocation?> queryGeoLocation(String entityId) async {
    try {
      final rows = await _db.query(
        'properties',
        columns: ['data_json'],
        where: 'node_id = ?',
        whereArgs: [entityId],
      );
      if (rows.isEmpty) return null;
      final dataJson = rows.first['data_json'] as String?;
      if (dataJson == null) return null;
      final map = Map<String, dynamic>.from(jsonDecode(dataJson) as Map);
      return GeoLocation.fromMap(entityId, map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> markAsExpired(String entityId) async {
    try {
      final rows = await _db.query(
        'properties',
        columns: ['data_json'],
        where: 'node_id = ?',
        whereArgs: [entityId],
      );
      if (rows.isEmpty) return false;
      final dataJson = rows.first['data_json'] as String?;
      if (dataJson == null) return false;
      final map = Map<String, dynamic>.from(jsonDecode(dataJson) as Map);
      map['valid_until'] = '1970-01-01T00:00:00Z';
      await _db.rawInsert('''
        INSERT INTO properties (node_id, data_json)
        VALUES (?, ?)
        ON CONFLICT(node_id) DO UPDATE SET
          data_json = excluded.data_json
      ''', [entityId, jsonEncode(map)]);
      return true;
    } catch (_) {
      return false;
    }
  }
}
