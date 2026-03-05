import 'package:connext_app/database/sqflite.dart';
import 'package:connext_app/model/event_model.dart';

class EventController {
  // CREATE
  static Future<void> insertEvent(EventModel event) async {
    final db = await DBHelper.db();
    await db.insert('event', event.toMap());
  }

  // READ
  static Future<List<EventModel>> getAllEvent() async {
    final db = await DBHelper.db();
    final data = await db.query('event');

    return data.map((e) => EventModel.fromMap(e)).toList();
  }

  // DELETE
  static Future<void> deleteEvent(int id) async {
    final db = await DBHelper.db();
    await db.delete('event', where: 'id = ?', whereArgs: [id]);
  }
}
