import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

enum GooglePlacesKeySource { none, dartDefine, firestore }

class GooglePlacesException implements Exception {
  final String code;
  final String message;

  const GooglePlacesException({required this.code, required this.message});

  String get userMessage {
    if (code == 'API_KEY_NOT_CONFIGURED') {
      return 'API key Google Places belum terkonfigurasi.';
    }

    if (code == 'REQUEST_DENIED') {
      return 'REQUEST_DENIED: cek API key, billing, dan API restrictions.';
    }

    if (code == 'OVER_QUERY_LIMIT') {
      return 'OVER_QUERY_LIMIT: kuota Google Places sudah habis.';
    }

    return '$code: $message';
  }

  @override
  String toString() => 'GooglePlacesException(code: $code, message: $message)';
}

class GooglePlacePrediction {
  final String description;
  final String placeId;
  final String? mainText;
  final String? secondaryText;

  const GooglePlacePrediction({
    required this.description,
    required this.placeId,
    this.mainText,
    this.secondaryText,
  });
}

class GooglePlaceDetails {
  final String placeId;
  final String description;
  final String formattedAddress;
  final String? name;

  const GooglePlaceDetails({
    required this.placeId,
    required this.description,
    required this.formattedAddress,
    this.name,
  });
}

class GooglePlacesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static String? _cachedApiKey;
  static GooglePlacesKeySource _cachedKeySource = GooglePlacesKeySource.none;

  static Future<String?> _resolveApiKey() async {
    if (_cachedApiKey != null) return _cachedApiKey;

    try {
      final doc = await _firestore
          .collection('app_config')
          .doc('google_maps')
          .get();
      final data = doc.data();
      final key =
          (data?['places_api_key'] ??
                  data?['google_places_api_key'] ??
                  data?['api_key'])
              ?.toString()
              .trim();

      if (key != null && key.isNotEmpty) {
        _cachedApiKey = key;
        _cachedKeySource = GooglePlacesKeySource.firestore;
        return _cachedApiKey;
      }
    } catch (_) {
      // Fall back to disabled autocomplete if config cannot be loaded.
    }

    const envKey = String.fromEnvironment('GOOGLE_PLACES_API_KEY');
    if (envKey.trim().isNotEmpty) {
      _cachedApiKey = envKey.trim();
      _cachedKeySource = GooglePlacesKeySource.dartDefine;
      return _cachedApiKey;
    }

    _cachedKeySource = GooglePlacesKeySource.none;

    return null;
  }

  static Future<GooglePlacesKeySource> getActiveKeySource() async {
    await _resolveApiKey();
    return _cachedKeySource;
  }

  static Future<String> getActiveKeySourceLabel() async {
    final source = await getActiveKeySource();
    switch (source) {
      case GooglePlacesKeySource.dartDefine:
        return 'dart-define';
      case GooglePlacesKeySource.firestore:
        return 'Firestore';
      case GooglePlacesKeySource.none:
        return 'none';
    }
  }

  static void clearCachedKey() {
    _cachedApiKey = null;
    _cachedKeySource = GooglePlacesKeySource.none;
  }

  static Future<void> savePlacesApiKeyToFirestore(String apiKey) async {
    final safeKey = apiKey.trim();
    if (safeKey.isEmpty) {
      throw const GooglePlacesException(
        code: 'INVALID_KEY',
        message: 'API key cannot be empty',
      );
    }

    await _firestore.collection('app_config').doc('google_maps').set({
      'places_api_key': safeKey,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    clearCachedKey();
  }

  static Future<List<GooglePlacePrediction>> autocomplete(
    String input, {
    String language = 'id',
    String? countryCode,
  }) async {
    final query = input.trim();
    if (query.length < 2) return const [];

    final apiKey = await _resolveApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw const GooglePlacesException(
        code: 'API_KEY_NOT_CONFIGURED',
        message:
            'Set key from your Firebase project via GOOGLE_PLACES_API_KEY or Firestore app_config/google_maps.places_api_key',
      );
    }

    final params = <String, String>{
      'input': query,
      'key': apiKey,
      'language': language,
    };

    if (countryCode != null && countryCode.trim().isNotEmpty) {
      params['components'] = 'country:${countryCode.trim()}';
    }

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      params,
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw GooglePlacesException(
        code: 'HTTP_${response.statusCode}',
        message: 'Google Places HTTP error ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const GooglePlacesException(
        code: 'PARSE_ERROR',
        message: 'Invalid Places response payload',
      );
    }

    final status = decoded['status']?.toString() ?? 'UNKNOWN';
    if (status != 'OK' && status != 'ZERO_RESULTS') {
      final statusMessage =
          decoded['error_message']?.toString() ??
          'Places autocomplete failed with status $status';
      throw GooglePlacesException(code: status, message: statusMessage);
    }

    final predictions = decoded['predictions'];
    if (predictions is! List) return const [];

    return predictions
        .whereType<Map>()
        .map(
          (prediction) => GooglePlacePrediction(
            description: prediction['description']?.toString() ?? '',
            placeId: prediction['place_id']?.toString() ?? '',
            mainText: prediction['structured_formatting'] is Map
                ? (prediction['structured_formatting']['main_text']?.toString())
                : null,
            secondaryText: prediction['structured_formatting'] is Map
                ? (prediction['structured_formatting']['secondary_text']
                      ?.toString())
                : null,
          ),
        )
        .where(
          (prediction) =>
              prediction.description.isNotEmpty &&
              prediction.placeId.isNotEmpty,
        )
        .toList(growable: false);
  }

  static Future<GooglePlaceDetails?> placeDetails(
    String placeId, {
    String language = 'id',
  }) async {
    final safePlaceId = placeId.trim();
    if (safePlaceId.isEmpty) return null;

    final apiKey = await _resolveApiKey();
    if (apiKey == null || apiKey.isEmpty) return null;

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/details/json',
      <String, String>{
        'place_id': safePlaceId,
        'key': apiKey,
        'language': language,
        'fields': 'place_id,formatted_address,name,geometry',
      },
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) return null;

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return null;

    if (decoded['status'] != 'OK') return null;

    final result = decoded['result'];
    if (result is! Map<String, dynamic>) return null;

    final formattedAddress = result['formatted_address']?.toString().trim();
    if (formattedAddress == null || formattedAddress.isEmpty) return null;

    final description = result['name']?.toString().trim().isNotEmpty ?? false
        ? result['name'].toString().trim()
        : formattedAddress;

    return GooglePlaceDetails(
      placeId: result['place_id']?.toString() ?? safePlaceId,
      description: description,
      formattedAddress: formattedAddress,
      name: result['name']?.toString(),
    );
  }
}
