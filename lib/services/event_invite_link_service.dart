class EventInviteLinkService {
  static const String scheme = 'connext';
  static const String host = 'join-event';
  static const String universalScheme = 'https';
  static const String universalHost = 'connext-ppkd.web.app';
  static const String universalHostAlt = 'connext-ppkd.firebaseapp.com';
  static const String legacyUniversalHost = 'connext.app';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.ppkd.connext';

  static Uri buildJoinEventUri(int eventId) {
    return Uri(
      scheme: universalScheme,
      host: universalHost,
      path: '/j/$eventId',
    );
  }

  static Uri buildDirectAppUri(int eventId) {
    return Uri(
      scheme: scheme,
      host: host,
      queryParameters: {'eventId': eventId.toString()},
    );
  }

  static Uri buildPlayStoreUri() => Uri.parse(playStoreUrl);

  static int? parseEventId(Uri uri) {
    final isCustomScheme = uri.scheme == scheme && uri.host == host;

    final isUniversalLink =
        uri.scheme == universalScheme &&
        (uri.host == universalHost ||
            uri.host == universalHostAlt ||
            uri.host == legacyUniversalHost);

    if (!isCustomScheme && !isUniversalLink) return null;

    final eventIdFromQuery = uri.queryParameters['eventId'];
    final parsedQueryId = int.tryParse(eventIdFromQuery ?? '');
    if (parsedQueryId != null && parsedQueryId > 0) return parsedQueryId;

    if (uri.pathSegments.isNotEmpty) {
      if (uri.pathSegments.length >= 2 && uri.pathSegments.first == 'j') {
        final parsedPathId = int.tryParse(uri.pathSegments[1]);
        if (parsedPathId != null && parsedPathId > 0) return parsedPathId;
      }

      if (uri.pathSegments.length >= 2 &&
          uri.pathSegments.first == 'join-event') {
        final parsedPathId = int.tryParse(uri.pathSegments[1]);
        if (parsedPathId != null && parsedPathId > 0) return parsedPathId;
      }

      final parsedFirstSegmentId = int.tryParse(uri.pathSegments.first);
      if (parsedFirstSegmentId != null && parsedFirstSegmentId > 0) {
        return parsedFirstSegmentId;
      }
    }

    return null;
  }

  static bool isJoinEventUri(Uri uri) => parseEventId(uri) != null;
}
