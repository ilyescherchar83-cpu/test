import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../controllers/product_controller.dart';
import '../models/product_model.dart';
import 'product_form_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isScanning = true;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مسح الباركود'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.flash_on : Icons.flash_off),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
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
                    _processBarcode(code);
                  }
                }
              },
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductFormScreen(
                            barcode: '',
                            product: null,
                          ),
                        ),
                      ).then((_) {
                        setState(() {
                          _isScanning = true;
                        });
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('إدخال منتج يدوياً'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 20,
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

  void _processBarcode(String barcode) async {
    final productController = Provider.of<ProductController>(context, listen: false);
    final product = await productController.findProductByBarcode(barcode);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormScreen(
          barcode: barcode,
          product: product,
        ),
      ),
    ).then((_) {
      setState(() {
        _isScanning = true;
      });
    });
  }
}