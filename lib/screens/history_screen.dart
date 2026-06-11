import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/sale.dart';
import '../widgets/sale_detail_dialog.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _db = DatabaseHelper();
  List<Sale> _sales = [];
  int _filter = 0; // 0=all, 1=paid, 2=debt
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    final bool? isPaid;
    switch (_filter) {
      case 1:
        isPaid = true;
        break;
      case 2:
        isPaid = false;
        break;
      default:
        isPaid = null;
    }
    final sales = await _db.getSales(isPaid: isPaid, from: _fromDate, to: _toDate);
    setState(() => _sales = sales);
  }

  double get _totalForRange {
    return _sales.fold(0, (sum, s) => sum + s.totalPrice);
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: now,
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      helpText: 'Hitamo amatariki',
      cancelText: 'HAGARIKA',
      confirmText: 'EMEZA',
      saveText: 'BIKA',
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      _loadSales();
    }
  }

  void _clearDateRange() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
    _loadSales();
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatShortDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ibyacurujwe'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: Icon(
              Icons.date_range,
              color: _fromDate != null ? Colors.green : null,
            ),
            onPressed: _pickDateRange,
          ),
        ],
      ),
      body: Column(
        children: [
          // Date range indicator
          if (_fromDate != null && _toDate != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.green.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_formatShortDate(_fromDate!)} - ${_formatShortDate(_toDate!)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '${_totalForRange.toStringAsFixed(0)} Frw',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _clearDateRange,
                    child: const Icon(Icons.close, size: 20, color: Colors.grey),
                  ),
                ],
              ),
            ),
          // Filter chips
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FilterChip(
                  label: 'Byose',
                  selected: _filter == 0,
                  onTap: () {
                    setState(() => _filter = 0);
                    _loadSales();
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Byishyuwe',
                  selected: _filter == 1,
                  onTap: () {
                    setState(() => _filter = 1);
                    _loadSales();
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Amadeni',
                  selected: _filter == 2,
                  onTap: () {
                    setState(() => _filter = 2);
                    _loadSales();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _sales.isEmpty
                ? const Center(
                    child: Text(
                      'Nta mateka',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _sales.length,
                    itemBuilder: (context, index) {
                      final sale = _sales[index];
                      return Card(
                        child: ListTile(
                          onTap: () async {
                            final result = await showModalBottomSheet(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              builder: (_) => SaleDetailDialog(sale: sale),
                            );
                            if (result == 'deleted') _loadSales();
                          },
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          leading: Icon(
                            sale.isPaid ? Icons.check_circle : Icons.schedule,
                            color: sale.isPaid ? Colors.green : Colors.orange,
                            size: 28,
                          ),
                          title: Text(
                            sale.itemName ?? 'Igicuruzwa',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'x${sale.quantity.toStringAsFixed(sale.quantity == sale.quantity.roundToDouble() ? 0 : 1)} • ${_formatDate(sale.createdAt)}'
                                '${sale.customerName != null ? ' • ${sale.customerName}' : ''}',
                                style: const TextStyle(fontSize: 13),
                              ),
                              if (sale.notes != null)
                                Text(
                                  sale.notes!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Text(
                            '${sale.totalPrice.toStringAsFixed(0)} Frw',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: sale.isPaid ? Colors.green : Colors.orange,
                            ),
                          ),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.green : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
