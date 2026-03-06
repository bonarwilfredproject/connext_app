import 'package:connext_app/services/database_helper.dart';
import 'package:connext_app/models/event_model.dart';

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

  static Future<void> incrementPeserta(int eventId) async {
    final db = await DBHelper.db();

    // ambil data event dulu
    final result = await db.query(
      "event",
      where: "id = ?",
      whereArgs: [eventId],
    );

    if (result.isNotEmpty) {
      int total = result.first["total_peserta"] as int;

      // tambah 1 peserta
      await db.update(
        "event",
        {"total_peserta": total + 1},
        where: "id = ?",
        whereArgs: [eventId],
      );
    }
  }

  static Future<void> updateEvent(EventModel event) async {
    final db = await DBHelper.db();

    await db.update(
      'event',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }
}
