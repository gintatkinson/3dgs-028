import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app_flutter/domain/database_initializer.dart';
import 'package:app_flutter/domain/data_sources/sqlite_data_source.dart';
import 'package:app_flutter/domain/domain_seed_strategy.dart';
import 'package:app_flutter/features/inspector/racks/rack_inventory_panel.dart';
import 'package:app_flutter/features/inspector/racks/rack_table_view_model.dart';
import 'package:app_flutter/features/inspector/racks/widgets/capacity_gauge.dart';

Future<void> settle(WidgetTester tester) async {
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Widget wrapWithProvider(Widget child, RackTableViewModel vm) {
  return MaterialApp(
    home: Scaffold(
      body: ChangeNotifierProvider<RackTableViewModel>.value(
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

  testWidgets('renders rack table with 2 rows',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    late SqliteDataSource ds;
    late RackTableViewModel vm;

    await tester.runAsync(() async {
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
      await vm.loadRacks();
    });

    await tester.pumpWidget(wrapWithProvider(const RackInventoryPanel(), vm));
    await settle(tester);

    expect(find.text('rack_101_a'), findsOneWidget);
    expect(find.text('rack_201_b'), findsOneWidget);
  });

  testWidgets('clicking row selects rack and shows detail',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    late SqliteDataSource ds;
    late RackTableViewModel vm;

    await tester.runAsync(() async {
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
      await vm.loadRacks();
    });

    await tester.pumpWidget(wrapWithProvider(const RackInventoryPanel(), vm));
    await settle(tester);

    await tester.tap(find.text('rack_101_a'));
    await settle(tester);

    expect(find.text('Identity'), findsOneWidget);
    expect(find.text('Dimensions'), findsOneWidget);
    expect(find.text('Power'), findsOneWidget);
  });

  testWidgets('capacity gauge shows utilization when rack is selected',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    late SqliteDataSource ds;
    late RackTableViewModel vm;

    await tester.runAsync(() async {
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
      await vm.loadRacks();
    });

    await tester.pumpWidget(wrapWithProvider(const RackInventoryPanel(), vm));
    await settle(tester);

    await tester.tap(find.text('rack_101_a'));
    await settle(tester);

    expect(find.byType(CapacityGauge), findsWidgets);
    expect(find.textContaining('0W / 8000W'), findsWidgets);
  });

  testWidgets('shows select placeholder when no rack selected',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    late SqliteDataSource ds;
    late RackTableViewModel vm;

    await tester.runAsync(() async {
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
      await vm.loadRacks();
    });

    await tester.pumpWidget(wrapWithProvider(const RackInventoryPanel(), vm));
    await settle(tester);

    expect(find.text('Select a rack to view details'), findsOneWidget);
  });

  testWidgets('filter input filters racks', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    late SqliteDataSource ds;
    late RackTableViewModel vm;

    await tester.runAsync(() async {
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
      await vm.loadRacks();
    });

    await tester.pumpWidget(wrapWithProvider(const RackInventoryPanel(), vm));
    await settle(tester);

    final filterField = find.byType(TextField);
    expect(filterField, findsOneWidget);

    await tester.enterText(filterField, '101');
    await settle(tester);

    expect(find.text('rack_101_a'), findsOneWidget);
    expect(find.text('rack_201_b'), findsNothing);
  });
}
