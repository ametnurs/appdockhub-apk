import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/ads_controller.dart';
import '../services/deep_link_service.dart';
import '../widgets/banner_ad_widget.dart';

/// AdsHubScreen (Offerwall Iklan): Tampilan Utama Berdesain Modern FinTech Glassmorphism
/// Dilengkapi Ambient Glows, Telegram Pairing Chip, dan Tombol Interaktif 3D Glow CTA.
class AdsHubScreen extends StatefulWidget {
  final AdsController adsController;

  const AdsHubScreen({Key? key, required this.adsController}) : super(key: key);

  @override
  State<AdsHubScreen> createState() => _AdsHubScreenState();
}

class _AdsHubScreenState extends State<AdsHubScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    widget.adsController.initialize();
    widget.adsController.addListener(_onControllerUpdate);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    widget.adsController.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.adsController;
    const bgDark = Color(0xFF070B14);
    const orangeStart = Color(0xFFFF5E00);
    const orangeEnd = Color(0xFFFF9E00);

    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [
          // Ambient Background Glow Effect (Efek Lampu Neon Lembut)
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: orangeStart.withOpacity(0.18),
                boxShadow: [
                  BoxShadow(
                    color: orangeStart.withOpacity(0.2),
                    blurRadius: 100,
                    spreadRadius: 40,
                  )
                ],
              ),
            ),
          ),
          Positioned(
            top: 280,
            left: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withOpacity(0.12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.12),
                    blurRadius: 120,
                    spreadRadius: 50,
                  )
                ],
              ),
            ),
          ),

          // Konten Utama Scrollable
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. HEADER MODERN BAR
                  _buildModernHeader(context),
                  const SizedBox(height: 16),

                  // 2. BANNER ADS ATAS (TERBUNGKUS FRAME GLASS ELEGAN)
                  _buildAdContainer(const BannerAdWidget()),
                  const SizedBox(height: 16),

                  // 3. TELEGRAM SYNC CHIP CARD
                  _buildTelegramSyncCard(controller),
                  const SizedBox(height: 16),

                  // 4. MAIN MONETIZATION GLASS CARD (DOMPET & SEGMENTED 10 ADS)
                  _buildMainBalanceCard(controller),
                  const SizedBox(height: 20),

                  // 5. TOMBOL UTAMA 3D GLOW CTA (NONTON IKLAN)
                  _buildActionWatchButton(controller),
                  const SizedBox(height: 20),

                  // 6. IN-FEED BANNER ADS
                  _buildAdContainer(const BannerAdWidget()),
                  const SizedBox(height: 18),

                  // 7. FUNNEL KEMITRAAN 2-TIER CARD (HIGH-CONVERSION)
                  _buildAffiliateFunnelCard(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 1. Modern Header dengan Status Realtime
  Widget _buildModernHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5E00), Color(0xFFFF9E00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5E00).withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Offerwall Iklan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Cloudflare D1 Online',
                      style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        // Badge Offerwall Aktif
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: const Row(
            children: [
              Icon(Icons.play_circle_fill_rounded, color: Color(0xFFFF9E00), size: 16),
              SizedBox(width: 6),
              Text(
                'Video Ads',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 2. Container Pembungkus Ad Agar Menyatu dengan Tema Gelap
  Widget _buildAdContainer(Widget child) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: child,
    );
  }

  /// 3. Telegram Pairing Card
  Widget _buildTelegramSyncCard(AdsController controller) {
    final token = controller.pairToken.isNotEmpty ? controller.pairToken : 'Generating...';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF0284C7).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.telegram, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sinkronisasi Telegram Bot',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: token));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Token Pairing disalin ke clipboard!')),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        token.length > 20 ? '${token.substring(0, 18)}...' : token,
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontFamily: 'monospace'),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.copy_rounded, color: Color(0xFF38BDF8), size: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onPressed: () => DeepLinkService.openBotPairing(controller.pairToken),
            child: const Text('Pair Bot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  /// 4. Main Glass Balance Card dengan Segmented 10-Ads Indicator
  Widget _buildMainBalanceCard(AdsController controller) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF141E33),
            const Color(0xFF0B1120),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Badge Pill Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5E00).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFF5E00).withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.monetization_on_rounded, color: Color(0xFFFF9E00), size: 14),
                    SizedBox(width: 5),
                    Text('Saldo Rewarded Ads', style: TextStyle(color: Color(0xFFFF9E00), fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '+Rp 10 / Iklan',
                  style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Nilai Saldo Besar
          Text(
            'Rp ${controller.balanceAds.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tersimpan aman di Cloudflare D1 Backend',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
        ],
      ),
    );
  }

  /// 5. Tombol CTA 3D Glow Nonton Iklan
  Widget _buildActionWatchButton(AdsController controller) {
    const orangeStart = Color(0xFFFF5E00);
    const orangeEnd = Color(0xFFFF9E00);

    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: controller.isLimitReached
            ? []
            : [
                BoxShadow(
                  color: orangeStart.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: EdgeInsets.zero,
        ),
        onPressed: controller.isLoading
            ? null
            : () => controller.watchRewardedAd(context),
        child: Ink(
          decoration: BoxDecoration(
            gradient: controller.isLimitReached
                ? LinearGradient(colors: [Colors.grey.shade800, Colors.grey.shade900])
                : const LinearGradient(colors: [orangeStart, orangeEnd]),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Container(
            alignment: Alignment.center,
            child: controller.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        controller.isLimitReached ? Icons.lock_clock_rounded : Icons.play_circle_fill_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        controller.isLimitReached
                            ? 'Buka Cuan Afiliasi 30% ➔'
                            : 'Tonton Video Rewarded (+Rp 10)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  /// 6. Card Funnel Kemitraan Afiliasi 2-Tier
  Widget _buildAffiliateFunnelCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B0764), Color(0xFF1E1B4B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Program Kemitraan Afiliasi 2-Tier',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Tanpa batas kuota harian! Raih Rp 29.700 per lisensi terjual (30%) + bonus pasif Rp 4.950 (5%) dari setiap penjualan tim Anda.',
            style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9333EA),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => DeepLinkService.openAffiliateProgram(),
              child: const Text('Ambil Link Afiliasi Anda ➔', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}
