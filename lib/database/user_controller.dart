import 'package:connext_app/database/sqflite.dart';
import 'package:connext_app/model/user_model.dart';

class UserController {
  static Future<void> registerUser(UserModel user) async {
    final dbs = await DBHelper.db();
    await dbs.insert('user', user.toMap());
  }

  static Future<UserModel?> loginUser({
    required String phone,
    required String password,
  }) async {
    final dbs = await DBHelper.db();
    final List<Map<String, dynamic>> results = await dbs.query(
      "user",
      where: 'phone = ? AND password = ?',
      whereArgs: [phone, password],
    );
    if (results.isNotEmpty) {
      return UserModel.fromMap(results.first);
    }
    return null;
  }

  static Future<List<UserModel>> getAllUser() async {
    final dbs = await DBHelper.db();
    final List<Map<String, dynamic>> results = await dbs.query("user");
    return results.map((e) => UserModel.fromMap(e)).toList();
  }
}
