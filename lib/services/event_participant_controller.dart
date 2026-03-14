import 'dart:math';
import 'package:connext_app/services/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class EventParticipantController {
  static String generateToken() {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    final rand = Random();

    return List.generate(
      10,
      (index) => chars[rand.nextInt(chars.length)],
    ).join();
  }

  /// JOIN EVENT
  static Future<void> joinEvent(int userId, int eventId) async {
    final db = await DBHelper.db();

    final existing = await db.query(
      "event_participants",
      where: "user_id = ? AND event_id = ?",
      whereArgs: [userId, eventId],
    );

    if (existing.isNotEmpty) return;

    final token = generateToken();

    await db.insert("event_participants", {
      "user_id": userId,
      "event_id": eventId,
      "qr_token": token,
      "checkin_time": null,
    });
  }

  /// CEK SUDAH JOIN EVENT
  static Future<bool> isJoined(int userId, int eventId) async {
    final db = await DBHelper.db();

    final result = await db.query(
      "event_participants",
      where: "user_id = ? AND event_id = ?",
      whereArgs: [userId, eventId],
    );

    return result.isNotEmpty;
  }

  /// GET QR TOKEN
  static Future<String?> getQrToken(int userId, int eventId) async {
    final db = await DBHelper.db();

    final data = await db.query(
      "event_participants",
      where: "user_id = ? AND event_id = ?",
      whereArgs: [userId, eventId],
      limit: 1,
    );

    if (data.isNotEmpty) {
      return data.first["qr_token"] as String;
    }

    return null;
  }

  /// GET PARTICIPANT ID
  static Future<int?> getParticipantId(int userId, int eventId) async {
    final db = await DBHelper.db();

    final data = await db.query(
      "event_participants",
      where: "user_id = ? AND event_id = ?",
      whereArgs: [userId, eventId],
      limit: 1,
    );

    if (data.isNotEmpty) {
      return data.first["id"] as int;
    }

    return null;
  }

  static Future<List<Map<String, dynamic>>> getParticipants(int eventId) async {
    final db = await DBHelper.db();

    /// ambil semua peserta event
    final participantData = await db.query(
      "event_participants",
      where: "event_id = ?",
      whereArgs: [eventId],
    );

    List<Map<String, dynamic>> participants = [];

    for (var p in participantData) {
      /// ambil data user
      final userData = await db.query(
        "users",
        where: "id = ?",
        whereArgs: [p["user_id"]],
        limit: 1,
      );

      if (userData.isNotEmpty) {
        bool isCheckedIn = p["checkin_time"] != null;

        participants.add({
          "name": userData.first["nama"],
          "phone": userData.first["phone"],
          "profileImage": userData.first["profile_image"],
          "isCheckedIn": isCheckedIn,
        });
      }
    }

    return participants;
  }

  static Future<int> getTotalParticipants(int eventId) async {
    final db = await DBHelper.db();

    final result = await db.query(
      "event_participants",
      where: "event_id = ?",
      whereArgs: [eventId],
    );

    return result.length;
  }

  /// CANCEL JOIN EVENT
  static Future<void> cancelJoin(int userId, int eventId) async {
    final db = await DBHelper.db();

    await db.delete(
      "event_participants",
      where: "user_id = ? AND event_id = ?",
      whereArgs: [userId, eventId],
    );
  }
}
