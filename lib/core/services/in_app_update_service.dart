import 'dart:io';

import 'package:in_app_update/in_app_update.dart';

class InAppUpdateService {
  static Future<void> checkAndUpdate({bool immediate = false}) async {
    if (!Platform.isAndroid) return;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (immediate) {
          await InAppUpdate.performImmediateUpdate();
        } else {
          await InAppUpdate.startFlexibleUpdate();
          await InAppUpdate.completeFlexibleUpdate();
        }
      }
    } catch (_) {
      // swallow errors to avoid crashing; updates are best-effort
    }
  }
}
