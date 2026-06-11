import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/sale.dart';
import '../widgets/sale_detail_dialog.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  final _db = DatabaseHelper();
  List<Sale> _debts = [];
  double _total = 0;

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    final debts = await _db.getSales(isPaid: false);
    final total = await _db.getTotalDebts();
    setState(() {
      _debts = debts;
      _total = total;
    });
  }

  void _markPaid(Sale sale) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kwishyura'),
        content: Text(
          '${sale.customerName ?? "Umukiriya"} yishyuye ${sale.totalPrice.toStringAsFixed(0)} Frw?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('OYA'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('YEGO, BYISHYUWE'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.markSaleAsPaid(sale.id!);
      _loadDebts();
    }
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Amadeni atarishyurwa'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.orange.withValues(alpha: 0.1),
            child: Text(
              'Amadeni yose: ${_total.toStringAsFixed(0)} Frw',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: _debts.isEmpty
                ? const Center(
                    child: Text(
                      'Nta madeni!',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _debts.length,
                    itemBuilder: (context, index) {
                      final sale = _debts[index];
                      return Card(
                        child: ListTile(
                          onLongPress: () async {
                            final result = await showModalBottomSheet(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              builder: (_) => SaleDetailDialog(sale: sale),
                            );
                            if (result == 'deleted') _loadDebts();
                          },
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          title: Text(
                            sale.itemName ?? 'Igicuruzwa',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${sale.customerName ?? "-"} • x${sale.quantity.toStringAsFixed(sale.quantity == sale.quantity.roundToDouble() ? 0 : 1)}',
                                style: const TextStyle(fontSize: 15),
                              ),
                              Text(
                                _formatDate(sale.createdAt),
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${sale.totalPrice.toStringAsFixed(0)} Frw',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _markPaid(sale),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
