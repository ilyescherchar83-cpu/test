# تعليمات بناء تطبيق إحصاء منتجات السوبرماركت

هذا الملف يحتوي على تعليمات مفصلة لبناء تطبيق Flutter لإحصاء منتجات السوبرماركت. يمكن استخدام هذه التعليمات من قبل الذكاء الاصطناعي أو المطورين لإعادة بناء التطبيق بالكامل.

## متطلبات النظام

1. تثبيت Flutter SDK (أحدث إصدار)
2. تثبيت Android Studio أو Visual Studio Code
3. تثبيت Git
4. تثبيت JDK (Java Development Kit)
5. إعداد جهاز Android للاختبار (حقيقي أو محاكي)

## خطوات بناء التطبيق

### 1. إنشاء مشروع Flutter جديد

```bash
flutter create supermarket_inventory
cd supermarket_inventory
```

### 2. تعديل ملف pubspec.yaml

استبدل محتوى ملف `pubspec.yaml` بالمحتوى التالي:

```yaml
name: supermarket_inventory
description: تطبيق لإحصاء منتجات السوبرماركت
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  cupertino_icons: ^1.0.2
  google_fonts: ^5.1.0
  flutter_svg: ^2.0.7
  mobile_scanner: ^3.3.0
  sqflite: ^2.3.0
  path_provider: ^2.1.1
  path: ^1.8.3
  provider: ^6.0.5
  excel: ^2.1.0
  file_picker: ^5.3.3
  permission_handler: ^10.4.3
  intl: ^0.18.1
  share_plus: ^7.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/images/
  fonts:
    - family: Cairo
      fonts:
        - asset: assets/fonts/Cairo-Regular.ttf
        - asset: assets/fonts/Cairo-Bold.ttf
          weight: 700
```

### 3. إنشاء هيكل المجلدات

قم بإنشاء المجلدات التالية:

```
lib/
  ├── controllers/
  ├── models/
  ├── views/
  ├── utils/
  └── widgets/
assets/
  ├── images/
  └── fonts/
```

### 4. إنشاء نموذج المنتج (Product Model)

أنشئ ملف `lib/models/product_model.dart` بالمحتوى التالي:

```dart
class Product {
  final int? id;
  final String barcode;
  final String name;
  final String category;
  final int quantity;
  final DateTime lastUpdate;

  Product({
    this.id,
    required this.barcode,
    required this.name,
    required this.category,
    required this.quantity,
    required this.lastUpdate,
  });

  Product copyWith({
    int? id,
    String? barcode,
    String? name,
    String? category,
    int? quantity,
    DateTime? lastUpdate,
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'category': category,
      'quantity': quantity,
      'lastUpdate': lastUpdate.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      barcode: map['barcode'],
      name: map['name'],
      category: map['category'],
      quantity: map['quantity'],
      lastUpdate: DateTime.parse(map['lastUpdate']),
    );
  }
}
```

### 5. إنشاء وحدة التحكم بالمنتجات (Product Controller)

أنشئ ملف `lib/controllers/product_controller.dart` بالمحتوى التالي:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';
import '../models/product_model.dart';

