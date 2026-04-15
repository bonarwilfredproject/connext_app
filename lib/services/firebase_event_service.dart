import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connext_app/models/event_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseEventService {
  static final FirebaseFirestore _firebaseFirestore =
      FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> get _eventsCollection =>
      _firebaseFirestore.collection('events');

  static CollectionReference<Map<String, dynamic>> _participantsCollection(
    int eventId,
  ) {
    return _eventsCollection.doc(eventId.toString()).collection('participants');
  }

  static CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firebaseFirestore.collection('users');

  static DocumentReference<Map<String, dynamic>> get _counterDoc =>
      _firebaseFirestore.collection('metadata').doc('counters');

  static Future<int> _nextCounter(String field) async {
    return _firebaseFirestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(_counterDoc);
      final current = (snapshot.data()?[field] as num?)?.toInt() ?? 0;
      final nextValue = current + 1;

      transaction.set(_counterDoc, {field: nextValue}, SetOptions(merge: true));

      return nextValue;
    });
  }

  static Future<int> _nextEventId() => _nextCounter('event_id');

  static Future<int> _nextParticipantId() => _nextCounter('participant_id');

  static int? _toIntFlexible(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();

    final text = raw.toString().trim();
    if (text.isEmpty) return null;

    final asInt = int.tryParse(text);
    if (asInt != null) return asInt;

    final asDouble = double.tryParse(text);
    if (asDouble != null) return asDouble.toInt();

    return null;
  }

  static Future<Set<String>> _ownerUidsByNumericId(int userId) async {
    final uids = <String>{};

    final currentUid = _auth.currentUser?.uid;
    if (currentUid != null && currentUid.isNotEmpty) {
      uids.add(currentUid);

      try {
        final ownDoc = await _usersCollection.doc(currentUid).get();
        final ownData = ownDoc.data();
        final ownUidFromField = ownData?['uid']?.toString();
        if (ownUidFromField != null && ownUidFromField.isNotEmpty) {
          uids.add(ownUidFromField);
        }
      } catch (_) {
        // Ignore and continue with known current UID.
      }

      return uids;
    }

    try {
      final numericQuery = await _usersCollection
          .where('id', isEqualTo: userId)
          .limit(1)
          .get();
      final stringQuery = await _usersCollection
          .where('id', isEqualTo: userId.toString())
          .limit(1)
          .get();

      for (final doc in [...numericQuery.docs, ...stringQuery.docs]) {
        final data = doc.data();
        final uidFromField = data['uid']?.toString();
        if (uidFromField != null && uidFromField.isNotEmpty) {
          uids.add(uidFromField);
        }
        if (doc.id.isNotEmpty) {
          uids.add(doc.id);
        }
      }
    } catch (_) {
      // Ignore and return whatever we could resolve.
    }

    return uids;
  }

  static bool _isCreatedByUser(
    Map<String, dynamic> map,
    int userId,
    Set<String> ownerUids,
  ) {
    final creatorCandidates = [
      map['created_by'],
      map['createdBy'],
      map['creator_id'],
      map['created_by_uid'],
      map['creator_uid'],
    ];

    for (final raw in creatorCandidates) {
      final parsedId = _toIntFlexible(raw);
      if (parsedId != null && parsedId == userId) {
        return true;
      }

      final rawText = raw?.toString().trim();
      if (rawText == null || rawText.isEmpty) continue;

      if (ownerUids.contains(rawText)) {
        return true;
      }
    }

    final creatorUid = (map['created_by_uid'] ?? map['creator_uid'])
        ?.toString()
        .trim();
    final currentUid = _auth.currentUser?.uid;
    if (creatorUid != null && creatorUid.isNotEmpty) {
      if (ownerUids.contains(creatorUid)) {
        return true;
      }
      if (currentUid != null &&
          currentUid.isNotEmpty &&
          creatorUid == currentUid) {
        return true;
      }
    }

    return false;
  }

  static Future<Map<String, dynamic>?> _getUserByNumericId(int userId) async {
    final query = await _usersCollection
        .where('id', isEqualTo: userId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) return query.docs.first.data();

    // Legacy fallback: some datasets store the numeric id as a string.
    final stringQuery = await _usersCollection
        .where('id', isEqualTo: userId.toString())
        .limit(1)
        .get();

    if (stringQuery.docs.isEmpty) return null;
    return stringQuery.docs.first.data();
  }

  static String? _profileImageFromUserMap(Map<String, dynamic>? userData) {
    if (userData == null) return null;
    final image = userData['profile_image'] ?? userData['profileImage'];
    return image?.toString();
  }

  static Future<EventModel> insertEvent(EventModel event) async {
    final eventId = await _nextEventId();
    final currentUid = _auth.currentUser?.uid;

    String? creatorName = event.createdByName?.trim();
    String? creatorUid = event.createdByUid?.trim();
    String? creatorRole;

    final userData = await _getUserByNumericId(event.createdBy);
    creatorName ??= userData?['nama']?.toString();
    creatorUid ??= userData?['uid']?.toString();
    creatorRole ??= userData?['role']?.toString();

    if ((creatorName == null || creatorName.isEmpty) &&
        currentUid != null &&
        currentUid.isNotEmpty) {
      final currentDoc = await _usersCollection.doc(currentUid).get();
      final currentData = currentDoc.data();
      creatorName ??= currentData?['nama']?.toString();
      creatorUid ??= currentData?['uid']?.toString();
      creatorRole ??= currentData?['role']?.toString();
    }

    creatorUid ??= currentUid;
    creatorRole = (creatorRole == null || creatorRole.isEmpty)
        ? 'Committee'
        : creatorRole;

    final payload = event.toMap()
      ..['id'] = eventId
      ..['created_by'] = event.createdBy
      ..['created_by_name'] = creatorName ?? ''
      ..['created_by_uid'] = creatorUid ?? ''
      ..['created_by_role'] = creatorRole;

    await _eventsCollection.doc(eventId.toString()).set(payload);

    return EventModel.fromMap(payload);
  }

  static Future<List<EventModel>> getAllEvent(int userId) async {
    final snapshot = await _eventsCollection.get();
    final ownerUids = await _ownerUidsByNumericId(userId);

    final events = <EventModel>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();

      if (_isCreatedByUser(data, userId, ownerUids)) {
        continue;
      }
      events.add(EventModel.fromMap(data));
    }

    return events;
  }

  static Future<void> deleteEvent(int id) async {
    Future<void> deleteByDocRef(
      DocumentReference<Map<String, dynamic>> doc,
    ) async {
      final participants = await doc.collection('participants').get();

      for (final participant in participants.docs) {
        await participant.reference.delete();
      }

      await doc.delete();
    }

    final directDoc = await _eventsCollection.doc(id.toString()).get();
    if (directDoc.exists) {
      await deleteByDocRef(directDoc.reference);
      return;
    }

    final fallback = await _eventsCollection
        .where('id', isEqualTo: id)
        .limit(1)
        .get();

    if (fallback.docs.isNotEmpty) {
      await deleteByDocRef(fallback.docs.first.reference);
    }
  }

  static Future<List<EventModel>> getEventByUser(int userId) async {
    final snapshot = await _eventsCollection.get();
    final ownerUids = await _ownerUidsByNumericId(userId);

    final events = <EventModel>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (_isCreatedByUser(data, userId, ownerUids)) {
        events.add(EventModel.fromMap(data));
      }
    }

    return events;
  }

  static Future<EventModel?> getEventById(int id) async {
    final doc = await _eventsCollection.doc(id.toString()).get();
    if (doc.exists && doc.data() != null) {
      return EventModel.fromMap(doc.data()!);
    }

    final fallback = await _eventsCollection
        .where('id', isEqualTo: id)
        .limit(1)
        .get();
    if (fallback.docs.isNotEmpty) {
      return EventModel.fromMap(fallback.docs.first.data());
    }

    return null;
  }

  static Future<List<EventModel>> getEventByParticipant(int userId) async {
    QuerySnapshot<Map<String, dynamic>> participantDocs =
        await _firebaseFirestore
            .collectionGroup('participants')
            .where('user_id', isEqualTo: userId)
            .get();

    if (participantDocs.docs.isEmpty) {
      final uid = _auth.currentUser?.uid;
      if (uid != null && uid.isNotEmpty) {
        participantDocs = await _firebaseFirestore
            .collectionGroup('participants')
            .where('user_uid', isEqualTo: uid)
            .get();
      }
    }

    final events = <EventModel>[];
    final seenIds = <int>{};

    for (final participant in participantDocs.docs) {
      final eventId = (participant.data()['event_id'] as num?)?.toInt();
      if (eventId == null || seenIds.contains(eventId)) continue;

      final event = await getEventById(eventId);
      if (event != null) {
        seenIds.add(eventId);
        events.add(event);
      }
    }

    return events;
  }

  static Future<void> updateEvent(EventModel event) async {
    if (event.id == null) return;

    await _eventsCollection
        .doc(event.id.toString())
        .set(event.toMap(), SetOptions(merge: true));
  }

  static Future<int> getTotalPeserta(int eventId) async {
    final snapshot = await _participantsCollection(eventId).get();
    return snapshot.docs.length;
  }

  static Future<void> joinEvent(int userId, int eventId) async {
    final existing = await _participantDocsByUser(eventId, userId);

    if (existing.docs.isNotEmpty) return;

    final participantId = await _nextParticipantId();
    final token = _generateToken();
    final uid = _auth.currentUser?.uid;
    final payload = {
      'id': participantId,
      'user_id': userId,
      'user_uid': uid,
      'event_id': eventId,
      'qr_token': token,
      'checkin_time': null,
    };

    await _participantsCollection(
      eventId,
    ).doc(participantId.toString()).set(payload);
  }

  static String _generateToken() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final seed = DateTime.now().microsecondsSinceEpoch;

    return List.generate(10, (index) {
      final charIndex = (seed + index) % chars.length;
      return chars[charIndex];
    }).join();
  }

  static Future<bool> isJoined(int userId, int eventId) async {
    final result = await _participantDocsByUser(eventId, userId);

    return result.docs.isNotEmpty;
  }

  static Future<String?> getQrToken(int userId, int eventId) async {
    final result = await _participantDocsByUser(eventId, userId);

    if (result.docs.isEmpty) return null;

    return result.docs.first.data()['qr_token'] as String?;
  }

  static Future<int?> getParticipantId(int userId, int eventId) async {
    final result = await _participantDocsByUser(eventId, userId);

    if (result.docs.isEmpty) return null;

    return (result.docs.first.data()['id'] as num?)?.toInt();
  }

  static Future<List<Map<String, dynamic>>> getParticipants(int eventId) async {
    final participantData = await _participantsCollection(eventId).get();

    final participants = <Map<String, dynamic>>[];

    for (final participant in participantData.docs) {
      final data = participant.data();
      final userId = (data['user_id'] as num?)?.toInt();
      if (userId == null) continue;

      final userData = await _getUserByNumericId(userId);
      if (userData == null) continue;

      participants.add({
        'name': userData['nama'] ?? '',
        'phone': userData['phone'] ?? '',
        'profileImage': _profileImageFromUserMap(userData),
        'isCheckedIn': data['checkin_time'] != null,
      });
    }

    return participants;
  }

  static Future<void> cancelJoin(int userId, int eventId) async {
    final result = await _participantDocsByUser(eventId, userId);

    for (final doc in result.docs) {
      await doc.reference.delete();
    }
  }

  static Future<QuerySnapshot<Map<String, dynamic>>> _participantDocsByUser(
    int eventId,
    int userId,
  ) async {
    var result = await _participantsCollection(
      eventId,
    ).where('user_id', isEqualTo: userId).limit(1).get();

    if (result.docs.isNotEmpty) return result;

    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return result;

    result = await _participantsCollection(
      eventId,
    ).where('user_uid', isEqualTo: uid).limit(1).get();

    return result;
  }

  static Future<bool> isAlreadyCheckin(int participantId) async {
    final result = await _firebaseFirestore
        .collectionGroup('participants')
        .where('id', isEqualTo: participantId)
        .limit(1)
        .get();

    if (result.docs.isEmpty) return false;

    return result.docs.first.data()['checkin_time'] != null;
  }

  static Future<void> checkinParticipant(int participantId) async {
    final result = await _firebaseFirestore
        .collectionGroup('participants')
        .where('id', isEqualTo: participantId)
        .limit(1)
        .get();

    if (result.docs.isEmpty) return;

    await result.docs.first.reference.update({
      'checkin_time': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getCheckinByEvent(
    int eventId,
  ) async {
    final participants = await _participantsCollection(
      eventId,
    ).where('checkin_time', isNull: false).get();

    final result = <Map<String, dynamic>>[];

    for (final participant in participants.docs) {
      final data = participant.data();
      final userId = (data['user_id'] as num?)?.toInt();
      final userData = userId == null
          ? null
          : await _getUserByNumericId(userId);

      result.add({
        'id': data['id'].toString(),
        'userId': data['user_id'].toString(),
        'namaUser': userData?['nama'] ?? '',
        'phone': userData?['phone'] ?? '',
        'profileImage': _profileImageFromUserMap(userData) ?? '',
        'waktu': data['checkin_time'] ?? '',
      });
    }

    return result;
  }

  static Future<void> deleteCheckin(int participantId) async {
    final result = await _firebaseFirestore
        .collectionGroup('participants')
        .where('id', isEqualTo: participantId)
        .limit(1)
        .get();

    if (result.docs.isEmpty) return;

    await result.docs.first.reference.update({'checkin_time': null});
  }

  static Future<Map<String, dynamic>?> getParticipant(
    int userId,
    int eventId,
  ) async {
    final result = await _participantsCollection(
      eventId,
    ).where('user_id', isEqualTo: userId).limit(1).get();

    if (result.docs.isEmpty) return null;

    return result.docs.first.data();
  }

  static Future<Map<String, dynamic>?> getParticipantByToken(
    String token,
    int eventId,
  ) async {
    final participant = await _participantsCollection(
      eventId,
    ).where('qr_token', isEqualTo: token).limit(1).get();

    if (participant.docs.isEmpty) return null;

    final data = participant.docs.first.data();
    final userId = (data['user_id'] as num?)?.toInt();
    final userData = userId == null ? null : await _getUserByNumericId(userId);

    return {...data, 'nama': userData?['nama'] ?? 'Peserta'};
  }
}
