import 'package:connext_app/services/database_helper.dart';
import 'package:connext_app/models/user_model.dart';

class UserController {
  static Future<void> registerUser(UserModel user) async {
    final dbs = await DBHelper.db();
    await dbs.insert('user', user.toMap());
  }

  static Future<void> updateProfileImage(int userId, String imagePath) async {
    final db = await DBHelper.db();

    await db.update(
      "user",
      {"profile_image": imagePath},
      where: "id = ?",
      whereArgs: [userId],
    );
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

  static Future<UserModel?> getUserById(int id) async {
    final dbs = await DBHelper.db();

    final result = await dbs.query("user", where: "id = ?", whereArgs: [id]);

    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }

    return null;
  }

  static Future<List<UserModel>> getAllUser() async {
    final dbs = await DBHelper.db();
    final List<Map<String, dynamic>> results = await dbs.query("user");
    return results.map((e) => UserModel.fromMap(e)).toList();
  }
}
