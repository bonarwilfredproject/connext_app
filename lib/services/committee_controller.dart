import 'package:connext_app/services/database_helper.dart';
import 'package:connext_app/models/committee_model.dart';

class CommitteeController {
  static Future<void> addCommittee(CommitteeModel committee) async {
    final db = await DBHelper.db();

    final attendee = await db.query(
      'attendee',
      where: 'user_id=? AND event_id=?',
      whereArgs: [committee.userId, committee.eventId],
    );

    if (attendee.isNotEmpty) {
      throw Exception("User sudah menjadi peserta di event ini");
    }

    await db.insert('committee', committee.toMap());
  }
}
