class Sale {
  final int? id;
  final int itemId;
  final double quantity;
  final double totalPrice;
  final bool isPaid;
  final String? customerName;
  final String? notes;
  final String createdAt;

  // Joined fields
  final String? itemName;

  Sale({
    this.id,
    required this.itemId,
    required this.quantity,
    required this.totalPrice,
    required this.isPaid,
    this.customerName,
    this.notes,
    String? createdAt,
    this.itemName,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'item_id': itemId,
      'quantity': quantity,
      'total_price': totalPrice,
      'is_paid': isPaid ? 1 : 0,
      'customer_name': customerName,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as int?,
      itemId: map['item_id'] as int,
      quantity: (map['quantity'] as num).toDouble(),
      totalPrice: (map['total_price'] as num).toDouble(),
      isPaid: (map['is_paid'] as int) == 1,
      customerName: map['customer_name'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
      itemName: map['item_name'] as String?,
    );
  }

  Sale copyWith({bool? isPaid}) {
    return Sale(
      id: id,
      itemId: itemId,
      quantity: quantity,
      totalPrice: totalPrice,
      isPaid: isPaid ?? this.isPaid,
      customerName: customerName,
      notes: notes,
      createdAt: createdAt,
      itemName: itemName,
    );
  }
}
