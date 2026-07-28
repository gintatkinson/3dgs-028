import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app_flutter/domain/database_initializer.dart';
import 'package:app_flutter/domain/data_sources/sqlite_data_source.dart';
import 'package:app_flutter/domain/domain_seed_strategy.dart';
import 'package:app_flutter/features/inspector/geo/geo_inspector_view_model.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('GeoInspectorViewModel', () {
    late SqliteDataSource ds;
    late GeoInspectorViewModel vm;

    Future<void> createVm() async {
      final db = await DatabaseInitializer.create(
        dbPath: inMemoryDatabasePath,
        seed: true,
        seedStrategy: DomainSeedStrategy(),
      );
      ds = SqliteDataSource(db);
      vm = GeoInspectorViewModel(ds);
      addTearDown(() async {
        await ds.dispose();
      });
    }

    test('loadNode extracts geo-location fields from data_json', () async {
      await createVm();
      await vm.loadNode('space_0');

      expect(vm.latitude, isNotNull);
      expect(vm.longitude, isNotNull);
      expect(vm.height, isNotNull);
    });

    test('isExpired returns true when validUntil is past', () async {
      await createVm();
      await vm.loadNode('space_0');

      await ds.saveProperties('space_0', {
        'geo_location_timestamp': '2024-01-01T00:00:00Z',
        'geo_location_valid_until': '2020-01-01T00:00:00Z',
      });
      await vm.loadNode('space_0');

      expect(vm.isExpired, isTrue);
    });

    test('speed is computed from vNorth/vEast', () async {
      await createVm();
      await vm.loadNode('space_0');

      await ds.saveProperties('space_0', {
        'velocity_v_north': 3.0,
        'velocity_v_east': 4.0,
      });
      await vm.loadNode('space_0');

      expect(vm.speed, closeTo(5.0, 0.01));
    });

    test('headingDegrees is 45 when vNorth=vEast=1', () async {
      await createVm();
      await vm.loadNode('space_0');

      await ds.saveProperties('space_0', {
        'velocity_v_north': 1.0,
        'velocity_v_east': 1.0,
      });
      await vm.loadNode('space_0');

      expect(vm.headingDegrees, closeTo(45.0, 0.1));
    });

    test('headingIsUndefined when both zero', () async {
      await createVm();
      await vm.loadNode('space_0');

      await ds.saveProperties('space_0', {
        'velocity_v_north': 0.0,
        'velocity_v_east': 0.0,
      });
      await vm.loadNode('space_0');

      expect(vm.headingIsUndefined, isTrue);
    });

    test('heading is 90 when vNorth=0 and vEast>0', () async {
      await createVm();
      await vm.loadNode('space_0');

      await ds.saveProperties('space_0', {
        'velocity_v_north': 0.0,
        'velocity_v_east': 5.0,
      });
      await vm.loadNode('space_0');

      expect(vm.headingDegrees, closeTo(90.0, 0.1));
    });

    test('saveField validates timestamp format', () async {
      await createVm();
      await vm.loadNode('space_0');

      final error = await vm.saveField('timestamp', 'not-a-date');
      expect(error, isNotNull);
      expect(error, contains('Invalid timestamp'));
    });

    test('saveField validates astronomical body pattern', () async {
      await createVm();
      await vm.loadNode('space_0');

      final error = await vm.saveField('astronomical_body', '\x01control');
      expect(error, isNotNull);
    });

    test('saveField validates latitude Earth range', () async {
      await createVm();
      await vm.loadNode('space_0');

      final error = await vm.saveField('latitude', '95.0');
      expect(error, isNotNull);
    });

    test('saveField accepts valid timestamp', () async {
      await createVm();
      await vm.loadNode('space_0');

      final error = await vm.saveField('timestamp', '2024-06-15T10:00:00Z');
      expect(error, isNull);
    });

    test('saveField normalizes astronomical body to lowercase', () async {
      await createVm();
      await vm.loadNode('space_0');

      await vm.saveField('astronomical_body', 'MOON');
      expect(vm.astronomicalBody, equals('moon'));
    });
  });
}
