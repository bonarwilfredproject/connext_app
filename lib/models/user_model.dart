import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class UserModel {
  final int? id;
  final String nama;
  final String phone;
  final String password;
  final String role;
  final String? profileImage;

  UserModel({
    this.id,
    required this.nama,
    required this.phone,
    required this.password,
    required this.role,
    this.profileImage,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'nama': nama,
      'phone': phone,
      'password': password,
      'role': role,
      'profile_image': profileImage,
    };
  }

  static int? _toIntFlexible(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();

    final text = value.toString().trim();
    if (text.isEmpty) return null;

    final asInt = int.tryParse(text);
    if (asInt != null) return asInt;

    final asDouble = double.tryParse(text);
    if (asDouble != null) return asDouble.toInt();

    return null;
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final rawProfile = map['profile_image'] ?? map['profileImage'];

    return UserModel(
      id: _toIntFlexible(map['id']),
      nama: (map['nama'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      password: (map['password'] ?? '').toString(),
      role: (map['role'] ?? 'Attendee').toString(),
      profileImage: rawProfile?.toString(),
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
