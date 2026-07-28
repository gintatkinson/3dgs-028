import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app_flutter/domain/database_initializer.dart';
import 'package:app_flutter/domain/data_sources/sqlite_data_source.dart';
import 'package:app_flutter/domain/domain_seed_strategy.dart';
import 'package:app_flutter/features/inspector/quality/quality_view_model.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('QualityDashboardViewModel', () {
    late SqliteDataSource ds;
    late QualityDashboardViewModel vm;

    Future<void> createVm() async {
      final db = await DatabaseInitializer.create(
        dbPath: inMemoryDatabasePath,
        seed: true,
        seedStrategy: DomainSeedStrategy(),
      );
      ds = SqliteDataSource(db);
      vm = QualityDashboardViewModel(ds);
      addTearDown(() async {
        await ds.dispose();
      });
    }

    test('runValidation returns status for all nodes', () async {
      await createVm();
      await vm.runValidation();

      expect(vm.totalCount, greaterThan(0));
      final results = vm.statusByNodeId;
      expect(results, isNotEmpty);
    });

    test('validCount counts nodes with valid status', () async {
      await createVm();
      await vm.runValidation();

      expect(vm.validCount, equals(3));
    });

    test('staleCount counts nodes with stale status', () async {
      await createVm();
      await vm.runValidation();

      expect(vm.staleCount, equals(1));
    });

    test('incompleteCount counts nodes with incomplete status', () async {
      await createVm();
      await vm.runValidation();

      expect(vm.incompleteCount, greaterThan(0));
    });

    test('paginatedResults returns correct page size', () async {
      await createVm();
      await vm.runValidation();

      final page = vm.paginatedResults;
      expect(page.length, lessThanOrEqualTo(25));
      if (vm.totalCount > 25) {
        expect(page.length, equals(25));
      }
    });

    test('nextPage advances to next page', () async {
      await createVm();
      await vm.runValidation();

      vm.nextPage();
      expect(vm.currentPage, equals(1));
    });

    test('prevPage returns to previous page', () async {
      await createVm();
      await vm.runValidation();

      vm.nextPage();
      expect(vm.currentPage, equals(1));
      vm.prevPage();
      expect(vm.currentPage, equals(0));
    });

    test('prevPage does not go below 0', () async {
      await createVm();
      await vm.runValidation();

      vm.prevPage();
      expect(vm.currentPage, equals(0));
    });

    test('filterStatus filters by status', () async {
      await createVm();
      await vm.runValidation();

      vm.setFilterStatus('valid');
      final page = vm.paginatedResults;
      for (final item in page) {
        expect(item['status'], equals('valid'));
      }
    });

    test('filterType filters by type', () async {
      await createVm();
      await vm.runValidation();

      vm.setFilterType('site');
      final page = vm.paginatedResults;
      for (final item in page) {
        expect(item['nodeId'].toString(), equals('nil_location_site'));
      }
    });

    test('nil_location_site status is incomplete', () async {
      await createVm();
      await vm.runValidation();

      expect(vm.statusByNodeId['nil_location_site'], equals('incomplete'));
    });

    test('nil_location_building status is valid', () async {
      await createVm();
      await vm.runValidation();

      expect(vm.statusByNodeId['nil_location_building'], equals('valid'));
    });
  });
}
