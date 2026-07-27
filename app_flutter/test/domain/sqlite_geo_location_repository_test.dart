import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app_flutter/domain/database_initializer.dart';
import 'package:app_flutter/domain/data_sources/sqlite_geo_location_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('T7: storeGeoLocation persists and can be queried', () async {
    final db = await DatabaseInitializer.create(dbPath: inMemoryDatabasePath, seed: false);
    final repo = SqliteGeoLocationRepository(db);

    final result = await repo.storeGeoLocation(
      'geo_test_entity',
      timestamp: '2022-02-11T12:00:00Z',
      validUntil: '2022-02-12T12:00:00Z',
    );
    expect(result, isTrue);

    final location = await repo.queryGeoLocation('geo_test_entity');
    expect(location, isNotNull);
    expect(location!.entityId, equals('geo_test_entity'));
    expect(location.timestamp, equals('2022-02-11T12:00:00Z'));
    expect(location.validUntil, equals('2022-02-12T12:00:00Z'));

    await db.close();
  });

  test('T8: queryGeoLocation returns null for unknown entity', () async {
    final db = await DatabaseInitializer.create(dbPath: inMemoryDatabasePath, seed: false);
    final repo = SqliteGeoLocationRepository(db);

    final location = await repo.queryGeoLocation('nonexistent');
    expect(location, isNull);

    await db.close();
  });

  test('markAsExpired sets valid-until to epoch', () async {
    final db = await DatabaseInitializer.create(dbPath: inMemoryDatabasePath, seed: false);
    final repo = SqliteGeoLocationRepository(db);

    await repo.storeGeoLocation(
      'geo_expire_test',
      timestamp: '2022-02-11T12:00:00Z',
      validUntil: '2022-02-12T12:00:00Z',
    );

    final result = await repo.markAsExpired('geo_expire_test');
    expect(result, isTrue);

    final location = await repo.queryGeoLocation('geo_expire_test');
    expect(location, isNotNull);
    expect(location!.validUntil, equals('1970-01-01T00:00:00Z'));
    expect(location.isExpired, isTrue);

    await db.close();
  });
}
