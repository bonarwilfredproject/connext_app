import 'package:connext_app/database/sqflite.dart';
import 'package:connext_app/model/checkin_model.dart';

class CheckinController {
  static Future<void> insertCheckin(CheckinModel checkin) async {
    final db = await DBHelper.db();
    await db.insert('checkin', checkin.toMap());
  }

  static Future<bool> isAlreadyCheckin(int userId, int eventId) async {
    final db = await DBHelper.db();

    final result = await db.query(
      'checkin',
      where: 'user_id = ? AND event_id = ?',
      whereArgs: [userId, eventId],
    );

    return result.isNotEmpty;
  }

  static Future<List<CheckinModel>> getCheckinsByEvent(int eventId) async {
    final db = await DBHelper.db();

    final result = await db.query(
      'checkin',
      where: 'event_id = ?',
      whereArgs: [eventId],
    );

    return result.map((e) => CheckinModel.fromMap(e)).toList();
  }
}
