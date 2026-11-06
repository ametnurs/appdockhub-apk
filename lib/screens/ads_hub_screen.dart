import 'package:flutter/material.dart';
import '../controllers/ads_controller.dart';
import '../services/deep_link_service.dart';
import '../widgets/banner_ad_widget.dart';
import 'activation_screen.dart';

/// AdsHubScreen: Layar Pusat Monetisasi APK
/// Menampilkan Banner Ads, Counter 10 Iklan Rewarded Harian, Akumulasi Poin,
/// Tombol Pairing Telegram, serta Tombol Nonton Iklan yang terkunci otomatis saat mencapai 10/10.
class AdsHubScreen extends StatefulWidget {
  final AdsController adsController;

  const AdsHubScreen({Key? key, required this.adsController}) : super(key: key);

  @override
  State<AdsHubScreen> createState() => _AdsHubScreenState();
}

class _AdsHubScreenState extends State<AdsHubScreen> {
  @override
  void initState() {
    super.initState();
    widget.adsController.initialize();
    widget.adsController.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    widget.adsController.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF080C14);
    const cardColor = Color(0xFF0F172A);
    const primaryOrange = Color(0xFFF97316);

    final controller = widget.adsController;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        title: const Text('AppDock Hub - Monetization', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.vpn_key_rounded, color: primaryOrange),
            tooltip: 'Aktivasi Lisensi HWID',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ActivationScreen(backendBaseUrl: controller.backendBaseUrl)),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. BANNER ADS ATAS (PENGHASILAN TAMBAHAN IMPRESI)
            const BannerAdWidget(),
            const SizedBox(height: 16),

            // Card 1: Pairing Telegram Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF1E293B), Colors.blueGrey.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.telegram, color: Color(0xFF38BDF8), size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sinkronkan ke Telegram',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Token: ${controller.pairToken.isNotEmpty ? controller.pairToken : "Memuat..."}',
                          style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: () => DeepLinkService.openBotPairing(controller.pairToken),
                    child: const Text('Pair', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card 2: Saldo Iklan & Progress Kuota 10 Harian
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                children: [
                  const Text('Saldo Nonton Iklan (Hari Ini)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(
                    'Rp ${controller.balanceAds.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Progress Bar 0 to 10
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Kuota Harian Ditonton', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      Text(
                        '${controller.adsWatchedToday} / ${AdsController.maxDailyQuota}',
                        style: TextStyle(
                          color: controller.isLimitReached ? Colors.amber : primaryOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: controller.adsWatchedToday / AdsController.maxDailyQuota,
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        controller.isLimitReached ? Colors.amber : primaryOrange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    controller.isLimitReached
                        ? '🔒 Kuota harian habis. Tombol nonton terkunci!'
                        : 'Sisa kuota hari ini: ${controller.remainingQuota} iklan video.',
                    style: TextStyle(
                      color: controller.isLimitReached ? Colors.amber : Colors.grey,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tombol Utama: Nonton Video Rewarded Ad
            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: controller.isLimitReached ? Colors.grey.shade800 : primaryOrange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: controller.isLimitReached ? 0 : 5,
                ),
                onPressed: controller.isLoading
                    ? null
                    : () => controller.watchRewardedAd(context),
                child: controller.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            controller.isLimitReached ? Icons.lock_rounded : Icons.play_circle_fill_rounded,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            controller.isLimitReached
                                ? 'Kuota Habis (Beralih ke Afiliasi 30%)'
                                : 'Tonton Iklan Rewarded (+Rp 300)',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. BANNER ADS TENGAH (IN-FEED BANNER)
            const BannerAdWidget(),
            const SizedBox(height: 20),

            // Banner CTA: Friction to Conversion Funnel 2-Tier
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF831843), Color(0xFF4C0519)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF831843).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Program Afiliasi 2-Tier Resmi',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tanpa batas kuota harian! Raih Rp 29.700 per closing software dan Rp 4.950 komisi pasif dari setiap penjualan tim Anda.',
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.amber),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => DeepLinkService.openAffiliateProgram(),
                      child: const Text(
                        'Ambil Link Afiliasi Saya ➔',
                        style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
