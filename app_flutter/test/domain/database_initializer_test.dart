import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app_flutter/domain/database_initializer.dart';
import 'package:app_flutter/domain/domain_seed_strategy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseInitializer spatial seeding', () {
    test('regenerate assets database', () async {
      final dbPath = 'assets/properties_db.db';
      final file = File(dbPath);
      if (await file.exists()) {
        await file.delete();
      }
      // Inject DomainSeedStrategy to ensure the generated asset is fully populated with mock topology data
      final db = await DatabaseInitializer.create(
        dbPath: dbPath,
        seed: true,
        seedStrategy: DomainSeedStrategy(),
      );
      await db.close();

      final gzFile = File('assets/properties_db.db.gz');
      if (await gzFile.exists()) {
        await gzFile.delete();
      }
      final bytes = await file.readAsBytes();
      final gzipped = gzip.encode(bytes);
      await gzFile.writeAsBytes(gzipped);
      expect(await gzFile.exists(), isTrue);
    });

    test('T9: After seeding, GeoLocation type is discoverable with timestamp and valid_until fields', () async {
      final db = await DatabaseInitializer.create(
        dbPath: inMemoryDatabasePath,
        seed: true,
        seedStrategy: DomainSeedStrategy(),
      );

      final typeRows = await db.query('type_definitions',
          where: 'type_name = ?', whereArgs: ['GeoLocation']);
      expect(typeRows, isNotEmpty);
      expect(typeRows.first['display_name'], equals('Geo Location'));
      expect(typeRows.first['icon_name'], equals('location_on'));

      final attrRows = await db.query('type_attributes',
          where: 'type_name = ?', whereArgs: ['GeoLocation']);
      final attrKeys = attrRows.map((r) => r['attr_key'] as String).toList();
      expect(attrKeys, contains('timestamp'));
      expect(attrKeys, contains('valid_until'));

      final timestampRow = attrRows.firstWhere((r) => r['attr_key'] == 'timestamp');
      expect(timestampRow['attr_type'], equals('date'));
      expect(timestampRow['section_label'], equals('Temporal'));
      expect(timestampRow['is_required'], equals(0));
      expect(timestampRow['pattern'], isNotNull);

      final validUntilRow = attrRows.firstWhere((r) => r['attr_key'] == 'valid_until');
      expect(validUntilRow['attr_type'], equals('date'));
      expect(validUntilRow['section_label'], equals('Temporal'));
      expect(validUntilRow['is_required'], equals(0));

      final relRows = await db.query('type_relations',
          where: 'parent_type_name = ? AND child_type_name = ?',
          whereArgs: ['Components', 'GeoLocation']);
      expect(relRows, isNotEmpty);

      final propRows = await db.query('properties',
          where: 'node_id = ?', whereArgs: ['geo_location_root']);
      expect(propRows, isNotEmpty);

      await db.close();
    });
  });
}
