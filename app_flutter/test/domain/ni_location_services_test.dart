import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app_flutter/domain/database_initializer.dart';
import 'package:app_flutter/domain/domain_seed_strategy.dart';
import 'package:app_flutter/domain/ni_location_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('NiLocationServices', () {
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

    group('queryLocationHierarchy', () {
      test('returns NI Location rows with id/type/parent fields', () async {
        final locations = await NiLocationServices.queryLocationHierarchy(db);
        expect(locations, isNotEmpty);
        for (final loc in locations) {
          expect(loc.containsKey('id'), isTrue);
          expect(loc.containsKey('type'), isTrue);
          expect(loc.containsKey('parent'), isTrue);
        }
      });

      test('includes the seeded site/building/room/pole entries', () async {
        final locations = await NiLocationServices.queryLocationHierarchy(db);
        final ids = locations.map((l) => l['id'] as String).toSet();
        expect(ids, contains('nil_location_site'));
        expect(ids, contains('nil_location_building'));
        expect(ids, contains('nil_location_room'));
        expect(ids, contains('nil_location_room2'));
        expect(ids, contains('nil_location_pole'));
      });
    });

    group('validateDispatchReadiness', () {
      test('returns null for complete location with address', () {
        final result = NiLocationServices.validateDispatchReadiness({
          'id': 'loc-1',
          'postal_code': '160-0022',
          'city': 'Shinjuku',
          'country_code': 'JP',
          'timestamp': '2024-01-01T00:00:00Z',
        });
        expect(result, isNull);
      });

      test('returns null for complete location with geo-location', () {
        final result = NiLocationServices.validateDispatchReadiness({
          'id': 'loc-1',
          'latitude': 35.0,
          'longitude': 139.0,
          'timestamp': '2024-01-01T00:00:00Z',
        });
        expect(result, isNull);
      });

      test('returns incomplete when neither address nor geo-location present', () {
        final result = NiLocationServices.validateDispatchReadiness({
          'id': 'loc-1',
          'timestamp': '2024-01-01T00:00:00Z',
        });
        expect(result, equals('incomplete'));
      });

      test('returns stale when valid_until is expired', () {
        final result = NiLocationServices.validateDispatchReadiness({
          'id': 'loc-1',
          'latitude': 35.0,
          'longitude': 139.0,
          'valid_until': '2020-01-01T00:00:00Z',
        });
        expect(result, equals('stale'));
      });

      test('returns null when valid_until is in the future', () {
        final result = NiLocationServices.validateDispatchReadiness({
          'id': 'loc-1',
          'latitude': 35.0,
          'longitude': 139.0,
          'valid_until': '2099-01-01T00:00:00Z',
        });
        expect(result, isNull);
      });

      test('returns null when valid_until is absent', () {
        final result = NiLocationServices.validateDispatchReadiness({
          'id': 'loc-1',
          'latitude': 35.0,
          'longitude': 139.0,
        });
        expect(result, isNull);
      });

      test('nil_location_pole has neither address nor geo → incomplete', () async {
        final locations = await NiLocationServices.queryLocationHierarchy(db);
        final pole = locations.firstWhere(
            (l) => l['_node_id'] == 'nil_location_pole');
        final result = NiLocationServices.validateDispatchReadiness(pole);
        expect(result, equals('incomplete'));
      });

      test('nil_location_building has address → ready (null)', () async {
        final locations = await NiLocationServices.queryLocationHierarchy(db);
        final building = locations.firstWhere(
            (l) => l['_node_id'] == 'nil_location_building');
        final result = NiLocationServices.validateDispatchReadiness(building);
        expect(result, isNull);
      });

      test('nil_location_room has geo → ready (null)', () async {
        final locations = await NiLocationServices.queryLocationHierarchy(db);
        final room = locations.firstWhere(
            (l) => l['_node_id'] == 'nil_location_room');
        final result = NiLocationServices.validateDispatchReadiness(room);
        expect(result, isNull);
      });

      test('nil_location_room2 has both address and geo → ready (null)', () async {
        final locations = await NiLocationServices.queryLocationHierarchy(db);
        final room2 = locations.firstWhere(
            (l) => l['_node_id'] == 'nil_location_room2');
        final result = NiLocationServices.validateDispatchReadiness(room2);
        expect(result, isNull);
      });

      test('nil_location_site has neither address nor geo → incomplete', () async {
        final locations = await NiLocationServices.queryLocationHierarchy(db);
        final site = locations.firstWhere(
            (l) => l['_node_id'] == 'nil_location_site');
        final result = NiLocationServices.validateDispatchReadiness(site);
        expect(result, equals('incomplete'));
      });
    });

    group('isLocationStale', () {
      test('returns true for expired valid_until', () {
        expect(NiLocationServices.isLocationStale({
          'valid_until': '2020-01-01T00:00:00Z',
        }), isTrue);
      });

      test('returns false for future valid_until', () {
        expect(NiLocationServices.isLocationStale({
          'valid_until': '2099-01-01T00:00:00Z',
        }), isFalse);
      });

      test('returns false when valid_until is absent', () {
        expect(NiLocationServices.isLocationStale({}), isFalse);
      });

      test('returns false for unparseable valid_until', () {
        expect(NiLocationServices.isLocationStale({
          'valid_until': 'not-a-date',
        }), isFalse);
      });
    });

    group('filterStaleLocations', () {
      test('separates stale from valid locations', () {
        final locations = [
          {'id': 'loc-1', 'valid_until': '2020-01-01T00:00:00Z'},
          {'id': 'loc-2', 'valid_until': '2099-01-01T00:00:00Z'},
          {'id': 'loc-3'},
          {'id': 'loc-4', 'valid_until': '2019-01-01T00:00:00Z'},
        ];
        final stale = NiLocationServices.filterStaleLocations(locations);
        expect(stale.length, equals(2));
        expect(stale[0]['id'], equals('loc-1'));
        expect(stale[1]['id'], equals('loc-4'));
      });

      test('returns empty list when all locations are valid', () {
        final locations = [
          {'id': 'loc-1', 'valid_until': '2099-01-01T00:00:00Z'},
          {'id': 'loc-2'},
        ];
        final stale = NiLocationServices.filterStaleLocations(locations);
        expect(stale, isEmpty);
      });
    });

    group('queryRackInventory', () {
      test('returns rack entity rows with dimension and power fields', () async {
        final racks = await NiLocationServices.queryRackInventory(db);
        expect(racks, isNotEmpty);

        final ids = racks.map((r) => r['id'] as String).toSet();
        expect(ids, contains('rack_101_a'));
        expect(ids, contains('rack_201_b'));

        for (final rack in racks) {
          expect(rack.containsKey('height'), isTrue);
          expect(rack.containsKey('width'), isTrue);
          expect(rack.containsKey('depth'), isTrue);
          expect(rack.containsKey('max_voltage'), isTrue);
          expect(rack.containsKey('max_allocated_power'), isTrue);
          expect(rack.containsKey('rack_class'), isTrue);
        }
      });
    });

    group('calculateRackCapacity', () {
      test('returns correct utilization for chassis within budget', () {
        final result = NiLocationServices.calculateRackCapacity(
          maxAllocatedPower: 8000,
          chassisPowerDraws: [1000, 2000, 1500],
        );
        expect(result['totalDraw'], equals(4500.0));
        expect(result['remainingCapacity'], equals(3500.0));
        expect(result['utilizationPercent'], closeTo(56.25, 0.01));
      });

      test('returns 0 remaining when chassis consume full capacity', () {
        final result = NiLocationServices.calculateRackCapacity(
          maxAllocatedPower: 5000,
          chassisPowerDraws: [2500, 2500],
        );
        expect(result['totalDraw'], equals(5000.0));
        expect(result['remainingCapacity'], equals(0.0));
        expect(result['utilizationPercent'], closeTo(100.0, 0.01));
      });

      test('handles empty chassis list', () {
        final result = NiLocationServices.calculateRackCapacity(
          maxAllocatedPower: 8000,
          chassisPowerDraws: [],
        );
        expect(result['totalDraw'], equals(0.0));
        expect(result['remainingCapacity'], equals(8000.0));
        expect(result['utilizationPercent'], equals(0.0));
      });

      test('returns negative remaining when over budget', () {
        final result = NiLocationServices.calculateRackCapacity(
          maxAllocatedPower: 5000,
          chassisPowerDraws: [3000, 3000],
        );
        expect(result['totalDraw'], equals(6000.0));
        expect(result['remainingCapacity'], equals(-1000.0));
      });
    });

    group('canFitChassis', () {
      test('returns true when chassis fits within rack height', () {
        expect(
          NiLocationServices.canFitChassis(
            rackHeight: 2200,
            relativePosition: 10,
            chassisHeight: 40,
          ),
          isTrue,
        );
      });

      test('returns false when chassis exceeds rack height', () {
        expect(
          NiLocationServices.canFitChassis(
            rackHeight: 2200,
            relativePosition: 2190,
            chassisHeight: 40,
          ),
          isFalse,
        );
      });

      test('returns true when chassis fits exactly at top', () {
        expect(
          NiLocationServices.canFitChassis(
            rackHeight: 2200,
            relativePosition: 2160,
            chassisHeight: 40,
          ),
          isTrue,
        );
      });
    });

    group('traceTopology', () {
      test('traces Site-Building-Room-Rack-Chassis chain for a known chassis', () async {
        final chain = await NiLocationServices.traceTopology(
          db,
          'inst_rack_101_a_RackChassis_10',
        );
        expect(chain.length, greaterThanOrEqualTo(3));
        expect(chain, contains('nil_location_site'));
        expect(chain, contains('nil_location_building'));
        expect(chain, contains('nil_location_room'));
        expect(chain, contains('rack_101_a'));
      });

      test('returns rack-less chain when chassis has no rack parent', () async {
        final chain = await NiLocationServices.traceTopology(
          db,
          'inst_ntt_exchange_0_LocationChassis_1',
        );
        expect(chain, isNotEmpty);
        expect(chain, contains('ntt_exchange_0'));
      });
    });

    group('findDistributedChassis', () {
      test('finds all chassis with matching ne-ref', () async {
        final results = await NiLocationServices.findDistributedChassis(
          db,
          'NE-1',
        );
        expect(results, isNotEmpty);
        for (final r in results) {
          expect(r['ne_ref'], equals('NE-1'));
        }
      });

      test('returns empty list for non-existent ne-ref', () async {
        final results = await NiLocationServices.findDistributedChassis(
          db,
          'NE-NONEXISTENT',
        );
        expect(results, isEmpty);
      });
    });

    group('paginate', () {
      test('returns first page of items', () {
        final items = List.generate(25, (i) => 'item-$i');
        final page = NiLocationServices.paginate(items, offset: 0, limit: 10);
        expect(page.length, equals(10));
        expect(page[0], equals('item-0'));
        expect(page[9], equals('item-9'));
      });

      test('returns second page of items', () {
        final items = List.generate(25, (i) => 'item-$i');
        final page = NiLocationServices.paginate(items, offset: 10, limit: 10);
        expect(page.length, equals(10));
        expect(page[0], equals('item-10'));
        expect(page[9], equals('item-19'));
      });

      test('returns partial page at end of list', () {
        final items = List.generate(25, (i) => 'item-$i');
        final page = NiLocationServices.paginate(items, offset: 20, limit: 10);
        expect(page.length, equals(5));
      });

      test('returns empty list when offset exceeds list length', () {
        final items = List.generate(10, (i) => 'item-$i');
        final page = NiLocationServices.paginate(items, offset: 20, limit: 10);
        expect(page, isEmpty);
      });
    });
  });
}
