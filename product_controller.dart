import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import '../models/product_model.dart';

class ProductController extends ChangeNotifier {
  Database? _database;
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  String _searchQuery = '';

  List<Product> get products => _products;
  List<Product> get filteredProducts => _filteredProducts;

  // تهيئة قاعدة البيانات
  Future<void> initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'inventory.db');

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
    
    await loadProducts();
  }

  // تحميل جميع المنتجات من قاعدة البيانات
  Future<void> loadProducts() async {
    if (_database == null) return;
    
    final List<Map<String, dynamic>> maps = await _database!.query('products');
    _products = List.generate(maps.length, (i) => Product.fromMap(maps[i]));
    _applyFilter();
    notifyListeners();
  }

  // إضافة منتج جديد أو تحديث منتج موجود
  Future<void> saveProduct(Product product) async {
    if (_database == null) return;

    if (product.id != null) {
      // تحديث منتج موجود
      await _database!.update(
        'products',
        product.toMap(),
        where: 'id = ?',
        whereArgs: [product.id],
      );
    } else {
      // إضافة منتج جديد
      await _database!.insert(
        'products',
        product.toMap(),
      );
    }
    
    await loadProducts();
  }

  // البحث عن منتج بواسطة الباركود
  Future<Product?> findProductByBarcode(String barcode) async {
    if (_database == null) return null;
    
    final List<Map<String, dynamic>> maps = await _database!.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
    );
    
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  // حذف منتج
  Future<void> deleteProduct(int id) async {
    if (_database == null) return;
    
    await _database!.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    await loadProducts();
  }

  // تصفية المنتجات حسب البحث
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  // تطبيق التصفية على المنتجات
  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredProducts = List.from(_products);
    } else {
      _filteredProducts = _products.where((product) {
        return product.name.contains(_searchQuery) ||
               product.barcode.contains(_searchQuery);
      }).toList();
    }
  }

  // الحصول على تاريخ اليوم بتنسيق مناسب
  String getCurrentDate() {
    return DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
  }

  // تصدير البيانات إلى ملف Excel
  Future<void> exportToExcel() async {
    if (_products.isEmpty) return;

    final excel = Excel.createExcel();
    final sheet = excel['المنتجات'];

    // إضافة العناوين
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = 'الكود بار';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value = 'اسم المنتج';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0)).value = 'الفئة';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).value = 'الكمية';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0)).value = 'تاريخ آخر تحديث';

    // إضافة البيانات
    for (int i = 0; i < _products.length; i++) {
      final product = _products[i];
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1)).value = product.barcode;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1)).value = product.name;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1)).value = product.category;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i + 1)).value = product.quantity;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: i + 1)).value = product.lastUpdate;
    }

    // حفظ الملف
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'inventory_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
    final filePath = '${directory.path}/$fileName';
    
    final fileBytes = excel.save();
    if (fileBytes != null) {
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);
      
      // مشاركة الملف
      await Share.shareXFiles([XFile(filePath)], text: 'تقرير إحصاء المنتجات');
    }
  }
}