import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/item.dart';
import '../widgets/cart_checkout_dialog.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _db = DatabaseHelper();
  final _searchController = TextEditingController();
  List<Item> _items = [];
  List<int> _topItemIds = [];
  String _searchQuery = '';
  final Map<int, double> _cart = {};
  final Map<int, double> _priceOverrides = {};

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    final items = await _db.getItems();
    final topIds = await _db.getTopSellingItemIds(limit: 10);
    setState(() {
      _items = items;
      _topItemIds = topIds;
    });
  }

  List<Item> get _filteredItems {
    if (_searchQuery.isEmpty) return _items;
    final q = _searchQuery.toLowerCase();
    return _items.where((i) => i.name.toLowerCase().contains(q)).toList();
  }

  List<Item> get _topItems {
    if (_searchQuery.isNotEmpty) return [];
    return _topItemIds
        .map((id) => _items.cast<Item?>().firstWhere((i) => i?.id == id, orElse: () => null))
        .whereType<Item>()
        .toList();
  }

  void _addToCart(Item item, [double amount = 1]) {
    setState(() {
      _cart[item.id!] = (_cart[item.id!] ?? 0) + amount;
    });
  }

  void _removeFromCart(Item item, [double amount = 1]) {
    setState(() {
      final current = _cart[item.id!] ?? 0;
      final newQty = current - amount;
      if (newQty <= 0.01) {
        _cart.remove(item.id!);
        _priceOverrides.remove(item.id!);
      } else {
        _cart[item.id!] = newQty;
      }
    });
  }

  void _showFractionPicker(Item item) {
    final unit = item.unitLabel ?? 'Igice';
    final customController = TextEditingController();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              '${item.sellingPrice.toStringAsFixed(0)} Frw / $unit',
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _QuickBtn(label: 'Irobo\n(¼)', onTap: () { _addToCart(item, 0.25); Navigator.pop(ctx); }),
                const SizedBox(width: 10),
                _QuickBtn(label: 'Inusu\n(½)', onTap: () { _addToCart(item, 0.5); Navigator.pop(ctx); }),
                const SizedBox(width: 10),
                _QuickBtn(label: '1\n$unit', onTap: () { _addToCart(item, 1); Navigator.pop(ctx); }),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: customController,
                    decoration: InputDecoration(
                      labelText: 'Ingano y\'$unit',
                      hintText: 'Urugero: 2.5',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    final val = double.tryParse(customController.text);
                    if (val != null && val > 0) {
                      _addToCart(item, val);
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(60, 48),
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _getItemPrice(Item item) {
    return _priceOverrides[item.id!] ?? item.sellingPrice;
  }

  double get _cartTotal {
    double total = 0;
    for (final entry in _cart.entries) {
      final item = _items.firstWhere((i) => i.id == entry.key);
      total += _getItemPrice(item) * entry.value;
    }
    return total;
  }

  String _formatQty(double qty) {
    if (qty == 0.25) return '¼';
    if (qty == 0.5) return '½';
    if (qty == 0.75) return '¾';
    return qty.toStringAsFixed(qty == qty.roundToDouble() ? 0 : 2);
  }

  void _checkout() async {
    if (_cart.isEmpty) return;

    final cartItems = <Item, double>{};
    for (final entry in _cart.entries) {
      final item = _items.firstWhere((i) => i.id == entry.key);
      cartItems[item] = entry.value;
    }

    final sold = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CartCheckoutDialog(
        cart: cartItems,
        priceOverrides: _priceOverrides,
      ),
    );

    if (sold == true && mounted) {
      setState(() {
        _cart.clear();
        _priceOverrides.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Byagurishijwe!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _showPriceEdit(Item item) {
    final controller = TextEditingController(
      text: _getItemPrice(item).toStringAsFixed(0),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Igiciro - ${item.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: 'Frw'),
          style: const TextStyle(fontSize: 20),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _priceOverrides.remove(item.id!));
              Navigator.pop(ctx);
            },
            child: const Text('SUBIZA'),
          ),
          TextButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                setState(() => _priceOverrides[item.id!] = val);
              }
              Navigator.pop(ctx);
            },
            child: const Text('BIKA'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(Item item) {
    final qty = _cart[item.id!] ?? 0;
    final inCart = qty > 0;
    final isFraction = item.sellingMode == 'fraction';
    final hasOverride = _priceOverrides.containsKey(item.id!);
    final price = _getItemPrice(item);

    return Card(
      color: inCart ? const Color(0xFFE8F5E9) : null,
      child: InkWell(
        onTap: () {
          if (isFraction) {
            _showFractionPicker(item);
          } else {
            _addToCart(item);
          }
        },
        onLongPress: inCart ? () => _showPriceEdit(item) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        Text(
                          '${price.toStringAsFixed(0)} Frw',
                          style: TextStyle(
                            fontSize: 14,
                            color: hasOverride ? Colors.blue : Colors.grey,
                            fontWeight: hasOverride ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (isFraction && item.unitLabel != null)
                          Text(
                            ' / ${item.unitLabel}',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (inCart) ...[
                IconButton(
                  onPressed: () => isFraction
                      ? _removeFromCart(item, qty)
                      : _removeFromCart(item),
                  icon: const Icon(Icons.remove_circle, size: 32),
                  color: Colors.red.shade400,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    _formatQty(qty),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (isFraction) {
                      _showFractionPicker(item);
                    } else {
                      _addToCart(item);
                    }
                  },
                  icon: const Icon(Icons.add_circle, size: 32),
                  color: Colors.green,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ] else
                const Icon(Icons.add_circle_outline, color: Colors.grey, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;
    final top = _topItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Andika ibyo ucuruje'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: _items.isEmpty
          ? const Center(
              child: Text(
                'Nta bicuruzwa.\nTangira wongere ibicuruzwa.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Shakisha igicuruzwa...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    style: const TextStyle(fontSize: 18),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                // Items list
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    children: [
                      // Most sold section
                      if (top.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(left: 8, top: 4, bottom: 4),
                          child: Text(
                            'Ibikunzwe',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                        ),
                        ...top.map(_buildItemTile),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Divider(),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 8, bottom: 4),
                          child: Text(
                            'Byose',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                        ),
                      ],
                      // All / filtered items
                      ...filtered.map(_buildItemTile),
                    ],
                  ),
                ),
                if (_cart.isNotEmpty)
                  GestureDetector(
                    onTap: _checkout,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_cart.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_cartTotal.toStringAsFixed(0)} Frw',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'KOMEZA',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 64,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade50,
            foregroundColor: Colors.green.shade800,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
        ),
      ),
    );
  }
}
