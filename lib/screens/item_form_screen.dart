import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/item.dart';

class ItemFormScreen extends StatefulWidget {
  final Item? item;

  const ItemFormScreen({super.key, this.item});

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseHelper();

  late final TextEditingController _nameController;
  late final TextEditingController _costController;
  late final TextEditingController _sellController;
  late final TextEditingController _unitLabelController;
  String _sellingMode = 'unit';

  bool get _isEditing => widget.item != null;

  static const _modes = [
    ('unit', 'Igice'),
    ('bag', 'Umufuka'),
    ('pack', 'Ipaki'),
    ('fraction', 'Ku kiro/litiro/metero'),
    ('name_only', 'Izina gusa'),
  ];

  static const _unitTypes = [
    ('Litiro', 'Litiro'),
    ('Kiro', 'Kiro'),
    ('Metero', 'Metero'),
  ];

  bool get _isFractionMode => _sellingMode == 'fraction';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _costController = TextEditingController(
      text: widget.item?.costPrice.toStringAsFixed(0) ?? '',
    );
    _sellController = TextEditingController(
      text: widget.item?.sellingPrice.toStringAsFixed(0) ?? '',
    );
    _unitLabelController = TextEditingController(text: widget.item?.unitLabel ?? '');
    _sellingMode = widget.item?.sellingMode ?? 'unit';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    _sellController.dispose();
    _unitLabelController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final item = Item(
      id: widget.item?.id,
      name: _nameController.text.trim(),
      costPrice: double.parse(_costController.text.trim()),
      sellingPrice: double.parse(_sellController.text.trim()),
      sellingMode: _sellingMode,
      unitLabel: _unitLabelController.text.trim().isEmpty
          ? null
          : _unitLabelController.text.trim(),
    );

    if (_isEditing) {
      await _db.updateItem(item);
    } else {
      await _db.insertItem(item);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Hindura' : 'Ongeraho igicuruzwa'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Izina'),
                style: const TextStyle(fontSize: 18),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => v == null || v.trim().isEmpty ? 'Andika izina' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(
                  labelText: 'Igiciro cyo kurangura',
                  suffixText: 'Frw',
                ),
                style: const TextStyle(fontSize: 18),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Andika igiciro';
                  if (double.tryParse(v.trim()) == null) return 'Umubare gusa';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sellController,
                decoration: const InputDecoration(
                  labelText: 'Igiciro cyo kugurisha',
                  suffixText: 'Frw',
                ),
                style: const TextStyle(fontSize: 18),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Andika igiciro';
                  if (double.tryParse(v.trim()) == null) return 'Umubare gusa';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _sellingMode,
                decoration: const InputDecoration(labelText: 'Uburyo bwo kugurisha'),
                style: const TextStyle(fontSize: 18, color: Colors.black),
                items: _modes
                    .map((m) => DropdownMenuItem(value: m.$1, child: Text(m.$2)))
                    .toList(),
                onChanged: (v) => setState(() => _sellingMode = v ?? 'unit'),
              ),
              if (_isFractionMode) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: _unitTypes.map((u) {
                    final selected = _unitLabelController.text == u.$1;
                    return ChoiceChip(
                      label: Text(u.$2, style: const TextStyle(fontSize: 16)),
                      selected: selected,
                      onSelected: (_) => setState(() => _unitLabelController.text = u.$1),
                      selectedColor: Colors.green.shade100,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Text(
                  'Igiciro cyo kugurisha = kuri ${_unitLabelController.text.isEmpty ? "..." : "1 ${_unitLabelController.text}"}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ] else ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _unitLabelController,
                  decoration: const InputDecoration(
                    labelText: 'Izina ry\'ingero (ntibisabwa)',
                    hintText: 'Urugero: Kg, Litiro, ...',
                  ),
                  style: const TextStyle(fontSize: 18),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('BIKA', style: TextStyle(fontSize: 20)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
