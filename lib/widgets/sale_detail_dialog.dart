import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/sale.dart';

class SaleDetailDialog extends StatelessWidget {
  final Sale sale;

  const SaleDetailDialog({super.key, required this.sale});

  Future<void> _delete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Siba'),
        content: const Text('Urashaka gusiba iyi transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('OYA'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('YEGO, SIBA'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper().deleteSale(sale.id!);
      if (context.mounted) Navigator.pop(context, 'deleted');
    }
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              sale.itemName ?? 'Igicuruzwa',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          _DetailRow(
            label: 'Ingano',
            value: 'x${sale.quantity.toStringAsFixed(sale.quantity == sale.quantity.roundToDouble() ? 0 : 1)}',
          ),
          _DetailRow(
            label: 'Igiciro cyose',
            value: '${sale.totalPrice.toStringAsFixed(0)} Frw',
          ),
          _DetailRow(
            label: 'Imimerere',
            value: sale.isPaid ? 'Byishyuwe' : 'Ideni',
            valueColor: sale.isPaid ? Colors.green : Colors.orange,
          ),
          if (sale.customerName != null)
            _DetailRow(label: 'Umukiriya', value: sale.customerName!),
          _DetailRow(label: 'Itariki', value: _formatDate(sale.createdAt)),
          if (sale.notes != null) ...[
            const SizedBox(height: 8),
            const Text(
              'Icyitonderwa:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              sale.notes!,
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black87,
                    ),
                    child: const Text('FUNGA'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _delete(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('SIBA'),
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
