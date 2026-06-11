import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/item.dart';
import 'item_form_screen.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final _db = DatabaseHelper();
  List<Item> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await _db.getItems();
    setState(() => _items = items);
  }

  void _addItem() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ItemFormScreen()),
    );
    _loadItems();
  }

  void _editItem(Item item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ItemFormScreen(item: item)),
    );
    _loadItems();
  }

  void _deleteItem(Item item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Siba'),
        content: Text('Urashaka gusiba "${item.name}"?'),
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
      await _db.deleteItem(item.id!);
      _loadItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ibicuruzwa'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: _items.isEmpty
          ? const Center(
              child: Text(
                'Nta bicuruzwa.\nKanda + wongere.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      item.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${item.sellingPrice.toStringAsFixed(0)} Frw / ${Item.modeLabel(item.sellingMode)}',
                      style: const TextStyle(fontSize: 15),
                    ),
                    trailing: Text(
                      'Kurangura: ${item.costPrice.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    onTap: () => _editItem(item),
                    onLongPress: () => _deleteItem(item),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: _addItem,
        child: const Icon(Icons.add, size: 36),
      ),
    );
  }
}
