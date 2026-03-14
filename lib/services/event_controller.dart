import 'package:connext_app/services/database_helper.dart';
import 'package:connext_app/models/event_model.dart';

class EventController {
  /// CREATE EVENT
  static Future<void> insertEvent(EventModel event) async {
    final db = await DBHelper.db();

    await db.insert('events', event.toMap());
  }

  /// GET ALL EVENTS
  static Future<List<EventModel>> getAllEvent(int userId) async {
    final db = await DBHelper.db();

    final data = await db.query(
      'events',
      where: 'created_by != ?',
      whereArgs: [userId],
    );

    return data.map((e) => EventModel.fromMap(e)).toList();
  }

  /// DELETE EVENT
  static Future<void> deleteEvent(int id) async {
    final db = await DBHelper.db();

    await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  /// GET EVENT BY CREATOR
  static Future<List<EventModel>> getEventByUser(int userId) async {
    final db = await DBHelper.db();

    final data = await db.query(
      'events',
      where: 'created_by = ?',
      whereArgs: [userId],
    );

    return data.map((e) => EventModel.fromMap(e)).toList();
  }

  /// GET EVENT BY ID
  static Future<EventModel?> getEventById(int id) async {
    final db = await DBHelper.db();

    final result = await db.query(
      "events",
      where: "id = ?",
      whereArgs: [id],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return EventModel.fromMap(result.first);
    }

    return null;
  }

  /// GET EVENTS JOINED BY USER
  static Future<List<EventModel>> getEventByParticipant(int userId) async {
    final db = await DBHelper.db();

    // ambil semua event_id dari tabel event_participants
    final participantData = await db.query(
      "event_participants",
      where: "user_id = ?",
      whereArgs: [userId],
    );

    List<EventModel> events = [];

    for (var p in participantData) {
      final eventData = await db.query(
        "events",
        where: "id = ?",
        whereArgs: [p["event_id"]],
      );

      if (eventData.isNotEmpty) {
        events.add(EventModel.fromMap(eventData.first));
      }
    }

    return events;
  }

  /// UPDATE EVENT
  static Future<void> updateEvent(EventModel event) async {
    final db = await DBHelper.db();

    await db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  static Future<int> getTotalPeserta(int eventId) async {
    final db = await DBHelper.db();

    final result = await db.query(
      "event_participants",
      where: "event_id = ?",
      whereArgs: [eventId],
    );

    return result.length;
  }
}
