import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class EventModel {
  final int? id;
  final String title;
  final String location;
  final String description;
  final int createdBy;
  final String? createdByName;
  final String? createdByUid;
  final String createdAt;
  final String? eventDate;
  final String? eventTime;

  EventModel({
    this.id,
    required this.title,
    required this.location,
    required this.description,
    required this.createdBy,
    this.createdByName,
    this.createdByUid,
    required this.createdAt,
    this.eventDate,
    this.eventTime,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'title': title,
      'location': location,
      'description': description,
      'created_by': createdBy,
      'created_at': createdAt,
      'event_date': eventDate,
      'event_time': eventTime,
    };

    final safeCreatorName = createdByName?.trim();
    if (safeCreatorName != null && safeCreatorName.isNotEmpty) {
      map['created_by_name'] = safeCreatorName;
    }

    final safeCreatorUid = createdByUid?.trim();
    if (safeCreatorUid != null && safeCreatorUid.isNotEmpty) {
      map['created_by_uid'] = safeCreatorUid;
    }

    return map;
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    final createdByRaw =
        map['created_by'] ?? map['createdBy'] ?? map['creator_id'];
    final createdByNameRaw =
        map['created_by_name'] ?? map['createdByName'] ?? map['creator_name'];
    final createdByUidRaw =
        map['created_by_uid'] ?? map['createdByUid'] ?? map['creator_uid'];

    return EventModel(
      id: map['id'] == null ? null : _toInt(map['id']),
      title: map['title'] ?? "",
      location: map['location'] ?? "",
      description: map['description'] ?? "",
      createdBy: _toInt(createdByRaw),
      createdByName: createdByNameRaw?.toString(),
      createdByUid: createdByUidRaw?.toString(),
      createdAt: map['created_at'] ?? "",
      eventDate: map['event_date'],
      eventTime: map['event_time'],
    );
  }

  String toJson() => json.encode(toMap());

  factory EventModel.fromJson(String source) =>
      EventModel.fromMap(json.decode(source));
}
