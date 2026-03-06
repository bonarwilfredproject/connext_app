import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class EventModel {
  final int? id;
  final String title;
  final String location;
  final int totalPeserta;
  final String createdBy;
  EventModel({
    this.id,
    required this.title,
    required this.location,
    required this.totalPeserta,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'location': location,
      'total_peserta': totalPeserta,
      'created_by': createdBy,
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'] != null ? map['id'] as int : null,
      title: map['title'] as String,
      location: map['location'] as String,
      totalPeserta: map['total_peserta'] as int,
      createdBy: map['created_by'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory EventModel.fromJson(String source) =>
      EventModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
