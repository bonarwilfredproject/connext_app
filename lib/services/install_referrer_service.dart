import 'dart:convert';

import 'package:connext_app/services/preferences_services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class InstallReferrerService {
  static const MethodChannel _channel = MethodChannel(
    'connext/install_referrer',
  );

  static Future<bool> hydratePendingJoinEventId() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;

    final pref = PreferenceHandler();
    await pref.init();

    final rawReferrer = await _readRawInstallReferrer();
    if (rawReferrer == null || rawReferrer.isEmpty) return false;

    final lastConsumed = pref.getLastConsumedInstallReferrer();
    if (lastConsumed == rawReferrer) return false;

    final eventId = _parseEventId(rawReferrer);
    if (eventId != null && eventId > 0) {
      await pref.savePendingJoinEventId(eventId);
      await pref.saveLastConsumedInstallReferrer(rawReferrer);
      return true;
    }

    await pref.saveLastConsumedInstallReferrer(rawReferrer);
    return false;
  }

  static Future<String?> _readRawInstallReferrer() async {
    try {
      final raw = await _channel.invokeMethod<String>('getInstallReferrer');
      return raw?.trim();
    } catch (_) {
      return null;
    }
  }

  static int? _parseEventId(String rawReferrer) {
    final normalized = rawReferrer.contains('?')
        ? rawReferrer.split('?').last
        : rawReferrer;

    Map<String, String> query;
    try {
      query = Uri.splitQueryString(normalized, encoding: utf8);
    } catch (_) {
      return null;
    }

    final directId =
        query['eventId'] ?? query['event_id'] ?? query['event'] ?? '';
    final parsedDirectId = int.tryParse(directId);
    if (parsedDirectId != null && parsedDirectId > 0) {
      return parsedDirectId;
    }

    final deepLink = query['deep_link'] ?? query['link'] ?? '';
    if (deepLink.isEmpty) return null;

    try {
      final uri = Uri.parse(deepLink);
      final eventIdFromDeepLink = uri.queryParameters['eventId'];
      final parsedDeepLinkId = int.tryParse(eventIdFromDeepLink ?? '');
      if (parsedDeepLinkId != null && parsedDeepLinkId > 0) {
        return parsedDeepLinkId;
      }
    } catch (_) {
      return null;
    }

    return null;
  }
}
