import 'package:connext_app/services/firebase_event_service.dart';
import 'package:connext_app/models/event_model.dart';

class EventController {
  /// CREATE EVENT
  static Future<void> insertEvent(EventModel event) async {
    await FirebaseEventService.insertEvent(event);
  }

  /// GET ALL EVENTS
  static Future<List<EventModel>> getAllEvent(int userId) async {
    return FirebaseEventService.getAllEvent(userId);
  }

  /// DELETE EVENT
  static Future<void> deleteEvent(int id) async {
    await FirebaseEventService.deleteEvent(id);
  }

  /// GET EVENT BY CREATOR
  static Future<List<EventModel>> getEventByUser(int userId) async {
    return FirebaseEventService.getEventByUser(userId);
  }

  /// GET EVENT BY ID
  static Future<EventModel?> getEventById(int id) async {
    return FirebaseEventService.getEventById(id);
  }

  /// GET EVENTS JOINED BY USER
  static Future<List<EventModel>> getEventByParticipant(int userId) async {
    return FirebaseEventService.getEventByParticipant(userId);
  }

  /// UPDATE EVENT
  static Future<void> updateEvent(EventModel event) async {
    await FirebaseEventService.updateEvent(event);
  }

  static Future<int> getTotalPeserta(int eventId) async {
    return FirebaseEventService.getTotalPeserta(eventId);
  }
}
