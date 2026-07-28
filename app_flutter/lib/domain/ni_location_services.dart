import 'dart:convert';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Static service methods implementing user story BDD scenarios for the
/// NI Location and Rack inventory domains.
///
/// All methods operate against a [Database] abstraction so they are
/// backend-agnostic. No mutable state or side effects beyond data access.
class NiLocationServices {
  /// US-01: Query Location Hierarchy
  ///
  /// Queries all NI Location properties rows and returns them with
  /// id/type/parent fields for hierarchy reconstruction.
  static Future<List<Map<String, dynamic>>> queryLocationHierarchy(
      Database db) async {
    final rows = await db.query('properties',
        where: 'node_id LIKE ?', whereArgs: ['nil_location_%']);
    return rows.map((r) {
      final data = Map<String, dynamic>.from(
          jsonDecode(r['data_json'] as String) as Map);
      data['_node_id'] = r['node_id'] as String;
      return data;
    }).toList();
  }

  /// US-02: Validate Location for Dispatch Readiness
  ///
  /// Returns null if ready, or error message. Checks: (a) physical-address
  /// OR geo-location present, (b) valid-until absent or future.
  /// Returns "stale", "incomplete", or null.
  static String? validateDispatchReadiness(Map<String, dynamic> locationData) {
    if (isLocationStale(locationData)) {
      return 'stale';
    }

    final hasAddress = (locationData.containsKey('postal_code') &&
            locationData['postal_code'] != null) ||
        (locationData.containsKey('city') &&
            locationData['city'] != null) ||
        (locationData.containsKey('country_code') &&
            locationData['country_code'] != null);
    final hasGeo = (locationData.containsKey('latitude') &&
            locationData['latitude'] != null) ||
        (locationData.containsKey('longitude') &&
            locationData['longitude'] != null);

    if (!hasAddress && !hasGeo) {
      return 'incomplete';
    }

    return null;
  }

  /// US-03a: Check if location data is expired.
  ///
  /// Returns true when validUntil is present, parseable, and strictly
  /// before the current UTC time.
  static bool isLocationStale(Map<String, dynamic> data) {
    final validUntil = data['valid_until'];
    if (validUntil == null) return false;
    final parsed = DateTime.tryParse(validUntil.toString());
    if (parsed == null) return false;
    return parsed.toUtc().isBefore(DateTime.now().toUtc());
  }

  /// US-03b: Filter locations that are stale (expired).
  static List<Map<String, dynamic>> filterStaleLocations(
      List<Map<String, dynamic>> locations) {
    return locations.where((l) => isLocationStale(l)).toList();
  }

  /// US-04: Query Rack Inventory
  ///
  /// Returns all RackEntity rows with identifiers, dimensions,
  /// electrical specs, and rack-class.
  static Future<List<Map<String, dynamic>>> queryRackInventory(
      Database db) async {
    final rows = await db.query('properties',
        where: 'node_id LIKE ?', whereArgs: ['rack_%']);
    return rows.map((r) {
      final data = Map<String, dynamic>.from(
          jsonDecode(r['data_json'] as String) as Map);
      data['_node_id'] = r['node_id'] as String;
      return data;
    }).toList();
  }

  /// US-06a: Calculate rack power capacity.
  ///
  /// Returns map with totalDraw, remainingCapacity, and utilizationPercent.
  static Map<String, double> calculateRackCapacity({
    required double maxAllocatedPower,
    required List<double> chassisPowerDraws,
  }) {
    final totalDraw = chassisPowerDraws.fold<double>(0, (a, b) => a + b);
    final remainingCapacity = maxAllocatedPower - totalDraw;
    final utilizationPercent =
        maxAllocatedPower > 0 ? (totalDraw / maxAllocatedPower) * 100 : 0;
    return {
      'totalDraw': totalDraw,
      'remainingCapacity': remainingCapacity,
      'utilizationPercent': double.parse(utilizationPercent.toStringAsFixed(2)),
    };
  }

