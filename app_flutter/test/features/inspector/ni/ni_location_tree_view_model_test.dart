import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app_flutter/domain/database_initializer.dart';
import 'package:app_flutter/domain/data_sources/sqlite_data_source.dart';
import 'package:app_flutter/domain/domain_seed_strategy.dart';
import 'package:app_flutter/features/inspector/ni/ni_location_tree_view_model.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('NiLocationTreeViewModel', () {
    late SqliteDataSource ds;
    late NiLocationTreeViewModel vm;

    Future<void> createVm() async {
      final db = await DatabaseInitializer.create(
        dbPath: inMemoryDatabasePath,
        seed: true,
        seedStrategy: DomainSeedStrategy(),
      );
      ds = SqliteDataSource(db);
      vm = NiLocationTreeViewModel(ds);
      addTearDown(() async {
        await ds.dispose();
      });
    }

    test('loadLocations returns 5 seeded locations', () async {
      await createVm();
      await vm.loadLocations();

      expect(vm.allLocationIds.length, equals(5));
    });

    test('rootLocationIds includes nil_location_site and nil_location_pole',
        () async {
      await createVm();
      await vm.loadLocations();

      expect(vm.rootLocationIds, contains('nil_location_site'));
      expect(vm.rootLocationIds, contains('nil_location_pole'));
      expect(vm.rootLocationIds.length, equals(2));
    });

    test('selectedLocation returns correct data', () async {
      await createVm();
      await vm.loadLocations();
      vm.selectLocation('nil_location_room');

      final selected = vm.selectedLocation;
      expect(selected, isNotNull);
      expect(selected!['_node_id'], equals('nil_location_room'));
      expect(selected['name'], equals('Equipment Room 101'));
      expect(selected['type'], equals('equipment-room'));
    });

    test('dispatchStatusByLocation: site is incomplete, building is ready, room is ready',
        () async {
      await createVm();
      await vm.loadLocations();

      final statuses = vm.dispatchStatusByLocation;
      expect(statuses['nil_location_site'], equals('incomplete'));
      expect(statuses['nil_location_building'], equals('ready'));
      expect(statuses['nil_location_room'], equals('ready'));
    });

    test('breadcrumbs for nil_location_room returns [Tokyo-Campus, Building-A, Room-101]',
        () async {
      await createVm();
      await vm.loadLocations();
      vm.selectLocation('nil_location_room');

      final crumbs = vm.breadcrumbs;
      expect(crumbs.length, equals(3));
      expect(crumbs[0].label, equals('Tokyo Campus'));
      expect(crumbs[0].id, equals('nil_location_site'));
      expect(crumbs[1].label, equals('Building A'));
      expect(crumbs[1].id, equals('nil_location_building'));
      expect(crumbs[2].label, equals('Equipment Room 101'));
      expect(crumbs[2].id, equals('nil_location_room'));
    });

    test('breadcrumbs for nil_location_pole returns single item', () async {
      await createVm();
      await vm.loadLocations();
      vm.selectLocation('nil_location_pole');

      final crumbs = vm.breadcrumbs;
      expect(crumbs.length, equals(1));
      expect(crumbs[0].label, equals('Utility Pole TK-01'));
    });

    test('readyCount and incompleteCount match seed data', () async {
      await createVm();
      await vm.loadLocations();

      expect(vm.readyCount, equals(3));
      expect(vm.incompleteCount, equals(2));
      expect(vm.staleCount, equals(0));
    });

    test('filter filters locations by text', () async {
      await createVm();
      await vm.loadLocations();
      vm.setFilter('Tokyo');

      final filtered = vm.filteredLocations;
      expect(filtered.length, equals(1));
      expect(filtered.first['_node_id'], equals('nil_location_site'));
    });

    test('filter is case-insensitive', () async {
      await createVm();
      await vm.loadLocations();
      vm.setFilter('building');

      final filtered = vm.filteredLocations;
      expect(filtered.length, equals(1));
      expect(filtered.first['_node_id'], equals('nil_location_building'));
    });

    test('expandAll expands all nodes with children', () async {
      await createVm();
      await vm.loadLocations();
      vm.expandAll();

      expect(vm.isExpanded('nil_location_site'), isTrue);
      expect(vm.isExpanded('nil_location_building'), isTrue);
    });

    test('collapseAll collapses all nodes', () async {
      await createVm();
      await vm.loadLocations();
      vm.expandAll();
      vm.collapseAll();

      expect(vm.isExpanded('nil_location_site'), isFalse);
    });

    test('toggleExpanded toggles a node', () async {
      await createVm();
      await vm.loadLocations();

      expect(vm.isExpanded('nil_location_site'), isFalse);
      vm.toggleExpanded('nil_location_site');
      expect(vm.isExpanded('nil_location_site'), isTrue);
      vm.toggleExpanded('nil_location_site');
      expect(vm.isExpanded('nil_location_site'), isFalse);
    });

    test('childrenOf returns correct children', () async {
      await createVm();
      await vm.loadLocations();

      final children = vm.childrenOf('nil_location_site');
      expect(children.length, equals(1));
      expect(children.first['_node_id'], equals('nil_location_building'));

      final subChildren = vm.childrenOf('nil_location_building');
      expect(subChildren.length, equals(2));
    });

    test('hasChildren returns true for parent nodes', () async {
      await createVm();
      await vm.loadLocations();

      expect(vm.hasChildren('nil_location_site'), isTrue);
      expect(vm.hasChildren('nil_location_building'), isTrue);
      expect(vm.hasChildren('nil_location_room'), isFalse);
      expect(vm.hasChildren('nil_location_pole'), isFalse);
    });
  });
}
