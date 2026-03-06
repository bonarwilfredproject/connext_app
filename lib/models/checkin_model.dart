import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class CheckinModel {
  final int? id;
  final int userId;
  final int eventId;
  final String waktu;
  CheckinModel({
    this.id,
    required this.userId,
    required this.eventId,
    required this.waktu,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'event_id': eventId,
      'waktu': waktu,
    };
  }

  factory CheckinModel.fromMap(Map<String, dynamic> map) {
    return CheckinModel(
      id: map['id'] != null ? map['id'] as int : null,
      userId: map['user_id'] as int,
      eventId: map['event_id'] as int,
      waktu: map['waktu'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory CheckinModel.fromJson(String source) =>
      CheckinModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
