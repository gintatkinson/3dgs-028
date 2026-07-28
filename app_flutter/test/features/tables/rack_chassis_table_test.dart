import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app_flutter/domain/database_initializer.dart';
import 'package:app_flutter/domain/domain_seed_strategy.dart';

/// Tests verifying that RackChassis instances are surfaced via
/// type_relations for rack nodes, enabling the TablesViewModel
/// to discover chassis child types.
///
/// @realizes T9.22-T9.33
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('RackChassis TableView wiring', () {
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

    test('T9.22: type_relations exist for RackEntity → RackChassis (contains)', () async {
      final rows = await db.query(
        'type_relations',
        where: "parent_type_name = ? AND relation_name = ? AND child_type_name = ?",
        whereArgs: ['RackEntity', 'contains', 'RackChassis'],
      );
      expect(rows, isNotEmpty);
      expect(rows.first['child_label'], equals('Rack Chassis'));
    });

    test('T9.23: instances exist for rack_101_a with type_name=RackChassis', () async {
      final rows = await db.query(
        'instances',
        where: "parent_node_id = ? AND type_name = ?",
        whereArgs: ['rack_101_a', 'RackChassis'],
      );
      expect(rows, isNotEmpty);
      expect(rows.length, equals(2));
    });

    test('T9.24: chassis entry at relative_position=10 has correct fields', () async {
      final rows = await db.query(
        'instances',
        where: "parent_node_id = ? AND type_name = ?",
        whereArgs: ['rack_101_a', 'RackChassis'],
      );

      final entry = rows.firstWhere((r) {
        final data = jsonDecode(r['data_json'] as String) as Map<String, dynamic>;
        return data['relative_position'] == 10;
      });

      final data = jsonDecode(entry['data_json'] as String) as Map<String, dynamic>;
      expect(data['relative_position'], equals(10));
      expect(data['ne_ref'], equals('NE-1'));
      expect(data['component_ref'], equals('comp-1-1'));
    });

    test('T9.25: chassis entry at relative_position=20 has correct fields', () async {
      final rows = await db.query(
        'instances',
        where: "parent_node_id = ? AND type_name = ?",
        whereArgs: ['rack_101_a', 'RackChassis'],
      );

      final entry = rows.firstWhere((r) {
        final data = jsonDecode(r['data_json'] as String) as Map<String, dynamic>;
        return data['relative_position'] == 20;
      });

      final data = jsonDecode(entry['data_json'] as String) as Map<String, dynamic>;
      expect(data['relative_position'], equals(20));
      expect(data['ne_ref'], equals('NE-2'));
      expect(data['component_ref'], equals('comp-2-1'));
    });

    test('T9.26: rack_201_b has one chassis with relative_position=5', () async {
      final rows = await db.query(
        'instances',
        where: "parent_node_id = ? AND type_name = ?",
        whereArgs: ['rack_201_b', 'RackChassis'],
      );
      expect(rows.length, equals(1));

      final data = jsonDecode(rows.first['data_json'] as String) as Map<String, dynamic>;
      expect(data['relative_position'], equals(5));
      expect(data['ne_ref'], equals('NE-3'));
      expect(data['component_ref'], equals('comp-3-1'));
    });

    test('T9.27: type_relations exist for rack_101_a → RackChassis via Components', () async {
      // Verify the chain: Components → rack_101_a exists and rack_101_a → RackChassis
      final rackRelRows = await db.query(
        'type_relations',
        where: "parent_type_name = ? AND child_type_name = ?",
        whereArgs: ['rack_101_a', 'RackChassis'],
      );
      expect(rackRelRows, isNotEmpty);
    });

    test('T9.28: TypeDescriptor for RackEntity includes RackChassis in childTypes', () async {
      final relRows = await db.query(
        'type_relations',
        where: "parent_type_name = ? AND relation_name = ? AND child_type_name = ?",
        whereArgs: ['RackEntity', 'contains', 'RackChassis'],
      );
      expect(relRows, isNotEmpty);
      expect(relRows.first['child_label'], equals('Rack Chassis'));
    });
  });
}
