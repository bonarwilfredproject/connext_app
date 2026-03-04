import 'package:shared_preferences/shared_preferences.dart';

class PreferenceHandler {
  //Inisialisasi Shared Preference
  static final PreferenceHandler _instance = PreferenceHandler._internal();
  late SharedPreferences _preferences;
  factory PreferenceHandler() => _instance;
  PreferenceHandler._internal();

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  static const String _isLogin = "isLogin";
  static const String _isAttendee = "isAttendee";
  static const String _isCommittee = "isCommittee";
  static const String _namaUser = "namaUser";
  static const String _role = "role";

  Future<void> logout() async {
    await _preferences.clear();
  }

  Future<void> saveUser(String nama, String role) async {
    await _preferences.setString(_namaUser, nama);
    await _preferences.setString(_role, role);
  }

  Future<String?> getNamaUser() async {
    return _preferences.getString(_namaUser);
  }

  Future<String?> getRole() async {
    return _preferences.getString(_role);
  }

  Future<void> storingIsLogin(bool isLogin) async {
    _preferences.setBool(_isLogin, isLogin);
  }

  Future<void> storingIsAttendee(bool isAttendee) async {
    _preferences.setBool(_isAttendee, isAttendee);
  }

  Future<bool?> getIsAttendee() async {
    return _preferences.getBool(_isAttendee);
  }

  Future<void> storingIsCommittee(bool isCommittee) async {
    _preferences.setBool(_isCommittee, isCommittee);
  }

  Future<bool?> getIsCommittee() async {
    return _preferences.getBool(_isCommittee);
  }

  Future<bool?> getIsLogin() async {
    return _preferences.getBool(_isLogin);
  }

  Future<void> deleteIsLogin() async {
    _preferences.remove(_isLogin);
  }
}
