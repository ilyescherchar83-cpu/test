import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/product_controller.dart';
import '../models/product_model.dart';

class ProductFormScreen extends StatefulWidget {
  final String barcode;
  final Product? product;

  const ProductFormScreen({
    super.key,
    required this.barcode,
    this.product,
  });

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  String _category = 'أساسية';
  final List<String> _categories = ['أساسية', 'ثانوية', 'كمالية'];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _quantityController.text = widget.product!.quantity.toString();
      _category = widget.product!.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productController = Provider.of<ProductController>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product != null ? 'تعديل منتج' : 'إضافة منتج جديد'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // عرض الباركود
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'الباركود:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.barcode.isEmpty ? 'غير محدد' : widget.barcode,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // اسم المنتج
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
              const SizedBox(height: 20),
              
              // فئة المنتج
              DropdownButtonFormField<String>(
                value: _category,
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
                  if (value != null) {
                    setState(() {
                      _category = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              
              // الكمية
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
              const SizedBox(height: 30),
              
              // زر الحفظ
              ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _saveProduct(productController);
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text(
                  'حفظ المنتج',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveProduct(ProductController controller) async {
    final product = Product(
      id: widget.product?.id,
      barcode: widget.barcode.isEmpty ? 'يدوي-${DateTime.now().millisecondsSinceEpoch}' : widget.barcode,
      name: _nameController.text,
      category: _category,
      quantity: int.parse(_quantityController.text),
      lastUpdate: controller.getCurrentDate(),
    );
    
    await controller.saveProduct(product);
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ المنتج بنجاح')),
    );
    
    Navigator.pop(context);
  }
}