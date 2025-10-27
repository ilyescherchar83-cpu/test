class Product {
  final int? id;
  final String barcode;
  final String name;
  final String category;
  final int quantity;
  final String lastUpdate;

  Product({
    this.id,
    required this.barcode,
    required this.name,
    required this.category,
    required this.quantity,
    required this.lastUpdate,
  });

  // تحويل المنتج إلى Map لتخزينه في قاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'category': category,
      'quantity': quantity,
      'lastUpdate': lastUpdate,
    };
  }

  // إنشاء منتج من Map مستخرج من قاعدة البيانات
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      barcode: map['barcode'],
      name: map['name'],
      category: map['category'],
      quantity: map['quantity'],
      lastUpdate: map['lastUpdate'],
    );
  }

  // نسخة جديدة من المنتج مع تحديث بعض الخصائص
  Product copyWith({
    int? id,
    String? barcode,
    String? name,
    String? category,
    int? quantity,
    String? lastUpdate,
  }) {
    return Product(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}