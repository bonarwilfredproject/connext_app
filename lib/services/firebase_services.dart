import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connext_app/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseServices {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firebaseFirestore =
      FirebaseFirestore.instance;

  static String? get currentUid => _auth.currentUser?.uid;

  static DocumentReference<Map<String, dynamic>> get _counterDoc =>
      _firebaseFirestore.collection('metadata').doc('counters');

  static String _emailFromPhone(String phone) {
    final normalized = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return '$normalized@connext.app';
  }

  static String normalizePhoneToE164(String phone, {String? countryDialCode}) {
    final raw = phone.trim();
    if (raw.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-phone-number',
        message: 'Phone number cannot be empty',
      );
    }

    final hasPlusPrefix = raw.startsWith('+');
    final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-phone-number',
        message: 'Phone number format is invalid',
      );
    }

    String normalizedDigits;
    if (hasPlusPrefix) {
      normalizedDigits = digitsOnly;
    } else if (raw.startsWith('00')) {
      normalizedDigits = digitsOnly.substring(2);
    } else {
      final dialDigits = (countryDialCode ?? '').replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      if (dialDigits.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-phone-number',
          message: 'Country dialing code is required for local phone numbers',
        );
      }

      var localDigits = digitsOnly;

      if (localDigits.startsWith(dialDigits) &&
          localDigits.length >= dialDigits.length + 6) {
        normalizedDigits = localDigits;
      } else {
        if (localDigits.startsWith('0')) {
          localDigits = localDigits.substring(1);
        }

        if (localDigits.isEmpty) {
          throw FirebaseAuthException(
            code: 'invalid-phone-number',
            message: 'Phone number format is invalid',
          );
        }

        normalizedDigits = '$dialDigits$localDigits';
      }
    }

    if (normalizedDigits.length < 8 || normalizedDigits.length > 15) {
      throw FirebaseAuthException(
        code: 'invalid-phone-number',
        message: 'Phone number length is invalid',
      );
    }

    return '+$normalizedDigits';
  }

  static String? _profileImageFromMap(Map<String, dynamic>? data) {
    if (data == null) return null;
    final image = data['profile_image'] ?? data['profileImage'];
    return image?.toString();
  }

  static bool _isRemoteImage(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  static bool _looksLikeStoragePath(String path) {
    if (path.contains('://')) return false;
    if (path.startsWith('/') || path.startsWith('\\')) return false;
    if (path.contains('\\')) return false;
    return path.contains('/');
  }

  static Future<String?> _downloadUrlFromKnownStoragePaths(String uid) async {
    final candidates = <String>[
      'profile_images/$uid.jpg',
      'profile_images/$uid.jpeg',
      'profile_images/$uid.png',
      'profile_images/$uid.webp',
    ];

    for (final path in candidates) {
      try {
        final url = await FirebaseStorage.instance.ref(path).getDownloadURL();
        if (url.isNotEmpty) return url;
      } catch (_) {
        // Try next candidate.
      }
    }

    return null;
  }

  static Future<String?> _normalizeProfileImage({
    required String uid,
    required Map<String, dynamic> data,
    required DocumentReference<Map<String, dynamic>> docRef,
  }) async {
    final raw = _profileImageFromMap(data)?.trim();
    final rawLooksLikeStorageRef =
        raw != null &&
        raw.isNotEmpty &&
        !_isRemoteImage(raw) &&
        (raw.startsWith('gs://') || _looksLikeStoragePath(raw));

    if (raw != null && raw.isNotEmpty) {
      if (_isRemoteImage(raw)) return raw;

      try {
        String? resolved;

        if (raw.startsWith('gs://')) {
          resolved = await FirebaseStorage.instance
              .refFromURL(raw)
              .getDownloadURL();
        } else if (_looksLikeStoragePath(raw)) {
          resolved = await FirebaseStorage.instance.ref(raw).getDownloadURL();
        }

        if (resolved != null && resolved.isNotEmpty) {
          await docRef.update({'profile_image': resolved});
          return resolved;
        }
      } catch (_) {
        // Continue to fallback lookup by UID.
      }
    }

    try {
      final fallbackUrl = await _downloadUrlFromKnownStoragePaths(uid);
      if (fallbackUrl != null && fallbackUrl.isNotEmpty) {
        await docRef.set({
          'profile_image': fallbackUrl,
        }, SetOptions(merge: true));
        return fallbackUrl;
      }
    } catch (_) {
      // Ignore and return existing value if any.
    }

    // Avoid repeated getDownloadURL attempts and noisy 404 logs on invalid
    // legacy storage references by clearing the field once fallback also fails.
    if (rawLooksLikeStorageRef) {
      await docRef.set({
        'profile_image': FieldValue.delete(),
      }, SetOptions(merge: true));
      return null;
    }

    return raw;
  }

  static int? _toIntFlexible(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();

    final text = value.toString().trim();
    if (text.isEmpty) return null;

    final asInt = int.tryParse(text);
    if (asInt != null) return asInt;

    final asDouble = double.tryParse(text);
    if (asDouble != null) return asDouble.toInt();

    return null;
  }

  static Future<int?> _ensureNumericUserId({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    final existingId = _toIntFlexible(data['id']);
    if (existingId != null && existingId > 0) {
      return existingId;
    }

    // Try to reuse a valid ID from a same-phone account (legacy migration).
    final phone = data['phone']?.toString().trim();
    if (phone != null && phone.isNotEmpty) {
      final phoneMatch = await _firebaseFirestore
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(5)
          .get();

      for (final doc in phoneMatch.docs) {
        final candidateId = _toIntFlexible(doc.data()['id']);
        if (candidateId != null && candidateId > 0) {
          await _firebaseFirestore.collection('users').doc(uid).set({
            'id': candidateId,
            'uid': uid,
          }, SetOptions(merge: true));
          return candidateId;
        }
      }
    }

    // If no valid ID exists, create one from counter and store it.
    final nextId = await _nextUserId();
    await _firebaseFirestore.collection('users').doc(uid).set({
      'id': nextId,
      'uid': uid,
    }, SetOptions(merge: true));
    return nextId;
  }

  static Future<int> _nextUserId() async {
    return _firebaseFirestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(_counterDoc);
      final current = (snapshot.data()?['user_id'] as num?)?.toInt() ?? 0;
      final nextValue = current + 1;

      transaction.set(_counterDoc, {
        'user_id': nextValue,
      }, SetOptions(merge: true));

      return nextValue;
    });
  }

  static Future<UserModel> registerUser({required UserModel user}) async {
    final email = _emailFromPhone(user.phone);
    final userId = await _nextUserId();
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: user.password,
    );

    final firebaseUser = cred.user!;
    await _firebaseFirestore.collection('users').doc(firebaseUser.uid).set({
      ...user.toMap(),
      'id': userId,
      'uid': firebaseUser.uid,
      'email': email,
      'created_at': FieldValue.serverTimestamp(),
    });

    return UserModel(
      id: userId,
      nama: user.nama,
      phone: user.phone,
      password: user.password,
      role: user.role,
      profileImage: user.profileImage,
    );
  }

  static Future<UserModel> registerUserWithPhoneCredential({
    required UserModel user,
    required PhoneAuthCredential credential,
  }) async {
    final email = _emailFromPhone(user.phone);
    final e164Phone = normalizePhoneToE164(user.phone);

    bool shouldSignOut = false;

    try {
      final phoneSignIn = await _auth.signInWithCredential(credential);
      final firebaseUser = phoneSignIn.user;

      if (firebaseUser == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Phone verification did not produce a valid user',
        );
      }

      shouldSignOut = true;

      final existingProfile = await _firebaseFirestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (existingProfile.exists) {
        throw FirebaseAuthException(
          code: 'phone-already-registered',
          message: 'Phone number is already registered',
        );
      }

      final userId = await _nextUserId();

      final emailCredential = EmailAuthProvider.credential(
        email: email,
        password: user.password,
      );

      try {
        await firebaseUser.linkWithCredential(emailCredential);
      } on FirebaseAuthException catch (e) {
        if (e.code != 'provider-already-linked') {
          rethrow;
        }
      }

      await _firebaseFirestore.collection('users').doc(firebaseUser.uid).set({
        ...user.toMap(),
        'id': userId,
        'uid': firebaseUser.uid,
        'email': email,
        'phone': user.phone.trim(),
        'phone_e164': e164Phone,
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return UserModel(
        id: userId,
        nama: user.nama,
        phone: user.phone,
        password: user.password,
        role: user.role,
        profileImage: user.profileImage,
      );
    } finally {
      if (shouldSignOut) {
        await _auth.signOut();
      }
    }
  }

  static Future<QueryDocumentSnapshot<Map<String, dynamic>>?>
  _findPhoneConflict(String phone, {String? excludeUid}) async {
    final rawPhone = phone.trim();
    if (rawPhone.isEmpty) return null;

    String? normalizedPhone;
    try {
      normalizedPhone = normalizePhoneToE164(rawPhone);
    } on FirebaseAuthException {
      normalizedPhone = null;
    }

    final canonicalPhone = normalizedPhone ?? rawPhone;
    final expectedEmail = _emailFromPhone(canonicalPhone);

    final phoneMatches = await _firebaseFirestore
        .collection('users')
        .where('phone', isEqualTo: canonicalPhone)
        .limit(10)
        .get();

    final e164Matches = await _firebaseFirestore
        .collection('users')
        .where('phone_e164', isEqualTo: canonicalPhone)
        .limit(10)
        .get();

    final effectiveExcludeUid = (excludeUid != null && excludeUid.isNotEmpty)
        ? excludeUid
        : _auth.currentUser?.uid;

    final seenPaths = <String>{};
    for (final doc in [...phoneMatches.docs, ...e164Matches.docs]) {
      // Use document ID as the primary UID source because legacy `uid` fields
      // may contain stale values and can break self-exclusion checks.
      final docUid = doc.id.toString();
      if (effectiveExcludeUid != null && docUid == effectiveExcludeUid) {
        continue;
      }

      // Ignore legacy rows where phone fields are stale and do not map to
      // the canonical email derived from this phone number.
      final docEmail = (doc.data()['email'] ?? '').toString().trim();
      if (docEmail.isEmpty || docEmail != expectedEmail) {
        continue;
      }

      if (seenPaths.add(doc.reference.path)) {
        return doc;
      }
    }

    return null;
  }

  static Future<bool> isPhoneExists(String phone, {String? excludeUid}) async {
    final conflict = await _findPhoneConflict(phone, excludeUid: excludeUid);
    return conflict != null;
  }

  static Future<Map<String, String>?> getPhoneConflictDebugInfo(
    String phone, {
    String? excludeUid,
  }) async {
    final conflict = await _findPhoneConflict(phone, excludeUid: excludeUid);
    if (conflict == null) return null;

    final data = conflict.data();
    return {
      'uid': conflict.id,
      'email': (data['email'] ?? '').toString(),
      'phone': (data['phone'] ?? '').toString(),
      'phone_e164': (data['phone_e164'] ?? '').toString(),
    };
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

    final resolvedId = await _ensureNumericUserId(
      uid: firebaseUser.uid,
      data: data,
    );

    final normalizedProfileImage = await _normalizeProfileImage(
      uid: firebaseUser.uid,
      data: data,
      docRef: doc.reference,
    );

    return UserModel.fromMap({
      'id': resolvedId,
      'nama': data['nama'] ?? '',
      'phone': data['phone'] ?? '',
      'password': data['password'] ?? '',
      'role': data['role'] ?? 'Attendee',
      'profile_image': normalizedProfileImage,
    });
  }

  static Stream<UserModel?> currentUserProfileStream() {
    return _auth.authStateChanges().asyncExpand((firebaseUser) {
      if (firebaseUser == null) {
        return Stream<UserModel?>.value(null);
      }

      return _firebaseFirestore
          .collection('users')
          .doc(firebaseUser.uid)
          .snapshots()
          .asyncMap((_) => getCurrentUserProfile());
    });
  }

  static Future<void> updateProfile({
    required String name,
    required String phone,
  }) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return;

    final normalizedPhone = normalizePhoneToE164(phone);

    await _firebaseFirestore.collection('users').doc(firebaseUser.uid).update({
      'nama': name,
      'phone': normalizedPhone,
      'phone_e164': normalizedPhone,
    });
  }

  static Future<void> updateProfileImage(String imagePath) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return;

    final trimmed = imagePath.trim();
    if (trimmed.isEmpty) return;

    // If already a usable URL, just store it.
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      await _firebaseFirestore.collection('users').doc(firebaseUser.uid).update(
        {'profile_image': trimmed},
      );
      return;
    }

    // If it's a gs:// URL, normalize it to a download URL.
    if (trimmed.startsWith('gs://')) {
      final url = await FirebaseStorage.instance
          .refFromURL(trimmed)
          .getDownloadURL();
      await _firebaseFirestore.collection('users').doc(firebaseUser.uid).update(
        {'profile_image': url},
      );
      return;
    }

    // If it's a Firebase Storage path, normalize it to a download URL.
    if (_looksLikeStoragePath(trimmed)) {
      final url = await FirebaseStorage.instance.ref(trimmed).getDownloadURL();
      await _firebaseFirestore.collection('users').doc(firebaseUser.uid).update(
        {'profile_image': url},
      );
      return;
    }

    // Otherwise, treat as a local filesystem path and upload it to Storage.
    final file = File(trimmed);
    if (!file.existsSync()) return;

    final ext = _safeFileExtension(file.path);
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('profile_images')
        .child('${firebaseUser.uid}$ext');

    await storageRef.putFile(file);
    final downloadUrl = await storageRef.getDownloadURL();

    await _firebaseFirestore.collection('users').doc(firebaseUser.uid).update({
      'profile_image': downloadUrl,
    });
  }

  static String _safeFileExtension(String path) {
    final lastDot = path.lastIndexOf('.');
    final lastSlash = path.lastIndexOf(RegExp(r'[\\/]'));

    if (lastDot == -1) return '.jpg';
    if (lastSlash != -1 && lastDot < lastSlash) return '.jpg';

    final ext = path.substring(lastDot);
    if (ext.length > 6) return '.jpg';
    return ext;
  }

  static Future<void> updateProfileImageBytes(
    Uint8List bytes, {
    String? fileName,
  }) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return;
    if (bytes.isEmpty) return;

    final ext = _safeFileExtension(fileName ?? '.jpg');
    final contentType = _contentTypeFromExtension(ext);

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('profile_images')
        .child('${firebaseUser.uid}$ext');

    await storageRef.putData(bytes, SettableMetadata(contentType: contentType));

    final downloadUrl = await storageRef.getDownloadURL();
    await _firebaseFirestore.collection('users').doc(firebaseUser.uid).update({
      'profile_image': downloadUrl,
    });
  }

  static String _contentTypeFromExtension(String ext) {
    final normalized = ext.toLowerCase();
    switch (normalized) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.jpeg':
      case '.jpg':
      default:
        return 'image/jpeg';
    }
  }

  static Future<void> updateRole(String role) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return;

    await _firebaseFirestore.collection('users').doc(firebaseUser.uid).update({
      'role': role,
    });
  }

  static Future<void> updateCurrentUserPhoneWithCredential({
    required PhoneAuthCredential credential,
  }) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'User is not logged in',
      );
    }

    try {
      await firebaseUser.updatePhoneNumber(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use' ||
          e.code == 'phone-number-already-exists') {
        throw FirebaseAuthException(
          code: 'phone-already-registered',
          message: 'Phone number is already used',
        );
      }
      rethrow;
    }
  }

  static Future<List<String>> _resolveEmailCandidatesByPhone(
    String phone,
  ) async {
    final rawPhone = phone.trim();
    if (rawPhone.isEmpty) return const [];

    String canonicalPhone = rawPhone;
    try {
      canonicalPhone = normalizePhoneToE164(rawPhone);
    } on FirebaseAuthException {
      canonicalPhone = rawPhone;
    }

    final emailCandidates = <String>[];
    final seen = <String>{};

    void addCandidate(String? value) {
      final email = (value ?? '').trim();
      if (email.isEmpty) return;
      if (seen.add(email)) {
        emailCandidates.add(email);
      }
    }

    final byE164 = await _firebaseFirestore
        .collection('users')
        .where('phone_e164', isEqualTo: canonicalPhone)
        .limit(10)
        .get();

    final byPhoneCanonical = await _firebaseFirestore
        .collection('users')
        .where('phone', isEqualTo: canonicalPhone)
        .limit(10)
        .get();

    QuerySnapshot<Map<String, dynamic>>? byPhoneRaw;
    if (rawPhone != canonicalPhone) {
      byPhoneRaw = await _firebaseFirestore
          .collection('users')
          .where('phone', isEqualTo: rawPhone)
          .limit(10)
          .get();
    }

    for (final doc in [
      ...byE164.docs,
      ...byPhoneCanonical.docs,
      if (byPhoneRaw != null) ...byPhoneRaw.docs,
    ]) {
      final data = doc.data();
      addCandidate(data['email']?.toString());
    }

    return emailCandidates;
  }

  static Future<UserModel?> loginUser({
    required String phone,
    required String password,
  }) async {
    final initialEmail = _emailFromPhone(phone);
    final candidates = <String>[];
    final seenCandidates = <String>{};

    void addCandidate(String? value) {
      final email = (value ?? '').trim();
      if (email.isEmpty) return;
      if (seenCandidates.add(email)) {
        candidates.add(email);
      }
    }

    addCandidate(initialEmail);

    final resolvedCandidates = await _resolveEmailCandidatesByPhone(phone);
    final hasResolvedPhoneRecord = resolvedCandidates.any(
      (e) => e.trim().isNotEmpty,
    );

    for (final email in resolvedCandidates) {
      addCandidate(email);
    }

    try {
      UserCredential? cred;
      bool hasPasswordMismatch = false;

      for (final candidate in candidates) {
        try {
          cred = await _auth.signInWithEmailAndPassword(
            email: candidate,
            password: password,
          );
          break;
        } on FirebaseAuthException catch (e) {
          final code = e.code.toLowerCase();

          if (code == 'wrong-password') {
            if (hasResolvedPhoneRecord) {
              hasPasswordMismatch = true;
            }
            continue;
          }

          if (code == 'user-not-found') {
            continue;
          }

          if (code == 'invalid-credential') {
            continue;
          }

          rethrow;
        }
      }

      if (cred == null) {
        if (hasPasswordMismatch) {
          throw FirebaseAuthException(
            code: 'wrong-password',
            message: 'Incorrect password',
          );
        }

        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Phone is not registered',
        );
      }

      final firebaseUser = cred.user;
      if (firebaseUser == null) return null;

      final doc = await _firebaseFirestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      final data = doc.data();
      if (data == null) return null;

      final resolvedId = await _ensureNumericUserId(
        uid: firebaseUser.uid,
        data: data,
      );

      final normalizedProfileImage = await _normalizeProfileImage(
        uid: firebaseUser.uid,
        data: data,
        docRef: doc.reference,
      );

      return UserModel.fromMap({
        'id': resolvedId,
        'nama': data['nama'] ?? '',
        'phone': data['phone'] ?? phone,
        'password': data['password'] ?? password,
        'role': data['role'] ?? 'user',
        'profile_image': normalizedProfileImage,
      });
    } on FirebaseAuthException catch (e) {
      final errorCode = e.code.toLowerCase();

      if (errorCode == 'wrong-password') {
        throw FirebaseAuthException(
          code: 'wrong-password',
          message: 'Incorrect password',
        );
      }

      if (errorCode == 'invalid-credential' || errorCode == 'user-not-found') {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Phone is not registered',
        );
      }

      rethrow;
    }
  }

  static Future<UserModel?> getUserByNumericId(int userId) async {
    final numericQuery = await _firebaseFirestore
        .collection('users')
        .where('id', isEqualTo: userId)
        .limit(1)
        .get();

    QueryDocumentSnapshot<Map<String, dynamic>>? userDoc;
    if (numericQuery.docs.isNotEmpty) {
      userDoc = numericQuery.docs.first;
    } else {
      final stringQuery = await _firebaseFirestore
          .collection('users')
          .where('id', isEqualTo: userId.toString())
          .limit(1)
          .get();
      if (stringQuery.docs.isNotEmpty) {
        userDoc = stringQuery.docs.first;
      }
    }

    if (userDoc == null) return null;

    final data = userDoc.data();
    final uid = (data['uid'] ?? userDoc.id).toString();
    final normalizedProfileImage = await _normalizeProfileImage(
      uid: uid,
      data: data,
      docRef: userDoc.reference,
    );

    return UserModel.fromMap({
      ...data,
      'profile_image': normalizedProfileImage,
    });
  }

  static Future<void> logout() async {
    await _auth.signOut();
  }
}
