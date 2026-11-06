import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'controllers/ads_controller.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Google Mobile Ads SDK (AdMob) untuk Rewarded & Banner Ads
  if (!kIsWeb) {
    try {
      await MobileAds.instance.initialize();
      debugPrint('🚀 Google Mobile Ads SDK initialized successfully!');
    } catch (e) {
      debugPrint('⚠️ Warning MobileAds init: $e');
    }
  }

  // Inisialisasi Ads Controller
  final adsController = AdsController(
    // Ganti URL ini dengan domain Cloudflare Worker Anda yang aktif
    backendBaseUrl: 'https://appdockhub.yourdomain.workers.dev',
  );
  await adsController.initialize();

  runApp(AppDockApp(adsController: adsController));
}

class AppDockApp extends StatelessWidget {
  final AdsController adsController;

  const AppDockApp({Key? key, required this.adsController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppDock Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF080C14),
        primaryColor: const Color(0xFFF97316),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF97316),
          secondary: Color(0xFF38BDF8),
          surface: Color(0xFF0F172A),
        ),
      ),
      home: MainNavigationScreen(adsController: adsController),
    );
  }
}
