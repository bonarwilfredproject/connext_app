import 'package:connext_app/services/database_helper.dart';

class CheckinController {
  /// CEK SUDAH CHECKIN
  static Future<bool> isAlreadyCheckin(int participantId) async {
    final db = await DBHelper.db();

    final result = await db.query(
      "event_participants",
      where: "id = ?",
      whereArgs: [participantId],
    );

    if (result.isEmpty) return false;

    return result.first["checkin_time"] != null;
  }

  /// CHECKIN PESERTA
  static Future<void> checkinParticipant(int participantId) async {
    final db = await DBHelper.db();

    final now = DateTime.now().toIso8601String();

    await db.update(
      "event_participants",
      {"checkin_time": now},
      where: "id = ?",
      whereArgs: [participantId],
    );
  }

  /// GET PESERTA YANG SUDAH CHECKIN
  static Future<List<Map<String, dynamic>>> getCheckinByEvent(
    int eventId,
  ) async {
    final db = await DBHelper.db();

    final participants = await db.query(
      "event_participants",
      where: "event_id = ? AND checkin_time IS NOT NULL",
      whereArgs: [eventId],
    );

    List<Map<String, dynamic>> result = [];

    for (var p in participants) {
      final user = await db.query(
        "users",
        where: "id = ?",
        whereArgs: [p["user_id"]],
        limit: 1,
      );

      result.add({
        "id": p["id"].toString(),
        "userId": p["user_id"].toString(),
        "namaUser": user.isNotEmpty ? (user.first["nama"] ?? "") : "",
        "phone": user.isNotEmpty ? (user.first["phone"] ?? "") : "",
        "profileImage": user.isNotEmpty
            ? (user.first["profile_image"] ?? "")
            : "",
        "waktu": p["checkin_time"] ?? "",
      });
    }

    return result;
  }

  /// DELETE CHECKIN (reset)
  static Future<void> deleteCheckin(int participantId) async {
    final db = await DBHelper.db();

    await db.update(
      "event_participants",
      {"checkin_time": null},
      where: "id = ?",
      whereArgs: [participantId],
    );
  }

  /// CARI PARTICIPANT BERDASARKAN USER DAN EVENT
  static Future<Map<String, dynamic>?> getParticipant(
    int userId,
    int eventId,
  ) async {
    final db = await DBHelper.db();

    final result = await db.query(
      "event_participants",
      where: "user_id = ? AND event_id = ?",
      whereArgs: [userId, eventId],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return result.first;
  }

  static Future<Map<String, dynamic>?> getParticipantByToken(
    String token,
    int eventId,
  ) async {
    final db = await DBHelper.db();

    /// 1. cari participant
    final participant = await db.query(
      "event_participants",
      where: "qr_token = ? AND event_id = ?",
      whereArgs: [token, eventId],
      limit: 1,
    );

    if (participant.isEmpty) return null;

    final data = participant.first;

    /// 2. ambil nama user
    final user = await db.query(
      "users",
      where: "id = ?",
      whereArgs: [data["user_id"]],
      limit: 1,
    );

    /// gabungkan data
    return {...data, "nama": user.isNotEmpty ? user.first["nama"] : "Peserta"};
  }
}
