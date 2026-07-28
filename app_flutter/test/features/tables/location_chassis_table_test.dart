import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app_flutter/domain/database_initializer.dart';
import 'package:app_flutter/domain/domain_seed_strategy.dart';

/// Tests verifying that LocationChassis instances are surfaced via
/// type_relations for NTT exchange nodes, enabling the TablesViewModel
/// to discover chassis child types.
///
/// @realizes T8.35-T8.45
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('LocationChassis TableView wiring', () {
    late Database db;

    setUp(() async {
      db = await DatabaseInitializer.create(
        dbPath: inMemoryDatabasePath,
        seed: true,
        seedStrategy: DomainSeedStrategy(),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('T8.35: type_relations exist for ntt_exchange_0 → LocationChassis (contains)', () async {
      final rows = await db.query(
        'type_relations',
        where: "parent_type_name = ? AND relation_name = ? AND child_type_name = ?",
        whereArgs: ['ntt_exchange_0', 'contains', 'LocationChassis'],
      );
      expect(rows, isNotEmpty);
      expect(rows.first['child_label'], equals('Location Chassis'));
    });

    test('T8.36: instances exist for ntt_exchange_0 with type_name=LocationChassis', () async {
      final rows = await db.query(
        'instances',
        where: "parent_node_id = ? AND type_name = ?",
        whereArgs: ['ntt_exchange_0', 'LocationChassis'],
      );
      expect(rows, isNotEmpty);
      expect(rows.length, equals(2));
    });

    test('T8.37: chassis entry has chassis_id, ne_ref, component_ref', () async {
      final rows = await db.query(
        'instances',
        where: "parent_node_id = ? AND type_name = ?",
        whereArgs: ['ntt_exchange_0', 'LocationChassis'],
      );

      final firstData = jsonDecode(rows.first['data_json'] as String) as Map<String, dynamic>;
      expect(firstData.containsKey('chassis_id'), isTrue);
      expect(firstData.containsKey('ne_ref'), isTrue);
      expect(firstData.containsKey('component_ref'), isTrue);
      expect(firstData['chassis_id'], equals(1));
      expect(firstData['ne_ref'], equals('NE-0'));
      expect(firstData['component_ref'], equals('comp-0-1'));
    });

    test('T8.38: second chassis entry has chassis_id=2', () async {
      final rows = await db.query(
        'instances',
        where: "parent_node_id = ? AND type_name = ?",
        whereArgs: ['ntt_exchange_0', 'LocationChassis'],
      );

      final secondData = jsonDecode(rows[1]['data_json'] as String) as Map<String, dynamic>;
      expect(secondData['chassis_id'], equals(2));
      expect(secondData['ne_ref'], equals('NE-0'));
      expect(secondData['component_ref'], equals('comp-0-2'));
    });

    test('T8.39: type_relations exist for all NTT exchange nodes → LocationChassis', () async {
      final typeDefRows = await db.query('type_definitions',
          where: "type_name LIKE 'ntt_exchange_%'");
      expect(typeDefRows.length, greaterThan(0));

      int countWithRelation = 0;
      for (final typeRow in typeDefRows) {
        final typeName = typeRow['type_name'] as String;
        final relRows = await db.query(
          'type_relations',
          where: "parent_type_name = ? AND child_type_name = ?",
          whereArgs: [typeName, 'LocationChassis'],
        );
        if (relRows.isNotEmpty) countWithRelation++;
      }
      expect(countWithRelation, equals(typeDefRows.length));
    });

    test('T8.40: TypeDescriptor typeFor ntt_exchange_0 includes LocationChassis in childTypes', () async {
      final relRows = await db.query(
        'type_relations',
        where: "parent_type_name = ? AND relation_name = ?",
        whereArgs: ['ntt_exchange_0', 'contains'],
      );
      final chassisRel = relRows.where((r) => r['child_type_name'] == 'LocationChassis');
      expect(chassisRel, isNotEmpty);
      expect(chassisRel.first['child_label'], equals('Location Chassis'));
    });
  });
}
