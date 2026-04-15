import 'package:connext_app/services/firebase_event_service.dart';

class CheckinController {
  /// CEK SUDAH CHECKIN
  static Future<bool> isAlreadyCheckin(int participantId) async {
    return FirebaseEventService.isAlreadyCheckin(participantId);
  }

  /// CHECKIN PESERTA
  static Future<void> checkinParticipant(int participantId) async {
    await FirebaseEventService.checkinParticipant(participantId);
  }

  /// GET PESERTA YANG SUDAH CHECKIN
  static Future<List<Map<String, dynamic>>> getCheckinByEvent(
    int eventId,
  ) async {
    return FirebaseEventService.getCheckinByEvent(eventId);
  }

  /// DELETE CHECKIN (reset)
  static Future<void> deleteCheckin(int participantId) async {
    await FirebaseEventService.deleteCheckin(participantId);
  }

  /// CARI PARTICIPANT BERDASARKAN USER DAN EVENT
  static Future<Map<String, dynamic>?> getParticipant(
    int userId,
    int eventId,
  ) async {
    return FirebaseEventService.getParticipant(userId, eventId);
  }

  static Future<Map<String, dynamic>?> getParticipantByToken(
    String token,
    int eventId,
  ) async {
    return FirebaseEventService.getParticipantByToken(token, eventId);
  }
}
