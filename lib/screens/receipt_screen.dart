import 'package:flutter/material.dart';
import 'package:package_baru/models/receipt_item.dart';
import 'package:package_baru/models/receipt_settings.dart';
import 'package:package_baru/providers/receipt_setting_provider.dart';
import 'package:package_baru/screens/receipt_setting_screen.dart';
import 'package:package_baru/screens/receipt_simulation_screen.dart';
import 'package:package_baru/services/printer_services.dart';
import 'package:provider/provider.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'dart:async';

// Tambahkan enum untuk tipe printer
enum PrinterType {
  thermal,
  ipos,
}

class ReceiptScreen extends StatefulWidget {
  String businessName;
  String? address;
  String? phoneNumber;
  String? email;
  String? website;
  final ImageProvider? logo;
  List<ReceiptItem> items;
  String? cashierName;
  final DateTime date;
  String? invoiceNumber;
  String? footer;
  String? paymentMethod;
  final double? logoWidth;
  final double? logoHeight;
  final ReceiptSettings settings;

  ReceiptScreen({
    super.key,
    required this.businessName,
    this.address,
    this.phoneNumber,
    this.email,
    this.website,
    this.logo,
    this.items = const [],
    this.cashierName,
    DateTime? date,
    this.invoiceNumber,
    this.footer,
    this.paymentMethod,
    this.logoWidth = 100,
    this.logoHeight = 100,
    ReceiptSettings? settings,
  })  : date = date ?? DateTime.now(),
        settings = settings ?? ReceiptSettings();

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  // Tambahkan StreamController untuk status printer
  Timer? _statusCheckTimer;

