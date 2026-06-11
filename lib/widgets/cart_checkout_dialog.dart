import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/item.dart';
import '../models/sale.dart';

class CartCheckoutDialog extends StatefulWidget {
  final Map<Item, double> cart;
  final Map<int, double> priceOverrides;

  const CartCheckoutDialog({super.key, required this.cart, this.priceOverrides = const {}});

  @override
  State<CartCheckoutDialog> createState() => _CartCheckoutDialogState();
}

class _CartCheckoutDialogState extends State<CartCheckoutDialog> {
  final _db = DatabaseHelper();
  final _customerController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isDebt = false;
  String? _error;

  double _getPrice(Item item) {
    return widget.priceOverrides[item.id!] ?? item.sellingPrice;
  }

  double get _total {
    double sum = 0;
    for (final entry in widget.cart.entries) {
      sum += _getPrice(entry.key) * entry.value;
    }
    return sum;
  }

  Future<void> _confirm({required bool isPaid}) async {
    if (!isPaid && _customerController.text.trim().isEmpty) {
      setState(() => _error = "Andika izina ry'umukiriya");
      return;
    }

    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();
    final customerName = isPaid ? null : _customerController.text.trim();

    for (final entry in widget.cart.entries) {
      final item = entry.key;
      final qty = entry.value;
      final sale = Sale(
        itemId: item.id!,
        quantity: qty,
        totalPrice: _getPrice(item) * qty,
        isPaid: isPaid,
        customerName: customerName,
        notes: notes,
      );
      await _db.insertSale(sale);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _customerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ibyo ugurishije',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // Cart items summary
          ...widget.cart.entries.map((entry) {
            final item = entry.key;
            final qty = entry.value;
            final lineTotal = _getPrice(item) * qty;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  Text(
                    'x${qty.toStringAsFixed(qty == qty.roundToDouble() ? 0 : 1)}',
                    style: const TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${lineTotal.toStringAsFixed(0)} Frw',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 20),
          Text(
            'Igiteranyo: ${_total.toStringAsFixed(0)} Frw',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (_isDebt) ...[
            TextField(
              controller: _customerController,
              decoration: const InputDecoration(labelText: "Izina ry'umukiriya"),
              style: const TextStyle(fontSize: 18),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Icyitonderwa (ntibisabwa)',
              hintText: 'Andika icyitonderwa...',
            ),
            style: const TextStyle(fontSize: 16),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 14)),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _confirm(isPaid: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('BYISHYUWE'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!_isDebt) {
                        setState(() => _isDebt = true);
                      } else {
                        _confirm(isPaid: false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('IDENI'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
