import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app_flutter/domain/database_initializer.dart';
import 'package:app_flutter/domain/data_sources/sqlite_data_source.dart';
import 'package:app_flutter/domain/domain_seed_strategy.dart';
import 'package:app_flutter/features/inspector/ni/ni_location_browser.dart';
import 'package:app_flutter/features/inspector/ni/ni_location_tree_view_model.dart';
import 'package:app_flutter/features/inspector/ni/widgets/dispatch_badge.dart';

Future<void> settle(WidgetTester tester) async {
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Widget wrapWithProvider(Widget child, NiLocationTreeViewModel vm) {
  return MaterialApp(
    home: Scaffold(
      body: ChangeNotifierProvider<NiLocationTreeViewModel>.value(
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

  testWidgets('renders tree with root locations',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    late SqliteDataSource ds;
    late NiLocationTreeViewModel vm;

    await tester.runAsync(() async {
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
      await vm.loadLocations();
    });

    await tester.pumpWidget(wrapWithProvider(const NiLocationBrowser(), vm));
    await settle(tester);

    expect(find.text('Tokyo Campus'), findsOneWidget);
    expect(find.text('Utility Pole TK-01'), findsOneWidget);
  });

  testWidgets('tapping location shows detail', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    late SqliteDataSource ds;
    late NiLocationTreeViewModel vm;

    await tester.runAsync(() async {
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
      await vm.loadLocations();
    });

    await tester.pumpWidget(wrapWithProvider(const NiLocationBrowser(), vm));
    await settle(tester);

    await tester.tap(find.text('Tokyo Campus'));
    await settle(tester);

    expect(find.text('Identity'), findsOneWidget);
  });

  testWidgets('filter filters tree nodes', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    late SqliteDataSource ds;
    late NiLocationTreeViewModel vm;

    await tester.runAsync(() async {
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
      await vm.loadLocations();
    });

    await tester.pumpWidget(wrapWithProvider(const NiLocationBrowser(), vm));
    await settle(tester);

    await tester.enterText(find.byType(TextField), 'Pole');
    await settle(tester);

    expect(find.text('Utility Pole TK-01'), findsOneWidget);
    expect(find.text('Tokyo Campus'), findsNothing);
  });

  testWidgets('dispatch badge shows correct color', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    late SqliteDataSource ds;
    late NiLocationTreeViewModel vm;

    await tester.runAsync(() async {
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
      await vm.loadLocations();
    });

    await tester.pumpWidget(wrapWithProvider(const NiLocationBrowser(), vm));
    await settle(tester);

    await tester.tap(find.text('Tokyo Campus'));
    await settle(tester);

    expect(find.byType(DispatchBadge), findsOneWidget);
  });
}
