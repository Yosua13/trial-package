import 'package:package_baru/models/receipt_item.dart';

class ReceiptSimulation {
  String businessName;
  String? address;
  String? phoneNumber;
  String? email;
  String? website;
  String? cashierName;
  String? invoiceNumber;
  String? paymentMethod;
  String? footer;
  List<ReceiptItem> items;

  ReceiptSimulation({
    this.businessName = '',
    this.address,
    this.phoneNumber,
    this.email,
    this.website,
    this.cashierName,
    this.invoiceNumber,
    this.paymentMethod,
    this.footer,
    this.items = const [],
  });
}
