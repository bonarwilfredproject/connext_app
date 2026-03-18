import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Future<Database> db() async {
    final dbpath = await getDatabasesPath();

    return openDatabase(
      join(dbpath, "connext.db"),
      version: 2,
      onCreate: (db, version) async {
        /// USERS
        await db.execute('''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nama TEXT,
          phone TEXT UNIQUE,
          password TEXT,
          role TEXT,
          profile_image TEXT
        )
        ''');

        /// EVENTS
        await db.execute('''
        CREATE TABLE events(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          location TEXT,
          description TEXT,
          created_by INTEGER,
          created_at TEXT,
          event_date TEXT,
          event_time TEXT
        )
        ''');

        /// EVENT PARTICIPANTS (JOIN EVENT + QR + CHECKIN)
        await db.execute('''
        CREATE TABLE event_participants(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          event_id INTEGER,
          user_id INTEGER,
          qr_token TEXT,
          checkin_time TEXT,
          UNIQUE(event_id,user_id)
        )
        ''');

        /// EVENT UPDATES (future feature)
        await db.execute('''
        CREATE TABLE event_updates(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          event_id INTEGER,
          title TEXT,
          content TEXT,
          image TEXT,
          created_by INTEGER,
          created_at TEXT
        )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute("ALTER TABLE events ADD COLUMN event_date TEXT");
          await db.execute("ALTER TABLE events ADD COLUMN event_time TEXT");
        }
      },
    );
  }
}
