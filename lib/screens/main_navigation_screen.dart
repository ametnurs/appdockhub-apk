import 'package:flutter/material.dart';
import '../controllers/ads_controller.dart';
import '../game/cyber_orbit_game.dart';
import '../services/locale_service.dart';
import '../widgets/banner_ad_widget.dart';
import 'ads_hub_screen.dart';
import 'affiliate_screen.dart';
import 'store_screen.dart';
import 'wallet_screen.dart';

/// MainNavigationScreen: Modern Floating Dock Navigation Bar
/// Menampilkan Game Orisinal "Cyber Orbit" sebagai Halaman Utama.
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
    const bgDark = Color(0xFF070B14);

    final List<Widget> screens = [
      CyberOrbitGameScreen(adsController: widget.adsController),
      AdsHubScreen(adsController: widget.adsController),
      StoreScreen(pairToken: widget.adsController.pairToken),
      AffiliateScreen(pairToken: widget.adsController.pairToken),
      WalletScreen(
        adsBalance: widget.adsController.balanceAds,
        pairToken: widget.adsController.pairToken,
      ),
    ];

    return Scaffold(
      backgroundColor: bgDark,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0B1120),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // STICKY BOTTOM BANNER ADS TERBUNGKUS FRAME RAPI
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: const BannerAdWidget(),
            ),

            // MODERN FLOATING DOCK BOTTOM NAVIGATION (5 MENU LENGKAP)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.gamepad_rounded, LocaleService.navGame),
                  _buildNavItem(1, Icons.live_tv_rounded, LocaleService.navOfferwall),
                  _buildNavItem(2, Icons.shopping_bag_rounded, LocaleService.navStore),
                  _buildNavItem(3, Icons.people_alt_rounded, LocaleService.navAffiliate),
                  _buildNavItem(4, Icons.account_balance_wallet_rounded, LocaleService.navWallet),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    const orangeColor = Color(0xFFFF5E00);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? orangeColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isSelected ? Border.all(color: orangeColor.withOpacity(0.35)) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? orangeColor : const Color(0xFF64748B),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
