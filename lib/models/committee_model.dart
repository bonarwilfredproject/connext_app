import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class CommitteeModel {
  int? id;
  int userId;
  int eventId;
  String role;
  CommitteeModel({
    this.id,
    required this.userId,
    required this.eventId,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'eventId': eventId,
      'role': role,
    };
  }

  factory CommitteeModel.fromMap(Map<String, dynamic> map) {
    return CommitteeModel(
      id: map['id'] != null ? map['id'] as int : null,
      userId: map['userId'] as int,
      eventId: map['eventId'] as int,
      role: map['role'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory CommitteeModel.fromJson(String source) =>
      CommitteeModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
