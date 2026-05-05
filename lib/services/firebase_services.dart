import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connext_app/models/user_model.dart';
import 'package:connext_app/services/preferences_services.dart';
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

  static String _fallbackEmailFromPhoneAndUid(String phone, String uid) {
    final normalized = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final safeUid = uid.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    final uidSuffix = safeUid.isEmpty
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : safeUid.substring(0, safeUid.length > 12 ? 12 : safeUid.length);
    return '$normalized.$uidSuffix@connext.app';
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
    final canonicalEmail = _emailFromPhone(user.phone);
    final e164Phone = normalizePhoneToE164(user.phone);
    String loginEmail = canonicalEmail;

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

      Future<void> linkUsingEmail(String targetEmail) async {
        final emailCredential = EmailAuthProvider.credential(
          email: targetEmail,
          password: user.password,
        );
        await firebaseUser.linkWithCredential(emailCredential);
        loginEmail = targetEmail;
      }

      bool isEmailConflictCode(String code) {
        final normalized = code.toLowerCase();
        return normalized == 'credential-already-in-use' ||
            normalized == 'email-already-in-use';
      }

      try {
        await linkUsingEmail(canonicalEmail);
      } on FirebaseAuthException catch (e) {
        final authCode = e.code.toLowerCase();

        if (authCode == 'provider-already-linked') {
          // Email provider already linked, this is fine
          loginEmail = firebaseUser.email ?? canonicalEmail;
        } else if (authCode == 'credential-already-in-use' ||
            authCode == 'email-already-in-use') {
          // Email is already registered by another user
          // Try to recover: check if this is an old email from a user who changed phone
          try {
            QuerySnapshot<Map<String, dynamic>> usersWithOldEmail =
                await _firebaseFirestore
                    .collection('users')
                    .where('old_email', isEqualTo: canonicalEmail)
                    .where('old_phone_e164', isEqualTo: e164Phone)
                    .limit(1)
                    .get();

            if (usersWithOldEmail.docs.isEmpty) {
              usersWithOldEmail = await _firebaseFirestore
                  .collection('users')
                  .where('auth_email_legacy', isEqualTo: canonicalEmail)
                  .where('old_phone_e164', isEqualTo: e164Phone)
                  .limit(1)
                  .get();
            }

            if (usersWithOldEmail.docs.isNotEmpty) {
              // Found matching old email+phone, clear them to allow re-registration
              await _firebaseFirestore
                  .collection('users')
                  .doc(usersWithOldEmail.docs.first.id)
                  .update({
                    'old_email': FieldValue.delete(),
                    'old_phone_e164': FieldValue.delete(),
                    'auth_email_legacy': FieldValue.delete(),
                  });

              // Retry linking with cleared old email
              try {
                await linkUsingEmail(canonicalEmail);
              } on FirebaseAuthException catch (retryError) {
                if (!isEmailConflictCode(retryError.code)) {
                  throw FirebaseAuthException(
                    code: 'email-linking-failed',
                    message:
                        'Failed to complete email registration after cleanup: ${retryError.toString()}',
                  );
                }

                // Canonical still occupied in Auth, fallback to deterministic alias.
                final fallbackEmail = _fallbackEmailFromPhoneAndUid(
                  e164Phone,
                  firebaseUser.uid,
                );

                try {
                  await linkUsingEmail(fallbackEmail);
                } on FirebaseAuthException catch (fallbackError) {
                  final fallbackCode = fallbackError.code.toLowerCase();
                  if (fallbackCode == 'provider-already-linked') {
                    loginEmail = firebaseUser.email ?? fallbackEmail;
                  } else {
                    throw FirebaseAuthException(
                      code: 'email-linking-failed',
                      message:
                          'Failed to complete email registration after cleanup with fallback alias: ${fallbackError.toString()}',
                    );
                  }
                }
              }
            } else {
              // If canonical email is already occupied, use deterministic alias email.
              final fallbackEmail = _fallbackEmailFromPhoneAndUid(
                e164Phone,
                firebaseUser.uid,
              );
              try {
                await linkUsingEmail(fallbackEmail);
              } on FirebaseAuthException catch (fallbackError) {
                final fallbackCode = fallbackError.code.toLowerCase();
                if (fallbackCode == 'provider-already-linked') {
                  loginEmail = firebaseUser.email ?? fallbackEmail;
                } else {
                  throw FirebaseAuthException(
                    code: 'email-already-registered',
                    message:
                        'Email associated with this phone is already registered and fallback alias failed. Please contact support.',
                  );
                }
              }
            }
          } catch (recoveryError) {
            if (recoveryError is FirebaseAuthException) {
              rethrow;
            }
            throw FirebaseAuthException(
              code: 'email-recovery-failed',
              message:
                  'Could not resolve email registration issue: ${recoveryError.toString()}',
            );
          }
        } else {
          rethrow;
        }
      }

      try {
        await _firebaseFirestore.collection('users').doc(firebaseUser.uid).set({
          ...user.toMap(),
          'id': userId,
          'uid': firebaseUser.uid,
          'email': loginEmail,
          'auth_email_canonical': canonicalEmail,
          if (loginEmail != canonicalEmail) 'auth_email_legacy': canonicalEmail,
          'phone': user.phone.trim(),
          'phone_e164': e164Phone,
          'created_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (firestoreError) {
        throw FirebaseAuthException(
          code: 'firestore-write-failed',
          message: 'Failed to save user profile: ${firestoreError.toString()}',
        );
      }

      return UserModel(
        id: userId,
        nama: user.nama,
        phone: user.phone,
        password: user.password,
        role: user.role,
        profileImage: user.profileImage,
      );
    } on FirebaseAuthException {
      rethrow;
    } catch (unexpectedError) {
      throw FirebaseAuthException(
        code: 'registration-error',
        message:
            'An unexpected error occurred during registration: ${unexpectedError.toString()}',
      );
    } finally {
      if (shouldSignOut) {
        await _auth.signOut();
      }
    }
  }

  static Future<void> migratePhoneAuthMappingsOnce() async {
    final pref = PreferenceHandler();
    await pref.init();
    if (pref.getPhoneAuthMappingsMigrated()) return;

    final usersSnapshot = await _firebaseFirestore.collection('users').get();
    if (usersSnapshot.docs.isEmpty) {
      await pref.setPhoneAuthMappingsMigrated(true);
      return;
    }

    final batch = _firebaseFirestore.batch();
    var changes = 0;

    for (final doc in usersSnapshot.docs) {
      final data = doc.data();
      final rawPhone = (data['phone_e164'] ?? data['phone'] ?? '')
          .toString()
          .trim();
      if (rawPhone.isEmpty) continue;

      String phoneE164;
      try {
        phoneE164 = normalizePhoneToE164(rawPhone);
      } catch (_) {
        try {
          phoneE164 = normalizePhoneToE164(rawPhone, countryDialCode: '+62');
        } catch (_) {
          continue;
        }
      }

      final canonicalEmail = _emailFromPhone(phoneE164);
      final currentEmail = (data['email'] ?? '').toString().trim();

      final updateData = <String, dynamic>{
        'phone_e164': phoneE164,
        'auth_email_canonical': canonicalEmail,
        'phone_auth_migrated_at': FieldValue.serverTimestamp(),
      };

      if (currentEmail.isNotEmpty && currentEmail != canonicalEmail) {
        updateData['auth_email_legacy'] = currentEmail;
      }

      batch.set(doc.reference, updateData, SetOptions(merge: true));
      changes++;
    }

    if (changes > 0) {
      await batch.commit();
    }

    await pref.setPhoneAuthMappingsMigrated(true);
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
        : null;

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
    String? oldPhone,
  }) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return;

    final normalizedPhone = normalizePhoneToE164(phone);

    String? normalizedOldPhone;
    if (oldPhone != null && oldPhone.trim().isNotEmpty) {
      try {
        normalizedOldPhone = normalizePhoneToE164(oldPhone);
      } catch (_) {
        normalizedOldPhone = oldPhone.trim();
      }
    }

    final hasChangedPhone =
        normalizedOldPhone != null && normalizedOldPhone != normalizedPhone;

    final updateData = <String, dynamic>{
      'nama': name,
      'phone': normalizedPhone,
      'phone_e164': normalizedPhone,
    };

    if (hasChangedPhone) {
      updateData['old_email'] = _emailFromPhone(normalizedOldPhone);
      updateData['old_phone_e164'] = normalizedOldPhone;
    }

    await _firebaseFirestore
        .collection('users')
        .doc(firebaseUser.uid)
        .update(updateData);
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

  static String _normalizePhoneSafely(String phone, {String? countryDialCode}) {
    try {
      return normalizePhoneToE164(phone, countryDialCode: countryDialCode);
    } catch (_) {
      final raw = phone.trim();
      final digits = raw.replaceAll(RegExp(r'[^0-9+]'), '');
      if (digits.isEmpty) return raw;
      if (digits.startsWith('+')) return digits;
      return '+$digits';
    }
  }

  static Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _findUserDocsByPhoneFlexible(String phone, {String? countryDialCode}) async {
    final candidates = <String>{};
    final trimmed = phone.trim();
    if (trimmed.isNotEmpty) {
      candidates.add(trimmed);
      candidates.add(
        _normalizePhoneSafely(trimmed, countryDialCode: countryDialCode),
      );
      candidates.add(_normalizePhoneSafely(trimmed, countryDialCode: '+62'));
    }

    final docsByPath = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};

    for (final value in candidates) {
      if (value.isEmpty) continue;

      final byE164 = await _firebaseFirestore
          .collection('users')
          .where('phone_e164', isEqualTo: value)
          .limit(10)
          .get();

      for (final doc in byE164.docs) {
        docsByPath[doc.reference.path] = doc;
      }

      final byPhone = await _firebaseFirestore
          .collection('users')
          .where('phone', isEqualTo: value)
          .limit(10)
          .get();

      for (final doc in byPhone.docs) {
        docsByPath[doc.reference.path] = doc;
      }
    }

    return docsByPath.values.toList();
  }

  static bool _isSamePhone(String a, String b) {
    final normalizedA = _normalizePhoneSafely(a);
    final normalizedB = _normalizePhoneSafely(b);
    return normalizedA == normalizedB;
  }

  static Future<UserModel?> loginUser({
    required String phone,
    required String password,
  }) async {
    final requestedPhone = _normalizePhoneSafely(phone);
    final initialEmail = _emailFromPhone(requestedPhone);
    final candidates = <String>[];
    final seenCandidates = <String>{};

    void addCandidate(String? value) {
      final email = (value ?? '').trim();
      if (email.isEmpty) return;
      if (seenCandidates.add(email)) {
        candidates.add(email);
      }
    }

    final matchedUserDocs = await _findUserDocsByPhoneFlexible(requestedPhone);
    final hasResolvedPhoneRecordFromDocs = matchedUserDocs.isNotEmpty;

    addCandidate(initialEmail);

    for (final doc in matchedUserDocs) {
      final data = doc.data();
      addCandidate(data['email']?.toString());
      addCandidate(data['auth_email_canonical']?.toString());
      addCandidate(data['auth_email_legacy']?.toString());
    }

    final resolvedCandidates = await _resolveEmailCandidatesByPhone(
      requestedPhone,
    );
    final hasResolvedPhoneRecord =
        hasResolvedPhoneRecordFromDocs || resolvedCandidates.isNotEmpty;

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

          final firebaseUser = cred.user;
          if (firebaseUser == null) {
            cred = null;
            continue;
          }

          final profileDoc = await _firebaseFirestore
              .collection('users')
              .doc(firebaseUser.uid)
              .get();
          final profileData = profileDoc.data();

          var matchedPhone = false;
          final authPhone = (firebaseUser.phoneNumber ?? '').trim();
          if (authPhone.isNotEmpty && _isSamePhone(authPhone, requestedPhone)) {
            matchedPhone = true;
          }

          if (!matchedPhone && profileData != null) {
            final profilePhoneE164 = (profileData['phone_e164'] ?? '')
                .toString()
                .trim();
            final profilePhone = (profileData['phone'] ?? '').toString().trim();
            if (profilePhoneE164.isNotEmpty &&
                _isSamePhone(profilePhoneE164, requestedPhone)) {
              matchedPhone = true;
            }
            if (!matchedPhone &&
                profilePhone.isNotEmpty &&
                _isSamePhone(profilePhone, requestedPhone)) {
              matchedPhone = true;
            }
          }

          if (!matchedPhone) {
            await _auth.signOut();
            cred = null;
            continue;
          }

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
            if (hasResolvedPhoneRecord) {
              hasPasswordMismatch = true;
            }
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

  static Future<void> resetPasswordForCurrentUser({
    required String currentPassword,
    required String newPassword,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user is currently logged in',
      );
    }

    final userEmail = currentUser.email;
    if (userEmail == null || userEmail.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'User email not found',
      );
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: userEmail,
        password: currentPassword,
      );
      await currentUser.reauthenticateWithCredential(credential);

      await currentUser.updatePassword(newPassword);

      await _firebaseFirestore.collection('users').doc(currentUser.uid).update({
        'password': newPassword,
        'password_updated_at': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      final code = e.code.toLowerCase();
      final message = (e.message ?? '').toLowerCase();
      if (code == 'wrong-password' ||
          code == 'invalid-credential' ||
          message.contains('wrong password') ||
          message.contains('incorrect password') ||
          message.contains('invalid credential')) {
        throw FirebaseAuthException(
          code: 'wrong-password',
          message: 'Current password is incorrect',
        );
      }
      rethrow;
    }
  }

  static Future<String?> findUserByPhoneForForgotPassword(
    String phone, {
    String? countryDialCode,
  }) async {
    String phoneE164;
    try {
      phoneE164 = normalizePhoneToE164(phone, countryDialCode: countryDialCode);
    } catch (_) {
      phoneE164 = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    }

    final byE164 = await _firebaseFirestore
        .collection('users')
        .where('phone_e164', isEqualTo: phoneE164)
        .limit(1)
        .get();

    final byPhone = await _firebaseFirestore
        .collection('users')
        .where('phone', isEqualTo: phoneE164)
        .limit(1)
        .get();

    QueryDocumentSnapshot<Map<String, dynamic>>? userDoc;
    if (byE164.docs.isNotEmpty) {
      userDoc = byE164.docs.first;
    } else if (byPhone.docs.isNotEmpty) {
      userDoc = byPhone.docs.first;
    }

    if (userDoc == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Phone number is not registered',
      );
    }

    await userDoc.reference.set({
      'phone': phoneE164,
      'phone_e164': phoneE164,
    }, SetOptions(merge: true));

    final userData = userDoc.data();
    final userEmail = (userData['email'] ?? '').toString().trim();

    if (userEmail.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'User email not found in system',
      );
    }

    return userEmail;
  }

  static Future<void> resetPasswordWithPhoneVerification({
    required String phone,
    required String newPassword,
    required PhoneAuthCredential credential,
  }) async {
    final phoneE164 = normalizePhoneToE164(phone);

    final signInResult = await _auth.signInWithCredential(credential);
    final signedInUser = signInResult.user;

    if (signedInUser == null) {
      throw FirebaseAuthException(
        code: 'phone-auth-failed',
        message: 'Phone authentication failed',
      );
    }

    if (signInResult.additionalUserInfo?.isNewUser == true) {
      try {
        await signedInUser.delete();
      } catch (_) {}
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Phone number is not registered',
      );
    }

    final authPhone = signedInUser.phoneNumber ?? '';
    if (authPhone.isNotEmpty && authPhone != phoneE164) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Phone number does not match account',
      );
    }

    try {
      final canonicalEmail = _emailFromPhone(phoneE164);
      final loginEmail = canonicalEmail;
      var emailToPersist = loginEmail;

      final providerIds = signedInUser.providerData
          .map((provider) => provider.providerId)
          .toSet();

      if (!providerIds.contains('password')) {
        final emailCredential = EmailAuthProvider.credential(
          email: loginEmail,
          password: newPassword,
        );

        try {
          await signedInUser.linkWithCredential(emailCredential);
          emailToPersist = loginEmail;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'provider-already-linked') {
            await signedInUser.updatePassword(newPassword);
            emailToPersist = signedInUser.email ?? loginEmail;
          } else if (e.code == 'email-already-in-use' ||
              e.code == 'credential-already-in-use') {
            await signedInUser.updatePassword(newPassword);
            emailToPersist = signedInUser.email ?? loginEmail;
          } else {
            rethrow;
          }
        }
      } else {
        await signedInUser.updatePassword(newPassword);
        emailToPersist = signedInUser.email ?? loginEmail;
      }

      await _firebaseFirestore.collection('users').doc(signedInUser.uid).set({
        'uid': signedInUser.uid,
        if (emailToPersist.isNotEmpty) 'email': emailToPersist,
        'phone': phoneE164,
        'phone_e164': phoneE164,
        'password': newPassword,
        'password_updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } finally {
      await _auth.signOut();
    }
  }

  static Future<void> logout() async {
    await _auth.signOut();
  }
}
