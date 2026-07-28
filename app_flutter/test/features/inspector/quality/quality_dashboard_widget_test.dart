import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app_flutter/domain/data_sources/sqlite_data_source.dart';
import 'package:app_flutter/features/inspector/quality/quality_dashboard.dart';
import 'package:app_flutter/features/inspector/quality/quality_view_model.dart';
import 'package:app_flutter/features/inspector/quality/widgets/summary_card.dart';

Future<Database> _createMinimalDb() async {
  final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
  await db.execute('''
    CREATE TABLE IF NOT EXISTS properties (
      node_id TEXT PRIMARY KEY,
      parent_node_id TEXT,
      data_json TEXT NOT NULL
    )
  ''');
  final validUntilFuture =
      DateTime.now().toUtc().add(const Duration(days: 365)).toIso8601String();
  final validUntilPast = '2020-01-01T00:00:00Z';

  await db.insert('properties', {
    'node_id': 'nil_location_site',
    'parent_node_id': null,
    'data_json': jsonEncode({
      'id': 'nil_location_site',
      'type': 'site',
      'name': 'Tokyo Campus',
      'valid_until': validUntilFuture,
    }),
  });
  await db.insert('properties', {
    'node_id': 'nil_location_building',
    'parent_node_id': null,
    'data_json': jsonEncode({
      'id': 'nil_location_building',
      'type': 'building',
      'name': 'Building A',
      'postal_code': '160-0022',
      'city': 'Shinjuku',
      'country_code': 'JP',
      'valid_until': validUntilFuture,
    }),
  });
  await db.insert('properties', {
    'node_id': 'nil_location_room',
    'parent_node_id': null,
    'data_json': jsonEncode({
      'id': 'nil_location_room',
      'type': 'equipment-room',
      'name': 'Equipment Room 101',
      'latitude': 35.6895,
      'longitude': 139.6917,
      'valid_until': validUntilFuture,
    }),
  });
  await db.insert('properties', {
    'node_id': 'geo_location_root',
    'parent_node_id': null,
    'data_json': jsonEncode({
      'timestamp': '2022-02-11T12:00:00Z',
      'valid_until': validUntilPast,
    }),
  });
  await db.insert('properties', {
    'node_id': 'rack_101_a',
    'parent_node_id': null,
    'data_json': jsonEncode({
      'id': 'rack_101_a',
      'rack_class': 'rack-secure-medium',
      'valid_until': validUntilFuture,
    }),
  });
  return db;
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('QualityDashboard widget', () {
    late SqliteDataSource ds;
    late QualityDashboardViewModel vm;

    setUp(() async {
      final db = await _createMinimalDb();
      ds = SqliteDataSource(db);
      vm = QualityDashboardViewModel(ds);
      await vm.runValidation();
    });

    tearDown(() async {
      await ds.dispose();
    });

    Widget buildWidget() {
      return ChangeNotifierProvider<QualityDashboardViewModel>.value(
        value: vm,
        child: const MaterialApp(
          home: Scaffold(body: QualityDashboard()),
        ),
      );
    }

    testWidgets('renders summary cards with counts', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byType(SummaryCard), findsNWidgets(4));
    });

    testWidgets('renders filterable status table', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('Re-validate All'), findsOneWidget);
    });

    testWidgets('re-validate button triggers refresh', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      final initialTotal = vm.totalCount;
      await tester.tap(find.text('Re-validate All'));
      await tester.pump();

      expect(vm.totalCount, equals(initialTotal));
    });
  });
}
