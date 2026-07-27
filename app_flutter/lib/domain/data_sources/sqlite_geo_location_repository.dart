import 'dart:convert';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app_flutter/domain/geo_location.dart';
import 'package:app_flutter/domain/geo_location_repository.dart';

/// SQLite-backed implementation of [GeoLocationRepository].
///
/// Stores geo-location data in the existing `properties` table (column
/// `data_json`) using the same upsert pattern as [SqliteDataSource] to
/// maintain consistency with the broader data layer. Temporal fields
/// ([timestamp], [validUntil]) are encoded as JSON keys within the
/// `data_json` blob.
///
/// This adapter shares the same [Database] instance passed to
/// [SqliteDataSource] — no separate connection is opened. Callers are
/// responsible for lifecycle management (closing the shared database).
///
/// @realizes UML::Datastore (SQLite transport adapter)
class SqliteGeoLocationRepository implements GeoLocationRepository {
  /// Creates a new repository adapter sharing [db] with other data sources.
  ///
  /// @param db An open SQLite database connection.
  SqliteGeoLocationRepository(this._db);
  final Database _db;

  /// Persists geo-location temporal data using an INSERT-OR-REPLACE pattern.
  ///
  /// Uses `INSERT ... ON CONFLICT(node_id) DO UPDATE` to support both
  /// initial creation and subsequent updates in a single atomic operation.
  /// This matches the upsert semantics of [SqliteDataSource.saveProperties].
  ///
  /// Only non-null temporal fields are written to the JSON payload —
  /// absent fields are simply omitted rather than set to `null`.
  ///
  /// @override
  @override
  Future<bool> storeGeoLocation(
    String entityId, {
    String? timestamp,
    String? validUntil,
  }) async {
    try {
      final dataMap = <String, dynamic>{
        if (timestamp != null) 'timestamp': timestamp,
        if (validUntil != null) 'valid_until': validUntil,
      };
      final dataJson = jsonEncode(dataMap);
      // UPSERT: if a row exists at node_id, overwrite data_json;
      // otherwise create a new row. This is the same pattern used by
      // SqliteDataSource.saveProperties for consistent behavior.
      await _db.rawInsert('''
        INSERT INTO properties (node_id, data_json)
        VALUES (?, ?)
        ON CONFLICT(node_id) DO UPDATE SET
          data_json = excluded.data_json
      ''', [entityId, dataJson]);
      return true;
    } catch (_) {
      // Swallow and return false: the caller can differentiate between
      // "not found" and "operation failed" by checking the return value
      // without needing to catch exceptions at the call site.
      return false;
    }
  }

  /// Retrieves a geo-location by reading the `properties` table.
  ///
  /// Deserializes the `data_json` column and constructs a [GeoLocation]
  /// via [GeoLocation.fromMap]. Returns `null` for any of: missing row,
  /// null JSON, malformed JSON — all treated as "not found" to provide
  /// a uniform interface to callers.
  ///
  /// @override
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
      // Malformed JSON or database errors are treated uniformly as
      // "not found" since callers are expected to handle null results.
      return null;
    }
  }

  /// Marks an entity's geo-location data as expired.
  ///
  /// Reads the current `data_json`, sets `valid_until` to the Unix epoch
  /// (`1970-01-01T00:00:00Z`), and writes back. The epoch sentinel
  /// ensures any future `isExpired` check evaluates to `true` without
  /// requiring a hard delete of the record.
  ///
  /// Returns `false` when the entity has no existing row or no stored
  /// JSON — the caller can differentiate "not found" from "marked."
  ///
  /// @override
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
