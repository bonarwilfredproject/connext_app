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
  static const String _phoneAuthMappingsMigrated = "phoneAuthMappingsMigrated";

  /// SAVE USER SAAT LOGIN / REGISTER
  Future<void> saveUser(int userId, String nama, String role) async {
    await _preferences.setInt(_userId, userId);
    await _preferences.setString(_namaUser, nama);
    await _preferences.setString(_role, role);
    await _preferences.setBool(_isLogin, true);
  }

  /// UPDATE NAMA USER SAJA
  Future<void> saveNamaUser(String nama) async {
    await _preferences.setString(_namaUser, nama);
  }

  /// UPDATE ROLE
  Future<void> saveRole(String role) async {
    await _preferences.setString(_role, role);
  }

  /// GET USER ID
  int getUserId() {
    return _preferences.getInt(_userId) ?? 0;
  }

  /// GET NAMA USER
  String? getNamaUser() {
    return _preferences.getString(_namaUser);
  }

  /// GET ROLE
  String? getRole() {
    return _preferences.getString(_role);
  }

  /// CEK LOGIN
  bool getIsLogin() {
    return _preferences.getBool(_isLogin) ?? false;
  }

  bool getPhoneAuthMappingsMigrated() {
    return _preferences.getBool(_phoneAuthMappingsMigrated) ?? false;
  }

  Future<void> setPhoneAuthMappingsMigrated(bool value) async {
    await _preferences.setBool(_phoneAuthMappingsMigrated, value);
  }

  /// LOGOUT
  Future<void> logout() async {
    await _preferences.clear();
  }
}
