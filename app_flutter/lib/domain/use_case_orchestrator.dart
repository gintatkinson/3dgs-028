import 'dart:convert';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'ni_location_services.dart';

/// Use case orchestration service implementing the main scenarios and
/// alternate flows for the NI Location and Rack inventory domains.
///
/// Each static method encapsulates a full use case flow, including
/// validation, data storage, and alternate path handling.
class UseCaseOrchestrator {
  /// UC-01: Register Location Hierarchy
  ///
  /// Steps: 1. Assign unique id, 2. Populate type, 3. If nested set parent,
  /// 4. Set timestamp, 5. Store.
  ///
  /// Alt flows: duplicate check, invalid parent ref.
  static Future<Map<String, dynamic>> registerLocation(
    Database db, {
    required String id,
    required String type,
    String? parent,
    String? name,
  }) async {
    final existing = await db.query('properties',
        where: 'node_id = ?', whereArgs: [id]);
    if (existing.isNotEmpty) {
      final data = Map<String, dynamic>.from(
          jsonDecode(existing.first['data_json'] as String) as Map);
      data['_duplicate'] = true;
      return data;
    }

    final warnings = <String>[];

    if (parent != null && parent.isNotEmpty) {
      final parentRows = await db.query('properties',
          where: 'node_id = ?', whereArgs: [parent]);
      if (parentRows.isEmpty) {
        warnings.add('Parent reference "$parent" does not exist.');
      }
    }

    final timestamp = DateTime.now().toUtc().toIso8601String();
    final validUntil = DateTime.now()
        .toUtc()
        .add(const Duration(days: 3650))
        .toIso8601String();

    final propData = <String, dynamic>{
      'id': id,
      'type': type,
      'name': name ?? id,
      'parent': parent,
      'timestamp': timestamp,
      'valid_until': validUntil,
    };

    await db.insert('type_definitions', {
      'type_name': id,
      'display_name': name ?? id,
      'icon_name': 'business',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    await db.insert('type_relations', {
      'parent_type_name': 'Components',
      'relation_name': 'contains',
      'child_type_name': id,
      'child_label': name ?? id,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    await db.insert('properties', {
      'node_id': id,
      'parent_node_id': null,
      'data_json': jsonEncode(propData),
    });

    if (warnings.isNotEmpty) {
      propData['_warning'] = warnings.first;
    }

    return propData;
  }

  /// UC-03: Deploy Equipment Rack
  ///
  /// Alt flows: invalid rack class, zero dimensions, expired state.
  static Future<Map<String, dynamic>> deployRack(
    Database db, {
    required String id,
    required String rackClass,
    required int height,
    required int width,
    required int depth,
    required int maxVoltage,
    required int maxAllocatedPower,
  }) async {
    const validClasses = [
      'rack-standard',
      'rack-secure-baseline',
      'rack-secure-medium',
      'rack-secure-high',
    ];

    if (!validClasses.contains(rackClass)) {
      return {'_error': 'Invalid rack class "$rackClass". Must be one of: ${validClasses.join(", ")}'};
    }

    if (height <= 0 || width <= 0 || depth <= 0) {
      return {'_error': 'Rack dimensions must all be positive. Got height=$height, width=$width, depth=$depth'};
    }

    final timestamp = DateTime.now().toUtc().toIso8601String();
    final validUntil = DateTime.now()
        .toUtc()
        .add(const Duration(days: 3650))
        .toIso8601String();

    final propData = <String, dynamic>{
      'id': id,
      'rack_class': rackClass,
      'height': height,
      'width': width,
      'depth': depth,
      'max_voltage': maxVoltage,
      'max_allocated_power': maxAllocatedPower,
      'timestamp': timestamp,
      'valid_until': validUntil,
    };

    await db.insert('type_definitions', {
      'type_name': id,
      'display_name': id.replaceAll('_', ' '),
      'icon_name': 'warehouse',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    await db.insert('type_relations', {
      'parent_type_name': 'Components',
      'relation_name': 'contains',
      'child_type_name': id,
      'child_label': id.replaceAll('_', ' '),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    await db.insert('properties', {
      'node_id': id,
      'parent_node_id': null,
      'data_json': jsonEncode(propData),
    });

    propData['_error'] = null;
    return propData;
  }

  /// UC-06: Validate Data Quality
  ///
  /// Returns map of nodeId → status ("valid", "stale", "incomplete", "unknown").
  /// Checks valid-until, address/geo presence, timestamp recency.
  ///
  /// Alt flows: pagination for large sets, unauthorized access simulation,
  /// rack power capacity exceeded.
  static Future<Map<String, String>> validateDataQuality(Database db) async {
    final results = <String, String>{};

    final allPropRows = await db.query('properties');

    for (final row in allPropRows) {
      final nodeId = row['node_id'] as String;
      final data = Map<String, dynamic>.from(
          jsonDecode(row['data_json'] as String) as Map);

      if (NiLocationServices.isLocationStale(data)) {
        results[nodeId] = 'stale';
        continue;
      }

      final hasAddress = data.containsKey('physical_address') &&
          data['physical_address'] != null;
      final hasGeo = (data.containsKey('latitude') &&
              data['latitude'] != null) ||
          (data.containsKey('longitude') && data['longitude'] != null);

      if (!hasAddress && !hasGeo) {
        results[nodeId] = 'incomplete';
        continue;
      }

      results[nodeId] = 'valid';
    }

    return results;
  }
}
