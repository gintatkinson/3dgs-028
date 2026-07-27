import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app_flutter/domain/database_initializer.dart';
import 'package:app_flutter/domain/data_sources/sqlite_data_source.dart';
import 'package:app_flutter/domain/domain_seed_strategy.dart';
import 'package:app_flutter/features/properties/view_models/properties_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('T10: saveProperties validates timestamp format and rejects invalid input', () async {
    final db = await DatabaseInitializer.create(
      dbPath: inMemoryDatabasePath,
      seed: true,
      seedStrategy: DomainSeedStrategy(),
    );
    final dataSource = SqliteDataSource(db);
    final viewModel = PropertiesViewModel(dataSource);

    await viewModel.loadType('GeoLocation');
    expect(viewModel.hasType, isTrue);

    final error = await viewModel.saveProperties(
      'geo_test_node',
      {
        'timestamp': 'not-a-date',
        'valid_until': '2022-02-12T12:00:00Z',
      },
    );
    expect(error, isNotNull);
    expect(error, contains('Invalid'));

    await db.close();
  });

  test('saveProperties accepts valid timestamp for GeoLocation', () async {
    final db = await DatabaseInitializer.create(
      dbPath: inMemoryDatabasePath,
      seed: true,
      seedStrategy: DomainSeedStrategy(),
    );
    final dataSource = SqliteDataSource(db);
    final viewModel = PropertiesViewModel(dataSource);

    await viewModel.loadType('GeoLocation');
    expect(viewModel.hasType, isTrue);

    final error = await viewModel.saveProperties(
      'geo_test_valid',
      {
        'timestamp': '2022-02-11T12:00:00Z',
        'valid_until': '2022-02-12T12:00:00Z',
      },
    );
    expect(error, isNull);

    final saved = await dataSource.fetchProperties('geo_test_valid');
    expect(saved['timestamp'], equals('2022-02-11T12:00:00Z'));

    await db.close();
  });

  test('saveProperties validates astronomical_body and rejects control characters', () async {
    final db = await DatabaseInitializer.create(
      dbPath: inMemoryDatabasePath,
      seed: true,
      seedStrategy: DomainSeedStrategy(),
    );
    final dataSource = SqliteDataSource(db);
    final viewModel = PropertiesViewModel(dataSource);

    await viewModel.loadType('ReferenceFrame');
    expect(viewModel.hasType, isTrue);

    final error = await viewModel.saveProperties(
      'ref_frame_test',
      {
        'astronomical_body': 'test\x00name',
      },
    );
    expect(error, isNotNull);
    expect(error, contains('Invalid'));

    await db.close();
  });

  test('saveProperties normalizes astronomical_body to lowercase', () async {
    final db = await DatabaseInitializer.create(
      dbPath: inMemoryDatabasePath,
      seed: true,
      seedStrategy: DomainSeedStrategy(),
    );
    final dataSource = SqliteDataSource(db);
    final viewModel = PropertiesViewModel(dataSource);

    await viewModel.loadType('ReferenceFrame');
    expect(viewModel.hasType, isTrue);

    final error = await viewModel.saveProperties(
      'ref_frame_norm',
      {
        'astronomical_body': 'EARTH',
      },
    );
    expect(error, isNull);

    final saved = await dataSource.fetchProperties('ref_frame_norm');
    expect(saved['astronomical_body'], equals('earth'));

    await db.close();
  });

  test('saveProperties accepts valid astronomical_body like "67p/churyumov-gerasimenko"', () async {
    final db = await DatabaseInitializer.create(
      dbPath: inMemoryDatabasePath,
      seed: true,
      seedStrategy: DomainSeedStrategy(),
    );
    final dataSource = SqliteDataSource(db);
    final viewModel = PropertiesViewModel(dataSource);

    await viewModel.loadType('ReferenceFrame');
    expect(viewModel.hasType, isTrue);

    final error = await viewModel.saveProperties(
      'ref_frame_comet',
      {
        'astronomical_body': '67p/churyumov-gerasimenko',
      },
    );
    expect(error, isNull);

    final saved = await dataSource.fetchProperties('ref_frame_comet');
    expect(saved['astronomical_body'], equals('67p/churyumov-gerasimenko'));

    await db.close();
  });

  test('saveProperties skips validation for non-GeoLocation types', () async {
    final db = await DatabaseInitializer.create(
      dbPath: inMemoryDatabasePath,
      seed: true,
      seedStrategy: DomainSeedStrategy(),
    );
    final dataSource = SqliteDataSource(db);
    final viewModel = PropertiesViewModel(dataSource);

    await viewModel.loadType('Components');
    expect(viewModel.hasType, isTrue);

    final error = await viewModel.saveProperties(
      'comp_test',
      {
        'field_1': 'some_value',
      },
    );
    expect(error, isNull);

    await db.close();
  });
}
