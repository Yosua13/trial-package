import 'package:flutter/services.dart';

class PackageBaru {
  static const MethodChannel _channel = MethodChannel('package_baru');

  // Fungsi untuk mendeteksi perangkat Bluetooth di sekitar
  static Future<List<String>> scanBluetoothDevices() async {
    try {
      final List<dynamic> devices =
          await _channel.invokeMethod('scanBluetoothDevices');
      return devices.map((device) => device.toString()).toList();
    } on PlatformException catch (e) {
      throw Exception("Failed to scan Bluetooth devices: ${e.message}");
    }
  }

  // Fungsi untuk menghubungkan ke printer Bluetooth
  static Future<String> connectBluetoothPrinter(String address) async {
    try {
      final String result = await _channel
          .invokeMethod('connectBluetoothPrinter', {'address': address});
      return result;
    } on PlatformException catch (e) {
      return "Failed to connect to printer: ${e.message}";
    }
  }

  // Fungsi untuk mencetak struk
  static Future<String> printReceipt(String data) async {
    try {
      final String result =
          await _channel.invokeMethod('printReceipt', {'data': data});
      return result;
    } on PlatformException catch (e) {
      return "Failed to print receipt: ${e.message}";
    }
  }
}
