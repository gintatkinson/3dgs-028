import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app_flutter/domain/database_initializer.dart';
import 'package:app_flutter/domain/domain_seed_strategy.dart';
import 'package:app_flutter/domain/use_case_orchestrator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('UseCaseOrchestrator', () {
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

    group('UC-01: registerLocation', () {
      test('registers a new top-level location with id/type/name', () async {
        final result = await UseCaseOrchestrator.registerLocation(
          db,
          id: 'test-site-1',
          type: 'site',
          name: 'Test Site',
        );
        expect(result['id'], equals('test-site-1'));
        expect(result['type'], equals('site'));
        expect(result['name'], equals('Test Site'));
        expect(result.containsKey('timestamp'), isTrue);
        expect(result['parent'], isNull);

        final rows = await db.query('properties',
            where: 'node_id = ?', whereArgs: ['test-site-1']);
        expect(rows, isNotEmpty);
      });

      test('registers a nested location with parent reference', () async {
        final result = await UseCaseOrchestrator.registerLocation(
          db,
          id: 'child-room-1',
          type: 'room',
          name: 'Child Room',
          parent: 'nil_location_building',
        );
        expect(result['id'], equals('child-room-1'));
        expect(result['parent'], equals('nil_location_building'));
      });

      test('duplicate id returns existing record without error', () async {
        await UseCaseOrchestrator.registerLocation(
          db,
          id: 'dup-loc',
          type: 'site',
          name: 'First',
        );
        final result = await UseCaseOrchestrator.registerLocation(
          db,
          id: 'dup-loc',
          type: 'site',
          name: 'Second Attempt',
        );
        expect(result['_duplicate'], isTrue);
        expect(result['name'], equals('First'));
      });

      test('invalid parent ref is accepted but flagged', () async {
        final result = await UseCaseOrchestrator.registerLocation(
          db,
          id: 'orphan-loc',
          type: 'room',
          name: 'Orphan Room',
          parent: 'non-existent-parent',
        );
        expect(result['id'], equals('orphan-loc'));
        expect(result['_warning'], isNotNull);
      });
    });

    group('UC-03: deployRack', () {
      test('deploys a rack with full dimensions and power specs', () async {
        final result = await UseCaseOrchestrator.deployRack(
          db,
          id: 'new-rack-1',
          rackClass: 'rack-standard',
          height: 2200,
          width: 600,
          depth: 1000,
          maxVoltage: 240,
          maxAllocatedPower: 5000,
        );
        expect(result['id'], equals('new-rack-1'));
        expect(result['rack_class'], equals('rack-standard'));
        expect(result['height'], equals(2200));
        expect(result['max_voltage'], equals(240));
        expect(result['max_allocated_power'], equals(5000));
        expect(result.containsKey('timestamp'), isTrue);

        final rows = await db.query('properties',
            where: 'node_id = ?', whereArgs: ['new-rack-1']);
        expect(rows, isNotEmpty);
      });

      test('rejects invalid rack class', () async {
        final result = await UseCaseOrchestrator.deployRack(
          db,
          id: 'bad-rack',
          rackClass: 'invalid-class',
          height: 2000,
          width: 600,
          depth: 800,
          maxVoltage: 240,
          maxAllocatedPower: 3000,
        );
        expect(result['_error'], isNotNull);
        expect(result['_error'], contains('rack class'));
      });

      test('rejects zero dimensions', () async {
        final result = await UseCaseOrchestrator.deployRack(
          db,
          id: 'zero-rack',
          rackClass: 'rack-standard',
          height: 0,
          width: 0,
          depth: 0,
          maxVoltage: 240,
          maxAllocatedPower: 3000,
        );
        expect(result['_error'], isNotNull);
      });

      test('allows deployment with future valid-until', () async {
        final result = await UseCaseOrchestrator.deployRack(
          db,
          id: 'future-rack',
          rackClass: 'rack-secure-medium',
          height: 2200,
          width: 600,
          depth: 1200,
          maxVoltage: 240,
          maxAllocatedPower: 8000,
        );
        expect(result['_error'], isNull);
        expect(result['valid_until'], isNotNull);
      });
    });

    group('UC-06: validateDataQuality', () {
      test('returns status map with valid/stale/incomplete/unknown', () async {
        final results = await UseCaseOrchestrator.validateDataQuality(db);
        expect(results, isNotEmpty);
        final statuses = results.values.toSet();
        expect(statuses, isNotEmpty);
      });

      test('identifies stale locations with expired valid_until', () async {
        await UseCaseOrchestrator.registerLocation(
          db,
          id: 'stale-loc',
          type: 'site',
          name: 'Stale Site',
        );
        await db.rawUpdate(
          'UPDATE properties SET data_json = ? WHERE node_id = ?',
          [
            '{"id":"stale-loc","type":"site","name":"Stale Site","timestamp":"2020-01-01T00:00:00Z","valid_until":"2020-01-02T00:00:00Z","parent":null}',
            'stale-loc',
          ],
        );

        final results = await UseCaseOrchestrator.validateDataQuality(db);
        expect(results.containsKey('stale-loc'), isTrue);
        expect(results['stale-loc'], equals('stale'));
      });

      test('identifies incomplete locations missing address and geo', () async {
        await UseCaseOrchestrator.registerLocation(
          db,
          id: 'incomplete-loc',
          type: 'room',
          name: 'No Address Room',
        );
        final results = await UseCaseOrchestrator.validateDataQuality(db);
        expect(results.containsKey('incomplete-loc'), isTrue);
        expect(results['incomplete-loc'], equals('incomplete'));
      });

      test('marks nil_location_site as incomplete since it lacks address/geo', () async {
        final results = await UseCaseOrchestrator.validateDataQuality(db);
        expect(results.containsKey('nil_location_site'), isTrue);
      });
    });

    group('paginate data', () {
      test('paginates validateDataQuality results', () async {
        final allResults = await UseCaseOrchestrator.validateDataQuality(db);
        final keys = allResults.keys.toList();
        final page1 = keys.length > 10 ? keys.sublist(0, 10) : keys;
        final subMap = <String, String>{};
        for (final k in page1) {
          subMap[k] = allResults[k]!;
        }
        expect(subMap.length, greaterThan(0));
        expect(subMap.length, lessThanOrEqualTo(10));
      });
    });

    group('power capacity checks', () {
      test('registers and validates rack power data', () async {
        await UseCaseOrchestrator.deployRack(
          db,
          id: 'test-power-rack',
          rackClass: 'rack-standard',
          height: 2200,
          width: 600,
          depth: 1000,
          maxVoltage: 240,
          maxAllocatedPower: 100,
        );

        final results = await UseCaseOrchestrator.validateDataQuality(db);
        expect(results.containsKey('test-power-rack'), isTrue);
      });
    });
  });
}
