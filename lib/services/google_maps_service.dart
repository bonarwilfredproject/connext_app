import 'package:url_launcher/url_launcher.dart';

String buildGoogleMapsSearchUrl(String location, {String? placeId}) {
  final safeLocation = location.trim();
  if (safeLocation.isEmpty) return '';

  final safePlaceId = placeId?.trim();
  if (safePlaceId != null && safePlaceId.isNotEmpty) {
    return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(safeLocation)}&query_place_id=${Uri.encodeComponent(safePlaceId)}';
  }

  return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(safeLocation)}';
}

Future<bool> openGoogleMapsLocation({
  required String location,
  String? locationUrl,
  String? placeId,
}) async {
  final targetUrl = (locationUrl?.trim().isNotEmpty ?? false)
      ? locationUrl!.trim()
      : buildGoogleMapsSearchUrl(location, placeId: placeId);

  if (targetUrl.isEmpty) return false;

  final uri = Uri.parse(targetUrl);
  try {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened) return true;

    return await launchUrl(uri, mode: LaunchMode.platformDefault);
  } catch (_) {
    return false;
  }
}
