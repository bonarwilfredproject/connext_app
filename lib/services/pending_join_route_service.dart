import 'package:connext_app/models/event_model.dart';
import 'package:connext_app/services/event_controller.dart';
import 'package:connext_app/services/event_participant_controller.dart';

enum PendingJoinRouteTarget { invitation, attendee }

class PendingJoinRouteDecision {
  final PendingJoinRouteTarget target;

  const PendingJoinRouteDecision(this.target);

  bool get openAttendee => target == PendingJoinRouteTarget.attendee;
}

class PendingJoinRouteService {
  static Future<PendingJoinRouteDecision> resolve({
    required int userId,
    required String userRole,
    required int eventId,
  }) async {
    if (eventId <= 0 || userId <= 0) {
      return const PendingJoinRouteDecision(PendingJoinRouteTarget.invitation);
    }

    final event = await EventController.getEventById(eventId);
    if (event == null) {
      return const PendingJoinRouteDecision(PendingJoinRouteTarget.invitation);
    }

    // Event owner should never be routed into attendee detail.
    if (event.createdBy == userId) {
      return const PendingJoinRouteDecision(PendingJoinRouteTarget.invitation);
    }

    final alreadyJoined = await EventParticipantController.isJoined(
      userId,
      eventId,
    );

    if (!alreadyJoined) {
      return const PendingJoinRouteDecision(PendingJoinRouteTarget.invitation);
    }

    if (_isEventExpired(event)) {
      return const PendingJoinRouteDecision(PendingJoinRouteTarget.invitation);
    }

    return const PendingJoinRouteDecision(PendingJoinRouteTarget.attendee);
  }

  static bool _isEventExpired(EventModel event) {
    final rawDate = event.eventDate?.trim() ?? '';
    if (rawDate.isEmpty) return false;

    final datePart = DateTime.tryParse(rawDate);
    if (datePart == null) return false;

    final rawTime = event.eventTime?.trim() ?? '';
    final timeSegments = rawTime.split(':');
    final hour = rawTime.isEmpty ? 0 : int.tryParse(timeSegments.first) ?? 0;
    final minute = rawTime.isEmpty
        ? 0
        : (timeSegments.length > 1 ? int.tryParse(timeSegments[1]) ?? 0 : 0);

    final eventDateTime = DateTime(
      datePart.year,
      datePart.month,
      datePart.day,
      hour,
      minute,
    );

    return eventDateTime.isBefore(DateTime.now());
  }
}
