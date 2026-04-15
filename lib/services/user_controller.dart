import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connext_app/models/user_model.dart';
import 'package:connext_app/services/firebase_services.dart';

class UserController {
  static Future<void> registerUser(UserModel user) async {
    await FirebaseServices.registerUser(user: user);
  }

  static Future<bool> isPhoneExists(String phone) async {
    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();

    return result.docs.isNotEmpty;
  }

  static Future<void> updateProfile(
    int userId,
    String name,
    String phone,
  ) async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('id', whereIn: [userId, userId.toString()])
        .limit(1)
        .get();

    if (query.docs.isEmpty) return;

    await query.docs.first.reference.update({'nama': name, 'phone': phone});
  }

  static Future<void> updateProfileImage(int userId, String imagePath) async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('id', whereIn: [userId, userId.toString()])
        .limit(1)
        .get();

    if (query.docs.isEmpty) return;

    await query.docs.first.reference.update({'profile_image': imagePath});
  }

  static Future<void> updateRole(int userId, String role) async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('id', whereIn: [userId, userId.toString()])
        .limit(1)
        .get();

    if (query.docs.isEmpty) return;

    await query.docs.first.reference.update({'role': role});
  }

  static Future<UserModel?> loginUser({
    required String phone,
    required String password,
  }) async {
    return FirebaseServices.loginUser(phone: phone, password: password);
  }

  static Future<UserModel?> getUserById(int id) async {
    return FirebaseServices.getUserByNumericId(id);
  }

  static Future<List<UserModel>> getAllUser() async {
    final results = await FirebaseFirestore.instance.collection('users').get();
    return results.docs.map((e) => UserModel.fromMap(e.data())).toList();
  }
}
