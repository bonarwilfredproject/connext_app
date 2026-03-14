class EventParticipantModel {
  final int? id;
  final int userId;
  final int eventId;
  final String qrToken;
  final String? checkinTime;

  EventParticipantModel({
    this.id,
    required this.userId,
    required this.eventId,
    required this.qrToken,
    this.checkinTime,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "user_id": userId,
      "event_id": eventId,
      "qr_token": qrToken,
      "checkin_time": checkinTime,
    };
  }

  factory EventParticipantModel.fromMap(Map<String, dynamic> map) {
    return EventParticipantModel(
      id: map["id"],
      userId: map["user_id"],
      eventId: map["event_id"],
      qrToken: map["qr_token"],
      checkinTime: map["checkin_time"],
    );
  }
}
