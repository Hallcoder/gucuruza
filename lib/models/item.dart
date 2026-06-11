class Item {
  final int? id;
  final String name;
  final double costPrice;
  final double sellingPrice;
  final String sellingMode;
  final String? unitLabel;
  final String createdAt;

  Item({
    this.id,
    required this.name,
    required this.costPrice,
    required this.sellingPrice,
    required this.sellingMode,
    this.unitLabel,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'selling_mode': sellingMode,
      'unit_label': unitLabel,
      'created_at': createdAt,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] as int?,
      name: map['name'] as String,
      costPrice: (map['cost_price'] as num).toDouble(),
      sellingPrice: (map['selling_price'] as num).toDouble(),
      sellingMode: map['selling_mode'] as String,
      unitLabel: map['unit_label'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  static String modeLabel(String mode) {
    switch (mode) {
      case 'unit':
        return 'Igice';
      case 'bag':
        return 'Umufuka';
      case 'pack':
        return 'Ipaki';
      case 'fraction':
        return 'Ibice';
      case 'name_only':
        return 'Izina gusa';
      default:
        return mode;
    }
  }
}
