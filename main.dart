import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'controllers/theme_controller.dart';
import 'controllers/product_controller.dart';
import 'views/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة قاعدة البيانات
  final productController = ProductController();
  await productController.initDatabase();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => productController),
      ],
      child: const SupermarketInventoryApp(),
    ),
  );
}

class SupermarketInventoryApp extends StatelessWidget {
  const SupermarketInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    
    return MaterialApp(
      title: 'إحصاء المنتجات',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Cairo',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Cairo',
      ),
      themeMode: themeController.themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', ''), // العربية
      ],
      locale: const Locale('ar', ''),
      home: const HomeScreen(),
    );
  }
}