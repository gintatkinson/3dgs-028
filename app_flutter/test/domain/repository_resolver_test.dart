import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app_flutter/domain/repository_resolver.dart';
import 'package:app_flutter/domain/database_initializer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late String dbPath;
  List<int>? mockAssetBytes;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp();
    dbPath = p.join(tempDir.path, 'properties_db.db');
    mockAssetBytes = null;

    // Mock path provider to return our temp directory
    const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationSupportDirectory') {
        return tempDir.path;
      }
      return null;
    });

    // Mock asset channel to return specified database bytes
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
      if (message == null) return null;
      final key = utf8.decode(message.buffer.asUint8List(message.offsetInBytes, message.lengthInBytes));
      if (key == 'assets/properties_db.db.gz') {
        if (mockAssetBytes != null) {
          return ByteData.sublistView(Uint8List.fromList(mockAssetBytes!));
        }
      }
      return null;
    });
  });

  tearDown(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  test('Database containing all 5 required tables is NOT considered outdated', () async {
    // 1. Create a database with the correct schema using DatabaseInitializer
    final db = await DatabaseInitializer.create(dbPath: dbPath, seed: false);
    // Add a test marker table to verify that it is NOT recreated
    await db.execute('CREATE TABLE test_marker (id TEXT PRIMARY KEY)');
    await db.close();

    // Mock the asset loading with the gzipped bytes of the database containing the test_marker
    final dbFile = File(dbPath);
    final dbBytes = await dbFile.readAsBytes();
    mockAssetBytes = gzip.encode(dbBytes);

    // 2. Resolve the repository. It should detect the database is NOT outdated and leave it intact.
    final dataSource = await RepositoryResolver.resolve(
      dataSourceType: 'sqlite',
      sqliteInMemory: false,
    );

    // 3. Open the database again and verify that the test_marker table still exists
    final checkDb = await databaseFactory.openDatabase(dbPath);
    final rows = await checkDb.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='test_marker'"
    );
    expect(rows, isNotEmpty, reason: 'test_marker table should not have been deleted');
    await checkDb.close();
  });

  test('Database missing some of the 5 required tables IS considered outdated and gets recreated', () async {
    // 1. Create a database using DatabaseInitializer
    final db = await DatabaseInitializer.create(dbPath: dbPath, seed: false);

    // Read the complete database bytes before we drop type_relations
    final dbFile = File(dbPath);
    final dbBytes = await dbFile.readAsBytes();
    mockAssetBytes = gzip.encode(dbBytes);

    // Drop 'type_relations' to make it missing one of the required tables
    await db.execute('DROP TABLE type_relations');
    // Add a test marker table to verify that the database gets deleted and recreated
    await db.execute('CREATE TABLE test_marker (id TEXT PRIMARY KEY)');
    await db.close();

    // 2. Resolve the repository. It should detect the database is outdated, delete it, and recreate it.
    final dataSource = await RepositoryResolver.resolve(
      dataSourceType: 'sqlite',
      sqliteInMemory: false,
    );

    // 3. Open the database again and verify that the test_marker table is gone
    final checkDb = await databaseFactory.openDatabase(dbPath);
    final rows = await checkDb.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='test_marker'"
    );
    expect(rows, isEmpty, reason: 'test_marker table should have been deleted because the database was recreated');
    await checkDb.close();
  });
}
