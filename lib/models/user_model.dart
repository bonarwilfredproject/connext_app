import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class UserModel {
  final int? id;
  final String nama;
  final String phone;
  final String password;
  final String? profileImage;
  UserModel({
    this.id,
    required this.nama,
    required this.phone,
    required this.password,
    this.profileImage,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'nama': nama,
      'phone': phone,
      'password': password,
      'profile_image': profileImage,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] != null ? map['id'] as int : null,
      nama: map['nama'] as String,
      phone: map['phone'] as String,
      password: map['password'] as String,
      profileImage: map['profile_image'] != null
          ? map['profile_image'] as String
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
