import 'package:flutter/material.dart';
import '../controllers/ads_controller.dart';
import '../widgets/banner_ad_widget.dart';
import 'activation_screen.dart';
import 'ads_hub_screen.dart';
import 'affiliate_screen.dart';
import 'wallet_screen.dart';

/// MainNavigationScreen: Container Navigasi 4 Tab Utama Ekosistem AppDock Hub
/// Dilengkapi Sticky Banner Ad yang selalu tampil di atas Bottom Navigation Bar.
class MainNavigationScreen extends StatefulWidget {
  final AdsController adsController;

  const MainNavigationScreen({Key? key, required this.adsController}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFF0F172A);
    const primaryOrange = Color(0xFFF97316);

    final List<Widget> screens = [
      AdsHubScreen(adsController: widget.adsController),
      ActivationScreen(backendBaseUrl: widget.adsController.backendBaseUrl),
      AffiliateScreen(pairToken: widget.adsController.pairToken),
      WalletScreen(adsBalance: widget.adsController.balanceAds),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      // Sticky Persistent Banner Ads di bagian bawah layar sebelum Navbar
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // STICKY BOTTOM BANNER ADS
          Container(
            color: const Color(0xFF0B132B),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: const BannerAdWidget(),
          ),
          // BOTTOM NAVIGATION BAR
          BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: cardColor,
            selectedItemColor: primaryOrange,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            selectedFontSize: 11,
            unselectedFontSize: 10,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.play_circle_filled_rounded),
                label: 'Cuan Ads',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.vpn_key_rounded),
                label: 'Software HWID',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_alt_rounded),
                label: 'Afiliasi 2-Tier',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Dompet',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
