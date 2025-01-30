import 'package:flutter/material.dart';
import 'package:package_baru/models/receipt_item.dart';
import 'package:package_baru/models/receipt_simulation.dart';

class ReceiptSimulationScreen extends StatefulWidget {
  final Function(ReceiptSimulation) onSimulationCreated;

  const ReceiptSimulationScreen({
    Key? key,
    required this.onSimulationCreated,
  }) : super(key: key);

  @override
  State<ReceiptSimulationScreen> createState() =>
      _ReceiptSimulationScreenState();
}

class _ReceiptSimulationScreenState extends State<ReceiptSimulationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _simulation = ReceiptSimulation();
  final List<ReceiptItem> _items = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulasi Struk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveSimulation,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Informasi Bisnis
            const Text(
              'Informasi Bisnis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Nama Bisnis *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama bisnis harus diisi';
                }
                return null;
              },
              onSaved: (value) => _simulation.businessName = value!,
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Alamat',
                border: OutlineInputBorder(),
              ),
              onSaved: (value) => _simulation.address = value,
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'No. Telepon',
                border: OutlineInputBorder(),
              ),
              onSaved: (value) => _simulation.phoneNumber = value,
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              onSaved: (value) => _simulation.email = value,
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Website',
                border: OutlineInputBorder(),
              ),
              onSaved: (value) => _simulation.website = value,
            ),

            const SizedBox(height: 16),
            // Informasi Transaksi
            const Text(
              'Informasi Transaksi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Nama Kasir',
                border: OutlineInputBorder(),
              ),
              onSaved: (value) => _simulation.cashierName = value,
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'No Invoice',
                border: OutlineInputBorder(),
              ),
              onSaved: (value) => _simulation.invoiceNumber = value,
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Metode Pembayaran',
                border: OutlineInputBorder(),
              ),
              onSaved: (value) => _simulation.paymentMethod = value,
            ),

            const SizedBox(height: 16),
            // Items
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Items',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Item'),
                  onPressed: _showAddItemDialog,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._buildItemsList(),

            const SizedBox(height: 16),
            // Footer
            const Text(
              'Footer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Footer Text',
                border: OutlineInputBorder(),
              ),
              onSaved: (value) => _simulation.footer = value,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildItemsList() {
    return _items.map((item) {
      return Card(
        child: ListTile(
          title: Text(item.name),
          subtitle: Text('${item.quantity}x @ ${item.price}'),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              setState(() {
                _items.remove(item);
              });
            },
          ),
        ),
      );
    }).toList();
  }

  void _showAddItemDialog() {
    String name = '';
    int quantity = 1;
    double price = 0;
    String? note;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Nama Item'),
              onChanged: (value) => name = value,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Jumlah'),
              keyboardType: TextInputType.number,
              onChanged: (value) => quantity = int.tryParse(value) ?? 1,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Harga'),
              keyboardType: TextInputType.number,
              onChanged: (value) => price = double.tryParse(value) ?? 0,
            ),
            TextField(
              decoration:
                  const InputDecoration(labelText: 'Catatan (opsional)'),
              onChanged: (value) => note = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Tambah'),
            onPressed: () {
              setState(() {
                _items.add(ReceiptItem(
                  name: name,
                  quantity: quantity,
                  price: price,
                  note: note,
                ));
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _saveSimulation() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      _simulation.items = _items;
      widget.onSimulationCreated(_simulation);
      Navigator.pop(context);
    }
  }
}
