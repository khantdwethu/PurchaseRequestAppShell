import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'screens/webview_screen.dart';

class PurchaseRequestApp extends StatelessWidget {
  const PurchaseRequestApp({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Color(AppConfig.primaryColorValue);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConfig.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const WebViewScreen(),
    );
  }
}
