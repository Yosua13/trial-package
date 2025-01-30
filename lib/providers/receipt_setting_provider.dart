import 'package:flutter/foundation.dart';
import 'package:package_baru/models/receipt_settings.dart';

class ReceiptSettingsProvider extends ChangeNotifier {
  ReceiptSettings _settings = ReceiptSettings();

  ReceiptSettings get settings => _settings;

  void updateSettings(ReceiptSettings newSettings) {
    _settings = newSettings;
    notifyListeners();
  }
}
