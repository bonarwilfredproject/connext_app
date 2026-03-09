import 'package:connext_app/services/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class AttendeeController {
  static Future<void> addAttendee(int userId, int eventId) async {
    final db = await DBHelper.db();

    await db.insert("attendee", {
      "user_id": userId,
      "event_id": eventId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}
