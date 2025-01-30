import 'package:flutter/material.dart';
import 'package:package_baru/models/receipt_settings.dart';

class ReceiptSettingsScreen extends StatefulWidget {
  final ReceiptSettings settings;
  final Function(ReceiptSettings) onSettingsChanged;

  const ReceiptSettingsScreen({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  State<ReceiptSettingsScreen> createState() => _ReceiptSettingsScreenState();
}

class _ReceiptSettingsScreenState extends State<ReceiptSettingsScreen> {
  late bool showLogo;
  late bool showAddress;
  late bool showPhone;
  late bool showEmail;
  late bool showWebsite;
  late bool showInvoiceNumber;
  late bool showCashier;
  late bool showPaymentMethod;
  late bool showItemNotes;
  late bool showFooter;
  late bool showDate;

  @override
  void initState() {
    super.initState();
    // Inisialisasi nilai dari settings yang ada
    showLogo = widget.settings.showLogo;
    showAddress = widget.settings.showAddress;
    showPhone = widget.settings.showPhone;
    showEmail = widget.settings.showEmail;
    showWebsite = widget.settings.showWebsite;
    showInvoiceNumber = widget.settings.showInvoiceNumber;
    showCashier = widget.settings.showCashier;
    showPaymentMethod = widget.settings.showPaymentMethod;
    showItemNotes = widget.settings.showItemNotes;
    showFooter = widget.settings.showFooter;
    showDate = widget.settings.showDate;
  }

  void _updateSettings() {
    final newSettings = ReceiptSettings(
      showLogo: showLogo,
      showAddress: showAddress,
      showPhone: showPhone,
      showEmail: showEmail,
      showWebsite: showWebsite,
      showInvoiceNumber: showInvoiceNumber,
      showCashier: showCashier,
      showPaymentMethod: showPaymentMethod,
      showItemNotes: showItemNotes,
      showFooter: showFooter,
      showDate: showDate,
    );
    widget.onSettingsChanged(newSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Struk'),
      ),
      body: ListView(
        children: [
          _buildSettingSection(
            title: 'Header',
            children: [
              _buildSwitchTile(
                title: 'Tampilkan Logo',
                value: showLogo,
                onChanged: (value) {
                  setState(() {
                    showLogo = value;
                    _updateSettings();
                  });
                },
              ),
              _buildSwitchTile(
                title: 'Tampilkan Alamat',
                value: showAddress,
                onChanged: (value) {
                  setState(() {
                    showAddress = value;
                    _updateSettings();
                  });
                },
              ),
              _buildSwitchTile(
                title: 'Tampilkan No. Telepon',
                value: showPhone,
                onChanged: (value) {
                  setState(() {
                    showPhone = value;
                    _updateSettings();
                  });
                },
              ),
              _buildSwitchTile(
                title: 'Tampilkan Email',
                value: showEmail,
                onChanged: (value) {
                  setState(() {
                    showEmail = value;
                    _updateSettings();
                  });
                },
              ),
              _buildSwitchTile(
                title: 'Tampilkan Website',
                value: showWebsite,
                onChanged: (value) {
                  setState(() {
                    showWebsite = value;
                    _updateSettings();
                  });
                },
              ),
            ],
          ),
          _buildSettingSection(
            title: 'Informasi Transaksi',
            children: [
              _buildSwitchTile(
                title: 'Tampilkan Tanggal',
                value: showDate,
                onChanged: (value) {
                  setState(() {
                    showDate = value;
                    _updateSettings();
                  });
                },
              ),
              _buildSwitchTile(
                title: 'Tampilkan No. Invoice',
                value: showInvoiceNumber,
                onChanged: (value) {
                  setState(() {
                    showInvoiceNumber = value;
                    _updateSettings();
                  });
                },
              ),
              _buildSwitchTile(
                title: 'Tampilkan Kasir',
                value: showCashier,
                onChanged: (value) {
                  setState(() {
                    showCashier = value;
                    _updateSettings();
                  });
                },
              ),
              _buildSwitchTile(
                title: 'Tampilkan Metode Pembayaran',
                value: showPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    showPaymentMethod = value;
                    _updateSettings();
                  });
                },
              ),
            ],
          ),
          _buildSettingSection(
            title: 'Detail Item',
            children: [
              _buildSwitchTile(
                title: 'Tampilkan Catatan Item',
                value: showItemNotes,
                onChanged: (value) {
                  setState(() {
                    showItemNotes = value;
                    _updateSettings();
                  });
                },
              ),
            ],
          ),
          _buildSettingSection(
            title: 'Footer',
            children: [
              _buildSwitchTile(
                title: 'Tampilkan Footer',
                value: showFooter,
                onChanged: (value) {
                  setState(() {
                    showFooter = value;
                    _updateSettings();
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}
