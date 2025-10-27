import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/product_controller.dart';
import '../models/product_model.dart';
import 'product_form_screen.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productController = Provider.of<ProductController>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة المنتجات'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () {
              productController.exportToExcel();
            },
            tooltip: 'تصدير البيانات',
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'بحث',
                hintText: 'ابحث عن منتج بالاسم أو الباركود',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                productController.setSearchQuery(value);
              },
            ),
          ),
          
          // قائمة المنتجات
          Expanded(
            child: productController.filteredProducts.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد منتجات',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    itemCount: productController.filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = productController.filteredProducts[index];
                      return ProductListItem(product: product);
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

  const ProductListItem({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final productController = Provider.of<ProductController>(context, listen: false);
    
    // تحديد لون الفئة
    Color categoryColor;
    switch (product.category) {
      case 'أساسية':
        categoryColor = Colors.green;
        break;
      case 'ثانوية':
        categoryColor = Colors.amber;
        break;
      case 'كمالية':
        categoryColor = Colors.blue;
        break;
      default:
        categoryColor = Colors.grey;
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: categoryColor,
          child: Text(
            product.name.isNotEmpty ? product.name[0] : '؟',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الباركود: ${product.barcode}'),
            Text('الفئة: ${product.category}'),
            Text('الكمية: ${product.quantity}'),
            Text('آخر تحديث: ${product.lastUpdate}'),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductFormScreen(
                      barcode: product.barcode,
                      product: product,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _showDeleteConfirmation(context, product, productController);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Product product,
    ProductController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف المنتج "${product.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              controller.deleteProduct(product.id!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حذف المنتج بنجاح')),
              );
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}