  /// US-06b: Check if a chassis can fit in a rack.
  ///
  /// Returns true when the chassis (at its relativePosition, with its
  /// chassisHeight) fits within the rack's total height.
  static bool canFitChassis({
    required double rackHeight,
    required int relativePosition,
    required double chassisHeight,
  }) {
    return (relativePosition + chassisHeight) <= rackHeight;
  }

  /// US-07: Navigate Full Facility Topology
  ///
  /// Traces Site → Building → Room → Rack → Chassis chain for a
  /// given chassis instance ID.
  static Future<List<String>> traceTopology(
      Database db, String chassisInstanceId) async {
    final chain = <String>[];

    final instRows = await db.query('instances',
        where: 'id = ?', whereArgs: [chassisInstanceId]);
    if (instRows.isEmpty) return chain;

    final parentNodeId = instRows.first['parent_node_id'] as String;
    chain.add(parentNodeId);

    if (parentNodeId.startsWith('rack_')) {
      final rackRows = await db.query('properties',
          where: 'node_id = ?', whereArgs: [parentNodeId]);
      if (rackRows.isNotEmpty) {
        final rackData = Map<String, dynamic>.from(
            jsonDecode(rackRows.first['data_json'] as String) as Map);

        final rackPlacementRows = await db.query('instances',
            where: 'parent_node_id = ? AND type_name = ?',
            whereArgs: [parentNodeId, 'RackPlacement']);
        if (rackPlacementRows.isNotEmpty) {
          final placementData = Map<String, dynamic>.from(jsonDecode(
              rackPlacementRows.first['data_json'] as String) as Map);
          final locationRef = placementData['location_ref'] as String?;
          if (locationRef != null) {
            chain.add(locationRef);

            final locRows = await db.query('properties',
                where: 'node_id = ?', whereArgs: [locationRef]);
            if (locRows.isNotEmpty) {
              final locData = Map<String, dynamic>.from(
                  jsonDecode(locRows.first['data_json'] as String) as Map);
              final parent = locData['parent'] as String?;
              if (parent != null) {
                chain.add(parent);

                final parentRows = await db.query('properties',
                    where: 'node_id = ?', whereArgs: [parent]);
                if (parentRows.isNotEmpty) {
                  final parentData = Map<String, dynamic>.from(jsonDecode(
                      parentRows.first['data_json'] as String) as Map);
                  final grandparent = parentData['parent'] as String?;
                  if (grandparent != null) {
                    chain.add(grandparent);
                  }
                }
              }
            }
          }
        }
      }
    }

    return chain.reversed.toList();
  }

  /// US-09: Map Distributed Multi-Chassis
  ///
  /// Finds all chassis instances across locations and racks that match
  /// the given NE reference.
  static Future<List<Map<String, dynamic>>> findDistributedChassis(
      Database db, String neRef) async {
    final rows = await db.query('instances',
        where: "type_name = 'LocationChassis' OR type_name = 'RackChassis'",
        whereArgs: []);

    final results = <Map<String, dynamic>>[];
    for (final row in rows) {
      final data =
          Map<String, dynamic>.from(jsonDecode(row['data_json'] as String) as Map);
      if (data['ne_ref'] == neRef) {
        data['_instance_id'] = row['id'] as String;
        data['_parent_node_id'] = row['parent_node_id'] as String;
        data['_type_name'] = row['type_name'] as String;
        results.add(data);
      }
    }
    return results;
  }

  /// US-10: Paginated Query
  ///
  /// Returns a sublist of [items] starting at [offset] with at most
  /// [limit] items.
  static List<T> paginate<T>(List<T> items,
      {required int offset, required int limit}) {
    if (offset >= items.length) return [];
    final end = offset + limit;
    if (end > items.length) return items.sublist(offset);
    return items.sublist(offset, end);
  }
}
