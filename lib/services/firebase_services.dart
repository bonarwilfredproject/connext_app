import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connext_app/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseServices {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firebaseFirestore =
      FirebaseFirestore.instance;

  static String _emailFromPhone(String phone) {
    final normalized = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return '$normalized@connext.app';
  }

  static Future<UserModel> registerUser({required UserModel user}) async {
    final email = _emailFromPhone(user.phone);
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: user.password,
    );

    final firebaseUser = cred.user!;
    await _firebaseFirestore.collection('users').doc(firebaseUser.uid).set({
      ...user.toMap(),
      'uid': firebaseUser.uid,
      'email': email,
      'created_at': FieldValue.serverTimestamp(),
    });

    return user;
  }

  static Future<bool> isPhoneExists(String phone) async {
    final query = await _firebaseFirestore
        .collection('users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  static Future<UserModel?> getCurrentUserProfile() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    final doc = await _firebaseFirestore
        .collection('users')
        .doc(firebaseUser.uid)
        .get();
    final data = doc.data();
    if (data == null) return null;

    return UserModel.fromMap({
      'id': data['id'],
      'nama': data['nama'] ?? '',
      'phone': data['phone'] ?? '',
      'password': data['password'] ?? '',
      'role': data['role'] ?? 'Attendee',
      'profile_image': data['profile_image'],
    });
  }

  static Future<void> updateProfile({
    required String name,
    required String phone,
  }) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return;

    await _firebaseFirestore.collection('users').doc(firebaseUser.uid).update({
      'nama': name,
      'phone': phone,
    });
  }

  static Future<void> updateProfileImage(String imagePath) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return;

    await _firebaseFirestore.collection('users').doc(firebaseUser.uid).update({
      'profile_image': imagePath,
    });
  }

  static Future<void> updateRole(String role) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return;

    await _firebaseFirestore.collection('users').doc(firebaseUser.uid).update({
      'role': role,
    });
  }

  static Future<UserModel?> loginUser({
    required String phone,
    required String password,
  }) async {
    final email = _emailFromPhone(phone);
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = cred.user;
    if (firebaseUser == null) return null;

    final doc = await _firebaseFirestore
        .collection('users')
        .doc(firebaseUser.uid)
        .get();
    final data = doc.data();
    if (data == null) return null;

    return UserModel.fromMap({
      'id': data['id'],
      'nama': data['nama'] ?? '',
      'phone': data['phone'] ?? phone,
      'password': data['password'] ?? password,
      'role': data['role'] ?? 'user',
      'profile_image': data['profile_image'],
    });
  }

  static Future<void> logout() async {
    await _auth.signOut();
  }
}
