class ReceiptItem {
  final String name;
  final int quantity;
  final double price;
  final String? note;

  ReceiptItem({
    required this.name,
    required this.quantity,
    required this.price,
    this.note,
  });
}
