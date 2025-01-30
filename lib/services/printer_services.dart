import 'dart:typed_data';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/services.dart';
import 'package:package_baru/models/receipt_settings.dart';

// Ubah nama enum untuk menghindari konflik
enum ThermalPaperSize {
  mm58, // 58mm
  mm76, // 76mm
  mm80 // 80mm
}

class PrinterService {
  static final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  // Update method helper dengan nama enum baru
  static int _getPaperWidth(ThermalPaperSize size) {
    switch (size) {
      case ThermalPaperSize.mm58:
        return 32; // 32 karakter per baris
      case ThermalPaperSize.mm76:
        return 42; // 42 karakter per baris
      case ThermalPaperSize.mm80:
        return 48; // 48 karakter per baris
    }
  }

  // Mencari printer bluetooth yang tersedia
  static Future<List<BluetoothDevice>> getBluetooths() async {
    final List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
    return devices;
  }

  // Mengecek koneksi printer
  static Future<bool> connectionStatus() async {
    final bool? isConnected = await bluetooth.isConnected;
    return isConnected ?? false;
  }

  // Menghubungkan ke printer
  static Future<void> connect(BluetoothDevice device) async {
    await bluetooth.connect(device);
  }

  // Mencetak struk
  static Future<void> printReceipt({
    required String businessName,
    String? address,
    String? phoneNumber,
    String? email,
    String? website,
    required List<Map<String, dynamic>> items,
    String? cashierName,
    required DateTime date,
    String? invoiceNumber,
    String? footer,
    String? paymentMethod,
    required ReceiptSettings settings,
  }) async {
    try {
      // Cek koneksi printer
      final bool isConnected = await connectionStatus();
      if (!isConnected) {
        throw Exception('Printer tidak terhubung');
      }

      // Inisialisasi generator
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      // Header
      bytes += generator.text(
        businessName.toUpperCase(),
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );

      if (address != null && settings.showAddress) {
        bytes += generator.text(address,
            styles: const PosStyles(align: PosAlign.center));
      }
      if (phoneNumber != null && settings.showPhone) {
        bytes += generator.text('Telp: $phoneNumber',
            styles: const PosStyles(align: PosAlign.center));
      }
      if (email != null && settings.showEmail) {
        bytes += generator.text('Email: $email',
            styles: const PosStyles(align: PosAlign.center));
      }
      if (website != null && settings.showWebsite) {
        bytes += generator.text('Web: $website',
            styles: const PosStyles(align: PosAlign.center));
      }

      bytes += generator.hr();

      // Info Transaksi
      if (settings.showDate) {
        bytes += generator.text('Tanggal: ${_formatDate(date)}');
      }
      if (cashierName != null && settings.showCashier) {
        bytes += generator.text('Kasir: $cashierName');
      }
      if (invoiceNumber != null && settings.showInvoiceNumber) {
        bytes += generator.text('No Invoice: $invoiceNumber');
      }
      if (paymentMethod != null && settings.showPaymentMethod) {
        bytes += generator.text('Pembayaran: $paymentMethod');
      }

      bytes += generator.hr();

      // Items
      bytes += generator.row([
        PosColumn(text: 'Item', width: 4),
        PosColumn(text: 'Qty', width: 2),
        PosColumn(
            text: 'Harga',
            width: 3,
            styles: const PosStyles(align: PosAlign.right)),
        PosColumn(
            text: 'Total',
            width: 3,
            styles: const PosStyles(align: PosAlign.right)),
      ]);

      bytes += generator.hr();

      // Item details
      for (var item in items) {
        bytes += generator.row([
          PosColumn(text: item['name'], width: 4),
          PosColumn(text: '${item['quantity']}x', width: 2),
          PosColumn(
            text: item['price'].toString(),
            width: 3,
            styles: const PosStyles(align: PosAlign.right),
          ),
          PosColumn(
            text: (item['quantity'] * item['price']).toString(),
            width: 3,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);

        if (item['note'] != null && settings.showItemNotes) {
          bytes += generator.text(
            'Note: ${item['note']}',
            styles: const PosStyles(),
          );
        }
      }

      bytes += generator.hr();

      // Total
      final total = items.fold<double>(
        0,
        (sum, item) => sum + (item['quantity'] * item['price']),
      );

      bytes += generator.row([
        PosColumn(
          text: 'TOTAL',
          width: 6,
          styles: const PosStyles(bold: true),
        ),
        PosColumn(
          text: 'Rp ${total.toStringAsFixed(0)}',
          width: 6,
          styles: const PosStyles(bold: true, align: PosAlign.right),
        ),
      ]);

      // Footer
      if (footer != null && settings.showFooter) {
        bytes += generator.hr();
        bytes += generator.text(
          footer,
          styles: const PosStyles(align: PosAlign.center),
        );
      }

      bytes += generator.hr();
      bytes += generator.cut();

      // Convert List<int> ke Uint8List sebelum print
      final Uint8List uint8bytes = Uint8List.fromList(bytes);

      // Print
      await bluetooth.writeBytes(uint8bytes);
    } catch (e) {
      rethrow;
    }
  }

  // Mencetak struk untuk iPOS printer
  static Future<void> printReceiptIPOS({
    required String businessName,
    String? address,
    String? phoneNumber,
    String? email,
    String? website,
    required List<Map<String, dynamic>> items,
    String? cashierName,
    required DateTime date,
    String? invoiceNumber,
    String? footer,
    String? paymentMethod,
    ThermalPaperSize paperSize = ThermalPaperSize.mm58, // Update default value
    required ReceiptSettings settings,
  }) async {
    try {
      final bool isConnected = await connectionStatus();
      if (!isConnected) {
        throw Exception('Printer tidak terhubung');
      }

      // Update pemanggilan method
      final int paperWidth = _getPaperWidth(paperSize);

      List<int> bytes = [];

      // Reset printer
      bytes += [0x1B, 0x40]; // ESC @

      // Set margin kiri (opsional)
      bytes += [0x1B, 0x6C, 0]; // ESC l n (left margin = 0)

      // Set lebar area print
      bytes += [0x1B, 0x57, paperWidth, 0]; // ESC W nL nH

      // Atur alignment center untuk header
      bytes += [0x1B, 0x61, 0x01]; // ESC a 1

      // Header dengan ukuran double
      bytes += [0x1D, 0x21, 0x11]; // GS ! 17 (double width & height)
      bytes += Uint8List.fromList(businessName.toUpperCase().codeUnits);
      bytes += [0x0A]; // Line feed

      // Reset ukuran text
      bytes += [0x1D, 0x21, 0x00]; // GS ! 0

      // Info alamat dan kontak
      if (address != null && settings.showAddress) {
        bytes += Uint8List.fromList(address.codeUnits);
        bytes += [0x0A];
      }
      if (phoneNumber != null && settings.showPhone) {
        bytes += Uint8List.fromList('Telp: $phoneNumber'.codeUnits);
        bytes += [0x0A];
      }
      if (email != null && settings.showEmail) {
        bytes += Uint8List.fromList('Email: $email'.codeUnits);
        bytes += [0x0A];
      }
      if (website != null && settings.showWebsite) {
        bytes += Uint8List.fromList('Web: $website'.codeUnits);
        bytes += [0x0A];
      }

      // Garis pembatas
      bytes += [0x1B, 0x61, 0x01]; // Center align
      bytes += Uint8List.fromList(('=' * paperWidth).codeUnits);
      bytes += [0x0A];

      // Align left untuk info transaksi
      bytes += [0x1B, 0x61, 0x00]; // ESC a 0

      // Info transaksi
      if (settings.showDate) {
        bytes += Uint8List.fromList('Tanggal: ${_formatDate(date)}'.codeUnits);
        bytes += [0x0A];
      }
      if (cashierName != null && settings.showCashier) {
        bytes += Uint8List.fromList('Kasir: $cashierName'.codeUnits);
        bytes += [0x0A];
      }
      if (invoiceNumber != null && settings.showInvoiceNumber) {
        bytes += Uint8List.fromList('No Invoice: $invoiceNumber'.codeUnits);
        bytes += [0x0A];
      }
      if (paymentMethod != null && settings.showPaymentMethod) {
        bytes += Uint8List.fromList('Pembayaran: $paymentMethod'.codeUnits);
        bytes += [0x0A];
      }

      // Garis pembatas
      bytes += Uint8List.fromList(('-' * paperWidth).codeUnits);
      bytes += [0x0A];

      // Sesuaikan format header item dengan lebar kertas
      int itemWidth = (paperWidth * 0.45).floor(); // 45% untuk nama item
      int qtyWidth = (paperWidth * 0.15).floor(); // 15% untuk qty
      int priceWidth = (paperWidth * 0.20).floor(); // 20% untuk harga
      int totalWidth =
          paperWidth - itemWidth - qtyWidth - priceWidth; // 20% untuk total

      // Header dengan format yang lebih rapi
      String header = 'ITEM'.padRight(itemWidth) +
          'QTY'.padRight(qtyWidth) +
          'HARGA'.padLeft(priceWidth) +
          'TOTAL'.padLeft(totalWidth);
      bytes += Uint8List.fromList(header.codeUnits);
      bytes += [0x0A];
      bytes += Uint8List.fromList(('-' * paperWidth).codeUnits);
      bytes += [0x0A];

      // Items dengan format yang lebih rapi
      double total = 0;
      for (var item in items) {
        String name = item['name'].toString();
        if (name.length > itemWidth) {
          name = name.substring(0, itemWidth - 3) + '...';
        } else {
          name = name.padRight(itemWidth);
        }

        int qty = item['quantity'] as int;
        double price = item['price'] as double;
        double subtotal = qty * price;
        total += subtotal;

        // Format angka dengan pemisah ribuan
        String priceStr = _formatCurrency(price);
        String subtotalStr = _formatCurrency(subtotal);

        String line = name +
            qty.toString().padRight(qtyWidth) +
            priceStr.padLeft(priceWidth) +
            subtotalStr.padLeft(totalWidth);
        bytes += Uint8List.fromList(line.codeUnits);
        bytes += [0x0A];

        // Note dengan indent yang lebih rapi
        if (item['note'] != null && settings.showItemNotes) {
          String note = '  Note: ${item['note']}';
          if (note.length > paperWidth) {
            note = note.substring(0, paperWidth - 3) + '...';
          }
          bytes += Uint8List.fromList(note.codeUnits);
          bytes += [0x0A];
        }
      }

      bytes += Uint8List.fromList(('-' * paperWidth).codeUnits);
      bytes += [0x0A];

      // Total dengan format yang lebih rapi
      bytes += [0x1B, 0x45, 0x01]; // Bold on
      String totalStr = _formatCurrency(total);
      String totalLine =
          'TOTAL:'.padRight(paperWidth - totalStr.length) + totalStr;
      bytes += Uint8List.fromList(totalLine.codeUnits);
      bytes += [0x1B, 0x45, 0x00]; // Bold off
      bytes += [0x0A];

      // Footer
      if (footer != null && settings.showFooter) {
        bytes += [0x1B, 0x61, 0x01]; // Center align
        bytes += Uint8List.fromList(('=' * paperWidth).codeUnits);
        bytes += [0x0A];
        bytes += Uint8List.fromList(footer.codeUnits);
        bytes += [0x0A];
      }

      // Akhiri dengan beberapa line feed dan cut
      bytes += [0x0A, 0x0A, 0x0A, 0x0A];
      bytes += [0x1D, 0x56, 0x41, 0x10]; // GS V A 16 (cut paper)

      // Print
      await bluetooth.writeBytes(Uint8List.fromList(bytes));
    } catch (e) {
      rethrow;
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Helper method untuk format currency
  static String _formatCurrency(double value) {
    String price = value.toStringAsFixed(0);
    String result = '';
    int count = 0;

    // Format dari belakang dengan pemisah ribuan
    for (int i = price.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        result = '.' + result;
      }
      result = price[i] + result;
      count++;
    }

    return result;
  }

  // Method untuk disconnect dari printer
  static Future<void> disconnect() async {
    await bluetooth.disconnect();
  }
}
