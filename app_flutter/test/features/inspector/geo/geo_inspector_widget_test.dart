import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app_flutter/domain/database_initializer.dart';
import 'package:app_flutter/domain/data_sources/sqlite_data_source.dart';
import 'package:app_flutter/domain/domain_seed_strategy.dart';
import 'package:app_flutter/features/inspector/geo/geo_inspector.dart';
import 'package:app_flutter/features/inspector/geo/geo_inspector_view_model.dart';

Future<void> settle(WidgetTester tester) async {
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Widget wrapWithProvider(Widget child, GeoInspectorViewModel vm) {
  return MaterialApp(
    home: Scaffold(
      body: ChangeNotifierProvider<GeoInspectorViewModel>.value(
        value: vm,
        child: child,
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('GeoInspector renders all sections for node with geo data',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    late SqliteDataSource ds;
    late GeoInspectorViewModel vm;

    await tester.runAsync(() async {
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
      await vm.loadNode('space_0');
    });

    await tester.pumpWidget(wrapWithProvider(const GeoInspector(), vm));
    await settle(tester);

    // Expect section labels visible
    expect(find.text('Temporal'), findsOneWidget);
    expect(find.text('Frame of Reference'), findsOneWidget);
    expect(find.text('Geodetic System'), findsOneWidget);
    expect(find.text('Coordinates'), findsOneWidget);
    expect(find.text('Velocity'), findsOneWidget);

    // Expect latitude/longitude/height values visible in UI
    expect(find.text('Latitude'), findsOneWidget);
    expect(find.text('Longitude'), findsOneWidget);
    expect(find.text('Height'), findsOneWidget);
  });

  testWidgets('CoordinateChoiceToggle switches between ellipsoid and cartesian',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    late SqliteDataSource ds;
    late GeoInspectorViewModel vm;

    await tester.runAsync(() async {
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
      await vm.loadNode('space_0');
    });

    await tester.pumpWidget(wrapWithProvider(const GeoInspector(), vm));
    await settle(tester);

    // Initially in ellipsoid mode - ellipsoid fields visible
    expect(find.text('Latitude'), findsOneWidget);
    expect(find.text('Longitude'), findsOneWidget);

    // Tap Cartesian radio
    await tester.tap(find.text('Cartesian'));
    await settle(tester);

    // Ellipsoid fields should be hidden, Cartesian fields visible
    expect(find.text('X'), findsOneWidget);
    expect(find.text('Y'), findsOneWidget);
    expect(find.text('Z'), findsOneWidget);
  });
}
