class ReceiptSettings {
  final bool showLogo;
  final bool showAddress;
  final bool showPhone;
  final bool showEmail;
  final bool showWebsite;
  final bool showInvoiceNumber;
  final bool showCashier;
  final bool showPaymentMethod;
  final bool showItemNotes;
  final bool showFooter;
  final bool showDate;

  ReceiptSettings({
    this.showLogo = true,
    this.showAddress = true,
    this.showPhone = true,
    this.showEmail = true,
    this.showWebsite = true,
    this.showInvoiceNumber = true,
    this.showCashier = true,
    this.showPaymentMethod = true,
    this.showItemNotes = true,
    this.showFooter = true,
    this.showDate = true,
  });
}