  @override
  void initState() {
    super.initState();
    // Cek status printer setiap 2 detik
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {}); // Refresh UI untuk update status
      }
    });
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  // Helper widget untuk status printer
  Widget _buildPrinterStatus() {
    return FutureBuilder<bool>(
      future: PrinterService.connectionStatus(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final bool isConnected = snapshot.data!;
          return Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isConnected ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isConnected ? Icons.print : Icons.print_disabled,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isConnected
                          ? 'Printer Connected'
                          : 'Printer Disconnected',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isConnected) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.bluetooth_disabled),
                  tooltip: 'Disconnect Printer',
                  onPressed: () async {
                    try {
                      await PrinterService.disconnect();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Printer disconnected')),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  },
                ),
              ],
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  String _generatePrintContent() {
    final StringBuffer receipt = StringBuffer();
    const int width = 40; // Lebar struk
    const String line = '========================================';
    const String dashedLine = '----------------------------------------';

    // Fungsi helper untuk center align text
    String centerText(String text) {
      final spaces = width - text.length;
      final leftPad = spaces ~/ 2;
      return text.padLeft(leftPad + text.length).padRight(width);
    }

    // Fungsi helper untuk right align text
    String rightText(String text) {
      return text.padLeft(width);
    }

    // Header
    receipt.writeln(line);
    receipt.writeln(centerText(widget.businessName.toUpperCase()));
    if (widget.address != null && widget.settings.showAddress) {
      receipt.writeln(centerText(widget.address!));
    }
    if (widget.phoneNumber != null && widget.settings.showPhone) {
      receipt.writeln(centerText('Telp: ${widget.phoneNumber}'));
    }
    if (widget.email != null && widget.settings.showEmail) {
      receipt.writeln(centerText('Email: ${widget.email}'));
    }
    if (widget.website != null && widget.settings.showWebsite) {
      receipt.writeln(centerText('Web: ${widget.website}'));
    }
    receipt.writeln(line);

    // Info Transaksi
    if (widget.settings.showDate) {
      receipt.writeln('Tanggal   : ${_formatDate(widget.date)}');
    }
    if (widget.cashierName != null && widget.settings.showCashier) {
      receipt.writeln('Kasir     : ${widget.cashierName}');
    }
    if (widget.invoiceNumber != null && widget.settings.showInvoiceNumber) {
      receipt.writeln('No Invoice: ${widget.invoiceNumber}');
    }
    if (widget.paymentMethod != null && widget.settings.showPaymentMethod) {
      receipt.writeln('Pembayaran: ${widget.paymentMethod}');
    }
    receipt.writeln(dashedLine);

    // Items Header
    receipt.writeln('ITEM                 QTY    HARGA     SUBTOTAL');
    receipt.writeln(dashedLine);

    // Items
    for (var item in widget.items) {
      // Nama item (max 20 karakter)
      final itemName = item.name.length > 20
          ? '${item.name.substring(0, 17)}...'
          : item.name.padRight(20);

      // Format harga dan subtotal
      final price = item.price.toStringAsFixed(0).padLeft(8);
      final subtotal =
          (item.quantity * item.price).toStringAsFixed(0).padLeft(10);

      receipt.writeln(
          '$itemName ${item.quantity.toString().padLeft(3)}x$price$subtotal');

      // Catatan item jika ada
      if (item.note != null && widget.settings.showItemNotes) {
        receipt.writeln('  Note: ${item.note}');
      }
    }
    receipt.writeln(dashedLine);

    // Total
    final total = 'TOTAL: Rp ${_calculateTotal().toStringAsFixed(0)}';
    receipt.writeln(rightText(total));

    // Footer
    if (widget.footer != null && widget.settings.showFooter) {
      receipt.writeln(line);
      receipt.writeln(centerText(widget.footer!));
    }
    receipt.writeln(line);

    return receipt.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Struk'),
        actions: [
          // Tambahkan tombol simulasi
          IconButton(
            icon: const Icon(Icons.edit_note),
            tooltip: 'Simulasi Data',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReceiptSimulationScreen(
                    onSimulationCreated: (simulation) {
                      setState(() {
                        // Update data struk dengan data simulasi
                        widget.businessName = simulation.businessName;
                        widget.address = simulation.address;
                        widget.phoneNumber = simulation.phoneNumber;
                        widget.email = simulation.email;
                        widget.website = simulation.website;
                        widget.cashierName = simulation.cashierName;
                        widget.invoiceNumber = simulation.invoiceNumber;
                        widget.paymentMethod = simulation.paymentMethod;
                        widget.footer = simulation.footer;
                        widget.items = simulation.items;
                      });
                    },
                  ),
                ),
              );
            },
          ),
          // Tambahkan status printer
          _buildPrinterStatus(),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReceiptSettingsScreen(
                    settings: widget.settings,
                    onSettingsChanged: (newSettings) {
                      // Update settings menggunakan provider
                      context
                          .read<ReceiptSettingsProvider>()
                          .updateSettings(newSettings);
                    },
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _showPrinterTypeSelection(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Preview struk dalam card
              Card(
                elevation: 4,
                child: Container(
                  width: 380, // Lebar struk
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Logo
                      if (widget.logo != null && widget.settings.showLogo) ...[
                        Image(
                          image: widget.logo!,
                          width: widget.logoWidth,
                          height: widget.logoHeight,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Header
                      Text(
                        widget.businessName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (widget.address != null && widget.settings.showAddress)
                        Text(
                          widget.address!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(height: 1.5),
                        ),
                      if (widget.phoneNumber != null &&
                          widget.settings.showPhone)
                        Text(
                          'Telp: ${widget.phoneNumber}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(height: 1.5),
                        ),
                      if (widget.email != null && widget.settings.showEmail)
                        Text(
                          'Email: ${widget.email}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(height: 1.5),
                        ),
                      if (widget.website != null && widget.settings.showWebsite)
                        Text(
                          'Web: ${widget.website}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(height: 1.5),
                        ),

                      const Divider(thickness: 1),

                      // Info Transaksi
                      if (widget.settings.showDate)
                        _buildInfoRow('Tanggal', _formatDate(widget.date)),
                      if (widget.cashierName != null &&
                          widget.settings.showCashier)
                        _buildInfoRow('Kasir', widget.cashierName!),
                      if (widget.invoiceNumber != null &&
                          widget.settings.showInvoiceNumber)
                        _buildInfoRow('No Invoice', widget.invoiceNumber!),
                      if (widget.paymentMethod != null &&
                          widget.settings.showPaymentMethod)
                        _buildInfoRow('Pembayaran', widget.paymentMethod!),

                      const Divider(thickness: 1),

                      // Header Items
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: const [
                            Expanded(
                              flex: 4,
                              child: Text(
                                'ITEM',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'QTY',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'HARGA',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'SUBTOTAL',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(thickness: 1),

                      // Items
                      ...widget.items.map((item) => _buildItemRowPreview(item)),

                      const Divider(thickness: 1),

                      // Total
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOTAL',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Rp ${_calculateTotal().toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Footer
                      if (widget.footer != null &&
                          widget.settings.showFooter) ...[
                        const Divider(thickness: 1),
                        const SizedBox(height: 8),
                        Text(
                          widget.footer!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const Text(': '),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildItemRowPreview(ReceiptItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  item.name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text('${item.quantity}x'),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  item.price.toStringAsFixed(0),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  (item.quantity * item.price).toStringAsFixed(0),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        if (item.note != null && widget.settings.showItemNotes)
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Text(
              'Note: ${item.note!}',
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  double _calculateTotal() {
    return widget.items
        .fold(0, (sum, item) => sum + (item.quantity * item.price));
  }

  void _printReceipt(PrinterType type, ThermalPaperSize? paperSize) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Cek koneksi printer
      final bool isConnected = await PrinterService.connectionStatus();
      if (!context.mounted) return;
      Navigator.pop(context); // Tutup loading

      if (type == PrinterType.thermal) {
        if (isConnected) {
          await PrinterService.printReceipt(
            businessName: widget.businessName,
            address: widget.address,
            phoneNumber: widget.phoneNumber,
            email: widget.email,
            website: widget.website,
            items: widget.items
                .map((item) => {
                      'name': item.name,
                      'quantity': item.quantity,
                      'price': item.price,
                      'note': item.note,
                    })
                .toList(),
            cashierName: widget.cashierName,
            date: widget.date,
            invoiceNumber: widget.invoiceNumber,
            footer: widget.footer,
            paymentMethod: widget.paymentMethod,
            settings: widget.settings,
          );
        } else {
          _showPrinterSelection(context, type, null);
          return;
        }
      } else {
        if (isConnected) {
          await PrinterService.printReceiptIPOS(
            businessName: widget.businessName,
            address: widget.address,
            phoneNumber: widget.phoneNumber,
            email: widget.email,
            website: widget.website,
            items: widget.items
                .map((item) => {
                      'name': item.name,
                      'quantity': item.quantity,
                      'price': item.price,
                      'note': item.note,
                    })
                .toList(),
            cashierName: widget.cashierName,
            date: widget.date,
            invoiceNumber: widget.invoiceNumber,
            footer: widget.footer,
            paymentMethod: widget.paymentMethod,
            settings: widget.settings,
            paperSize: paperSize!,
          );
        } else {
          _showPrinterSelection(context, type, paperSize);
          return;
        }
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Struk berhasil dicetak')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _showPrinterTypeSelection(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Tipe Printer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Thermal Printer'),
              onTap: () {
                Navigator.pop(context);
                _printReceipt(PrinterType.thermal, null);
              },
            ),
            ListTile(
              title: const Text('iPOS Printer'),
              onTap: () {
                Navigator.pop(context);
                _showPaperSizeSelection(context, PrinterType.ipos);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPaperSizeSelection(BuildContext context, PrinterType type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Ukuran Kertas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('58mm'),
              onTap: () {
                Navigator.pop(context);
                _printReceipt(type, ThermalPaperSize.mm58);
              },
            ),
            ListTile(
              title: const Text('76mm'),
              onTap: () {
                Navigator.pop(context);
                _printReceipt(type, ThermalPaperSize.mm76);
              },
            ),
            ListTile(
              title: const Text('80mm'),
              onTap: () {
                Navigator.pop(context);
                _printReceipt(type, ThermalPaperSize.mm80);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPrinterSelection(
    BuildContext context,
    PrinterType type,
    ThermalPaperSize? paperSize,
  ) async {
    try {
      final List<BluetoothDevice> devices =
          await PrinterService.getBluetooths();
      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Pilih Printer'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: devices.length,
              itemBuilder: (context, index) {
                return ListTile(
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );

                      await PrinterService.connect(devices[index]);
                      if (!context.mounted) return;
                      Navigator.pop(context);

                      // Setelah terkoneksi, langsung print
                      _printReceipt(type, paperSize);
                    } catch (e) {
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  },
                  title: Text(devices[index].name ?? 'Unknown'),
                  subtitle: Text(devices[index].address ?? ''),
                );
              },
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}
