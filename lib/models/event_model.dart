import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class EventModel {
  final int? id;
  final String title;
  final String location;
  final String description;
  final int createdBy;
  final String createdAt;
  final String? eventDate;
  final String? eventTime;

  EventModel({
    this.id,
    required this.title,
    required this.location,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    this.eventDate,
    this.eventTime,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'location': location,
      'description': description,
      'created_by': createdBy,
      'created_at': createdAt,
      'event_date': eventDate,
      'event_time': eventTime,
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'] != null ? map['id'] as int : null,
      title: map['title'] ?? "",
      location: map['location'] ?? "",
      description: map['description'] ?? "",
      createdBy: map['created_by'] ?? 0,
      createdAt: map['created_at'] ?? "",
      eventDate: map['event_date'],
      eventTime: map['event_time'],
    );
  }

  String toJson() => json.encode(toMap());

  factory EventModel.fromJson(String source) =>
      EventModel.fromMap(json.decode(source));
}
