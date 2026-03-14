import 'package:shared_preferences/shared_preferences.dart';

class PreferenceHandler {
  static final PreferenceHandler _instance = PreferenceHandler._internal();
  factory PreferenceHandler() => _instance;
  PreferenceHandler._internal();

  late SharedPreferences _preferences;

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  static const String _isLogin = "isLogin";
  static const String _namaUser = "namaUser";
  static const String _role = "role";
  static const String _userId = "userId";

  Future<void> saveUser(int userId, String nama, String role) async {
    await _preferences.setInt(_userId, userId);
    await _preferences.setString(_namaUser, nama);
    await _preferences.setString(_role, role);
    await _preferences.setBool(_isLogin, true);
  }

  Future<void> saveRole(String role) async {
    await _preferences.setString(_role, role);
  }

  int getUserId() {
    return _preferences.getInt(_userId) ?? 0;
  }

  String? getNamaUser() {
    return _preferences.getString(_namaUser);
  }

  String? getRole() {
    return _preferences.getString(_role);
  }

  bool getIsLogin() {
    return _preferences.getBool(_isLogin) ?? false;
  }

  Future<void> logout() async {
    await _preferences.clear();
  }
}
