import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app_flutter/domain/database_initializer.dart';
import 'package:app_flutter/domain/data_sources/sqlite_data_source.dart';
import 'package:app_flutter/domain/domain_seed_strategy.dart';
import 'package:app_flutter/features/inspector/racks/rack_table_view_model.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('RackTableViewModel', () {
    late SqliteDataSource ds;
    late RackTableViewModel vm;

    Future<void> createVm() async {
      final db = await DatabaseInitializer.create(
        dbPath: inMemoryDatabasePath,
        seed: true,
        seedStrategy: DomainSeedStrategy(),
      );
      ds = SqliteDataSource(db);
      vm = RackTableViewModel(ds);
      addTearDown(() async {
        await ds.dispose();
      });
    }

    test('loadRacks returns 2 seeded racks', () async {
      await createVm();
      await vm.loadRacks();

      expect(vm.racks.length, equals(2));
      expect(vm.racks.map((r) => r['_node_id']), contains('rack_101_a'));
      expect(vm.racks.map((r) => r['_node_id']), contains('rack_201_b'));
    });

    test('filteredRacks filters by id text', () async {
      await createVm();
      await vm.loadRacks();
      vm.setFilter('101');

      final filtered = vm.filteredRacks;
      expect(filtered.length, equals(1));
      expect(filtered.first['_node_id'], equals('rack_101_a'));
    });

    test('filteredRacks filters by rack_class', () async {
      await createVm();
      await vm.loadRacks();
      vm.setFilter('standard');

      final filtered = vm.filteredRacks;
      expect(filtered.length, equals(1));
      expect(filtered.first['_node_id'], equals('rack_201_b'));
    });

    test('filteredRacks is case-insensitive', () async {
      await createVm();
      await vm.loadRacks();
      vm.setFilter('RACK');

      final filtered = vm.filteredRacks;
      expect(filtered.length, equals(2));
    });

    test('filteredRacks empty filter returns all racks', () async {
      await createVm();
      await vm.loadRacks();

      expect(vm.filteredRacks.length, equals(2));
    });

    test('selectedRack returns full rack data', () async {
      await createVm();
      await vm.loadRacks();
      vm.selectRack('rack_101_a');

      final selected = vm.selectedRack;
      expect(selected, isNotNull);
      expect(selected!['_node_id'], equals('rack_101_a'));
      expect(selected['rack_class'], equals('rack-secure-medium'));
      expect(selected['height'], equals(2200));
      expect(selected['width'], equals(600));
      expect(selected['depth'], equals(1200));
      expect(selected['max_voltage'], equals(240));
      expect(selected['max_allocated_power'], equals(8000));
    });

    test('rackPlacement returns placement data for rack_101_a', () async {
      await createVm();
      await vm.loadRacks();
      vm.selectRack('rack_101_a');

      final placement = vm.rackPlacement;
      expect(placement, isNotNull);
      expect(placement!['location_ref'], equals('nil_location_room'));
      expect(placement['row_number'], equals(1));
      expect(placement['column_number'], equals(1));
    });

    test('rackPlacement returns correct data for rack_201_b', () async {
      await createVm();
      await vm.loadRacks();
      vm.selectRack('rack_201_b');

      final placement = vm.rackPlacement;
      expect(placement, isNotNull);
      expect(placement!['location_ref'], equals('nil_location_room2'));
    });

    test('rackChassis returns 2 chassis for rack_101_a', () async {
      await createVm();
      await vm.loadRacks();
      vm.selectRack('rack_101_a');

      final chassis = vm.rackChassis;
      expect(chassis.length, equals(2));
      expect(chassis[0]['relative_position'], equals(10));
      expect(chassis[1]['relative_position'], equals(20));
    });

    test('rackChassis returns 1 chassis for rack_201_b', () async {
      await createVm();
      await vm.loadRacks();
      vm.selectRack('rack_201_b');

      final chassis = vm.rackChassis;
      expect(chassis.length, equals(1));
      expect(chassis[0]['relative_position'], equals(5));
    });

    test('chassisCount returns correct value', () async {
      await createVm();
      await vm.loadRacks();
      vm.selectRack('rack_101_a');

      expect(vm.chassisCount, equals(2));

      vm.selectRack('rack_201_b');
      expect(vm.chassisCount, equals(1));
    });

    test('powerUtilizationPercent returns 0% when no chassis have power_draw',
        () async {
      await createVm();
      await vm.loadRacks();
      vm.selectRack('rack_101_a');

      expect(vm.powerUtilizationPercent, equals(0.0));
    });

    test('remainingPowerWatts equals max_allocated_power when no power_draw',
        () async {
      await createVm();
      await vm.loadRacks();
      vm.selectRack('rack_101_a');

      expect(vm.remainingPowerWatts, equals(8000.0));
    });

    test('sortBy sorts by column ascending then descending', () async {
      await createVm();
      await vm.loadRacks();

      vm.sortBy('rack_class');
      var sorted = vm.filteredRacks;
      expect(sorted[0]['_node_id'], equals('rack_101_a'));
      expect(sorted[1]['_node_id'], equals('rack_201_b'));

      vm.sortBy('rack_class');
      sorted = vm.filteredRacks;
      expect(sorted[0]['_node_id'], equals('rack_201_b'));
      expect(sorted[1]['_node_id'], equals('rack_101_a'));
    });

    test('sortBy sorts by height', () async {
      await createVm();
      await vm.loadRacks();

      vm.sortBy('height');
      var sorted = vm.filteredRacks;
      expect(sorted[0]['_node_id'], equals('rack_201_b'));
      expect(sorted[1]['_node_id'], equals('rack_101_a'));
    });

    test('selectedRackId is null initially', () async {
      await createVm();
      await vm.loadRacks();

      expect(vm.selectedRackId, isNull);
      expect(vm.selectedRack, isNull);
      expect(vm.rackPlacement, isNull);
      expect(vm.rackChassis, isEmpty);
    });

    test('rackPlacement is null when selectedRackId is null', () async {
      await createVm();
      await vm.loadRacks();

      expect(vm.rackPlacement, isNull);
    });

    test('loading is true during load', () async {
      await createVm();

      var loadingDuringLoad = false;
      vm.addListener(() {
        if (vm.loading) loadingDuringLoad = true;
      });

      await vm.loadRacks();
      expect(loadingDuringLoad, isTrue);
      expect(vm.loading, isFalse);
    });
  });
}
