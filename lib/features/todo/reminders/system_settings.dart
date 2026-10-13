import 'package:flutter/services.dart';

const _channel = MethodChannel('todo/system');

/// Opens the phone's own notification settings for this app. Returns whether
/// the phone could be asked (false on platforms without this page).
Future<bool> openNotificationSettings() async {
  try {
    await _channel.invokeMethod<void>('openNotificationSettings');
    return true;
  } on PlatformException {
    return false;
  } on MissingPluginException {
    return false;
  }
}
