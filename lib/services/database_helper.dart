import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Future<Database> db() async {
    final dbpath = await getDatabasesPath();
    return openDatabase(
      join(dbpath, "connext.db"),
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE user(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nama TEXT,
          phone TEXT UNIQUE,
          password TEXT,
          profile_image TEXT
        )
        ''');
        await db.execute('''
        CREATE TABLE event(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          location TEXT,
          total_peserta INTEGER,
          created_by TEXT,
          user_id INTEGER
        )
        ''');
        await db.execute('''
        CREATE TABLE attendee(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER,
          event_id INTEGER,
          UNIQUE(user_id,event_id)
        )
        ''');
        await db.execute('''
        CREATE TABLE committee(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER,
          event_id INTEGER,
          role TEXT,
          UNIQUE(user_id,event_id)
        )
        ''');
        await db.execute('''
        CREATE TABLE checkin(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER,
          event_id INTEGER,
          waktu TEXT,
          nama_user TEXT,
          phone TEXT,
          UNIQUE(user_id,event_id)
        )
        ''');
      },
      version: 5,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
        CREATE TABLE event (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          location TEXT,
          total_peserta INTEGER,
          created_by TEXT,
          user_id INTEGER
        )
      ''');
        }
        if (oldVersion < 4) {
          await db.execute('''
  CREATE TABLE checkin (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    event_id INTEGER,
    waktu TEXT
  )
  ''');
        }
      },
    );
  }
}
