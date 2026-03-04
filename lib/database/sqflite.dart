import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Future<Database> db() async {
    final dbpath = await getDatabasesPath();
    return openDatabase(
      join(dbpath, "connext.db"),
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE user (id INTEGER PRIMARY KEY AUTOINCREMENT, nama TEXT, phone TEXT, password TEXT)',
        );
      },
      version: 2,
    );
  }
}
