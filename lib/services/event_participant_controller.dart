import 'package:connext_app/services/firebase_event_service.dart';

class EventParticipantController {
  /// JOIN EVENT
  static Future<void> joinEvent(int userId, int eventId) async {
    await FirebaseEventService.joinEvent(userId, eventId);
  }

  /// CEK SUDAH JOIN EVENT
  static Future<bool> isJoined(int userId, int eventId) async {
    return FirebaseEventService.isJoined(userId, eventId);
  }

  /// GET QR TOKEN
  static Future<String?> getQrToken(int userId, int eventId) async {
    return FirebaseEventService.getQrToken(userId, eventId);
  }

  /// GET PARTICIPANT ID
  static Future<int?> getParticipantId(int userId, int eventId) async {
    return FirebaseEventService.getParticipantId(userId, eventId);
  }

  static Future<List<Map<String, dynamic>>> getParticipants(int eventId) async {
    return FirebaseEventService.getParticipants(eventId);
  }

  static Future<int> getTotalParticipants(int eventId) async {
    return FirebaseEventService.getTotalPeserta(eventId);
  }

  /// CANCEL JOIN EVENT
  static Future<void> cancelJoin(int userId, int eventId) async {
    await FirebaseEventService.cancelJoin(userId, eventId);
  }
}
