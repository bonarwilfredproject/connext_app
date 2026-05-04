import 'package:connext_app/services/event_invite_link_service.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateGuardService {
  static Future<bool> blockInviteNavigationIfUpdateRequired() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    try {
      final info = await InAppUpdate.checkForUpdate();
      final updateAvailable =
          info.updateAvailability == UpdateAvailability.updateAvailable ||
          info.updateAvailability ==
              UpdateAvailability.developerTriggeredUpdateInProgress;

      if (!updateAvailable) {
        return false;
      }

      if (info.immediateUpdateAllowed) {
        try {
          await InAppUpdate.performImmediateUpdate();
        } catch (_) {
          await _openPlayStore();
        }
        return true;
      }

      await _openPlayStore();
      return true;
    } catch (_) {
      // On debug builds / non-Play installs this plugin can throw.
      return false;
    }
  }

  static Future<void> _openPlayStore() async {
    final uri = EventInviteLinkService.buildPlayStoreUri();
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