class ProductController extends ChangeNotifier {
  late Database _database;
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<Product> get products => _filteredProducts;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  ProductController() {
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    _isLoading = true;
    notifyListeners();

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'products.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE products(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            barcode TEXT,
            name TEXT,
            category TEXT,
            quantity INTEGER,
            lastUpdate TEXT
          )
        ''');
      },
    );

    await _loadProducts();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadProducts() async {
    final List<Map<String, dynamic>> maps = await _database.query('products');
    _products = List.generate(maps.length, (i) => Product.fromMap(maps[i]));
    _applyFilter();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredProducts = List.from(_products);
    } else {
      _filteredProducts = _products.where((product) {
        return product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.barcode.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
  }

  Future<Product?> findProductByBarcode(String barcode) async {
    final List<Map<String, dynamic>> maps = await _database.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
    );

    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  Future<void> saveProduct(Product product) async {
    _isLoading = true;
    notifyListeners();

    if (product.id != null) {
      await _database.update(
        'products',
        product.toMap(),
        where: 'id = ?',
        whereArgs: [product.id],
      );
    } else {
      await _database.insert('products', product.toMap());
    }

    await _loadProducts();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteProduct(int id) async {
    _isLoading = true;
    notifyListeners();

    await _database.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );

    await _loadProducts();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> exportToExcel() async {
    _isLoading = true;
    notifyListeners();

    try {
      final excel = Excel.createExcel();
      final sheet = excel['المنتجات'];

      // Add headers
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = 'الباركود';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value = 'اسم المنتج';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0)).value = 'الفئة';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).value = 'الكمية';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0)).value = 'آخر تحديث';

      // Add data
      for (var i = 0; i < _products.length; i++) {
        final product = _products[i];
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1)).value = product.barcode;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1)).value = product.name;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1)).value = product.category;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i + 1)).value = product.quantity;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: i + 1)).value = 
            '${product.lastUpdate.year}-${product.lastUpdate.month}-${product.lastUpdate.day}';
      }

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/products_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File(path);
      await file.writeAsBytes(excel.encode()!);

      // Share file
      await Share.shareXFiles([XFile(path)], text: 'تصدير بيانات المنتجات');
    } catch (e) {
      debugPrint('Error exporting to Excel: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}
```

### 6. إنشاء وحدة التحكم بالسمة (Theme Controller)

أنشئ ملف `lib/controllers/theme_controller.dart` بالمحتوى التالي:

```dart
import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
```

### 7. إنشاء الشاشة الرئيسية (Home Screen)

أنشئ ملف `lib/views/home_screen.dart` بالمحتوى التالي:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/theme_controller.dart';
import '../controllers/product_controller.dart';
import 'scan_screen.dart';
import 'products_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final productController = Provider.of<ProductController>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('إحصاء المنتجات'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              themeController.themeMode == ThemeMode.light
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            onPressed: () {
              themeController.toggleTheme();
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.inventory_2_rounded,
                size: 100,
                color: Colors.green,
              ),
              const SizedBox(height: 20),
              const Text(
                'مرحباً بك في تطبيق إحصاء المنتجات',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _buildButton(
                context,
                'بدء الإحصاء',
                Icons.qr_code_scanner,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ScanScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildButton(
                context,
                'عرض المنتجات',
                Icons.view_list,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProductsScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildButton(
                context,
                'تصدير البيانات',
                Icons.file_download,
                () async {
                  await productController.exportToExcel();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تصدير البيانات بنجاح'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
      BuildContext context, String text, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(
          text,
          style: const TextStyle(fontSize: 18),
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
```

### 8. إنشاء شاشة المسح (Scan Screen)

أنشئ ملف `lib/views/scan_screen.dart` بالمحتوى التالي:

```dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'product_form_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  MobileScannerController controller = MobileScannerController();
  bool _isScanning = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مسح الباركود'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off);
                  case TorchState.on:
                    return const Icon(Icons.flash_on);
                }
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller.cameraFacingState,
              builder: (context, state, child) {
                switch (state) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: MobileScanner(
              controller: controller,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && _isScanning) {
                  final String code = barcodes.first.rawValue ?? '';
                  if (code.isNotEmpty) {
                    setState(() {
                      _isScanning = false;
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductFormScreen(barcode: code),
                      ),
                    ).then((_) {
                      setState(() {
                        _isScanning = true;
                      });
                    });
                  }
                }
              },
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'قم بتوجيه الكاميرا نحو الباركود',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('إدخال يدوي'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProductFormScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
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
```

### 9. إنشاء شاشة نموذج المنتج (Product Form Screen)

أنشئ ملف `lib/views/product_form_screen.dart` بالمحتوى التالي:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/product_controller.dart';
import '../models/product_model.dart';

class ProductFormScreen extends StatefulWidget {
  final String? barcode;
  final Product? product;

  const ProductFormScreen({Key? key, this.barcode, this.product}) : super(key: key);

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _barcodeController;
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  String _selectedCategory = 'أساسية';
  bool _isLoading = false;

  final List<String> _categories = ['أساسية', 'ثانوية', 'كمالية'];

  @override
  void initState() {
    super.initState();
    _barcodeController = TextEditingController(text: widget.barcode ?? widget.product?.barcode ?? '');
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _quantityController = TextEditingController(text: widget.product?.quantity.toString() ?? '1');
    
    if (widget.product != null) {
      _selectedCategory = widget.product!.category;
    }

    _loadProductIfExists();
  }

  Future<void> _loadProductIfExists() async {
    if (widget.barcode != null && widget.product == null) {
      setState(() {
        _isLoading = true;
      });

      final productController = Provider.of<ProductController>(context, listen: false);
      final product = await productController.findProductByBarcode(widget.barcode!);

      if (product != null && mounted) {
        setState(() {
          _nameController.text = product.name;
          _quantityController.text = product.quantity.toString();
          _selectedCategory = product.category;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product != null ? 'تعديل منتج' : 'إضافة منتج'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barcode Field
                    TextFormField(
                      controller: _barcodeController,
                      decoration: const InputDecoration(
                        labelText: 'الباركود',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.qr_code),
                      ),
                      readOnly: widget.barcode != null || widget.product != null,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال الباركود';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم المنتج',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.shopping_bag),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال اسم المنتج';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'الفئة',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Quantity Field
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'الكمية',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال الكمية';
                        }
                        if (int.tryParse(value) == null) {
                          return 'الرجاء إدخال رقم صحيح';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Consumer<ProductController>(
                        builder: (context, productController, child) {
                          return ElevatedButton(
                            onPressed: productController.isLoading
                                ? null
                                : () async {
                                    if (_formKey.currentState!.validate()) {
                                      final product = Product(
                                        id: widget.product?.id,
                                        barcode: _barcodeController.text,
                                        name: _nameController.text,
                                        category: _selectedCategory,
                                        quantity: int.parse(_quantityController.text),
                                        lastUpdate: DateTime.now(),
                                      );

                                      await productController.saveProduct(product);

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('تم حفظ المنتج بنجاح'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                        Navigator.pop(context);
                                      }
                                    }
                                  },
                            child: productController.isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'حفظ',
                                    style: TextStyle(fontSize: 18),
                                  ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
```

### 10. إنشاء شاشة عرض المنتجات (Products Screen)

أنشئ ملف `lib/views/products_screen.dart` بالمحتوى التالي:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/product_controller.dart';
import '../models/product_model.dart';
import 'product_form_screen.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة المنتجات'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () async {
              final productController = Provider.of<ProductController>(context, listen: false);
              await productController.exportToExcel();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم تصدير البيانات بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'بحث عن منتج',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                Provider.of<ProductController>(context, listen: false)
                    .setSearchQuery(value);
              },
            ),
          ),
          Expanded(
            child: Consumer<ProductController>(
              builder: (context, productController, child) {
                if (productController.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final products = productController.products;

                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          productController.searchQuery.isEmpty
                              ? 'لا توجد منتجات'
                              : 'لا توجد نتائج للبحث',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ProductListItem(product: product);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ProductListItem extends StatelessWidget {
  final Product product;

  const ProductListItem({Key? key, required this.product}) : super(key: key);

  Color _getCategoryColor() {
    switch (product.category) {
      case 'أساسية':
        return Colors.green;
      case 'ثانوية':
        return Colors.blue;
      case 'كمالية':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          product.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.qr_code, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('الباركود: ${product.barcode}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.category, size: 16, color: _getCategoryColor()),
                const SizedBox(width: 4),
                Text('الفئة: ${product.category}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.numbers, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('الكمية: ${product.quantity}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.update, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('آخر تحديث: ${dateFormat.format(product.lastUpdate)}'),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductFormScreen(product: product),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('تأكيد الحذف'),
                    content: const Text('هل أنت متأكد من حذف هذا المنتج؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('إلغاء'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Provider.of<ProductController>(context, listen: false)
                              .deleteProduct(product.id!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم حذف المنتج بنجاح'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        },
                        child: const Text('حذف', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

### 11. إنشاء ملف main.dart

أنشئ ملف `lib/main.dart` بالمحتوى التالي:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'controllers/product_controller.dart';
import 'controllers/theme_controller.dart';
import 'views/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => ProductController()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp(
            title: 'إحصاء المنتجات',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.green,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              textTheme: GoogleFonts.cairoTextTheme(
                Theme.of(context).textTheme,
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.green,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              textTheme: GoogleFonts.cairoTextTheme(
                Theme.of(context).textTheme,
              ),
            ),
            themeMode: themeController.themeMode,
            locale: const Locale('ar', 'SA'),
            supportedLocales: const [
              Locale('ar', 'SA'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
```

### 12. بناء التطبيق

بعد إنشاء جميع الملفات، قم بتنفيذ الأوامر التالية:

```bash
# تثبيت الاعتمادات
flutter pub get

# تشغيل التطبيق للاختبار
flutter run

# بناء ملف APK للتثبيت على الهاتف
flutter build apk --release
```

### 13. تثبيت التطبيق على الهاتف

1. انسخ ملف APK من المسار `build/app/outputs/flutter-apk/app-release.apk` إلى هاتفك
2. قم بتثبيت التطبيق على هاتفك
3. استمتع باستخدام تطبيق إحصاء منتجات السوبرماركت!

## ملاحظات إضافية

- تأكد من تفعيل وضع المطور على هاتفك والسماح بتثبيت التطبيقات من مصادر غير معروفة
- يمكنك تخصيص التطبيق حسب احتياجاتك بتعديل الكود المصدري
- للحصول على أفضل أداء، قم بتشغيل التطبيق على هاتف بكاميرا جيدة لمسح الباركود بدقة

## استكشاف الأخطاء وإصلاحها

إذا واجهت أي مشاكل أثناء بناء التطبيق، تأكد من:

1. تثبيت أحدث إصدار من Flutter SDK
2. تثبيت جميع الاعتمادات بشكل صحيح
3. تكوين بيئة التطوير بشكل صحيح
4. تفعيل وضع المطور على هاتفك