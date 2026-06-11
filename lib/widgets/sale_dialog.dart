import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/item.dart';
import '../models/sale.dart';

class SaleDialog extends StatefulWidget {
  final Item item;

  const SaleDialog({super.key, required this.item});

  @override
  State<SaleDialog> createState() => _SaleDialogState();
}

class _SaleDialogState extends State<SaleDialog> {
  final _db = DatabaseHelper();
  final _qtyController = TextEditingController(text: '1');
  final _customerController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isDebt = false;
  String? _error;

  double get _total {
    final qty = double.tryParse(_qtyController.text) ?? 0;
    return qty * widget.item.sellingPrice;
  }

  Future<void> _sell({required bool isPaid}) async {
    final qty = double.tryParse(_qtyController.text);
    if (qty == null || qty <= 0) {
      setState(() => _error = 'Andika umubare');
      return;
    }

    if (!isPaid && _customerController.text.trim().isEmpty) {
      setState(() => _error = 'Andika izina ry\'umukiriya');
      return;
    }

    final sale = Sale(
      itemId: widget.item.id!,
      quantity: qty,
      totalPrice: _total,
      isPaid: isPaid,
      customerName: isPaid ? null : _customerController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    await _db.insertSale(sale);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _qtyController.dispose();
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
          Text(
            widget.item.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Text(
            '${widget.item.sellingPrice.toStringAsFixed(0)} Frw / ${Item.modeLabel(widget.item.sellingMode)}',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _qtyController,
            decoration: const InputDecoration(labelText: 'Ingano'),
            style: const TextStyle(fontSize: 22),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: 8),
          Text(
            'Igiteranyo: ${_total.toStringAsFixed(0)} Frw',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          if (_isDebt) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _customerController,
              decoration: const InputDecoration(labelText: "Izina ry'umukiriya"),
              style: const TextStyle(fontSize: 18),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() => _error = null),
            ),
          ],
          const SizedBox(height: 12),
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
                    onPressed: () => _sell(isPaid: true),
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
                        _sell(isPaid: false);
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
