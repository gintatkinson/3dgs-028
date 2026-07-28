import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'lib/domain/database_initializer.dart';

Future<void> main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final db = await DatabaseInitializer.create(dbPath: inMemoryDatabasePath, seed: true);
  final res = await db.rawQuery('SELECT node_id, parent_node_id FROM properties WHERE parent_node_id IS NULL');
  print('Roots: \${res.length}');
  print(res);
}
