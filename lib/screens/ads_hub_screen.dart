import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/ads_controller.dart';
import '../services/deep_link_service.dart';
import '../widgets/banner_ad_widget.dart';

/// Model Provider Offerwall CPA (Torox, CPALead, AdGate, TimeWall, Lootably, AyetStudios)
class OfferwallProviderItem {
  final String id;
  final String name;
  final String badge;
  final String subtitle;
  final String rewardRange;
  final List<Color> gradientColors;
  final IconData icon;
  final String baseUrl;

  const OfferwallProviderItem({
    required this.id,
    required this.name,
    required this.badge,
    required this.subtitle,
    required this.rewardRange,
    required this.gradientColors,
    required this.icon,
    required this.baseUrl,
  });

  String buildUrl(String userId) => baseUrl.replaceAll('{USER_ID}', Uri.encodeComponent(userId));
}

/// AdsHubScreen (Offerwall Center): Menampilkan daftar jaringan CPA Offerwall
/// seperti Torox, CPALead, AdGate Media, TimeWall, Lootably, dan AyetStudios
/// beserta Video Rewarded AdMob & sinkronisasi otomatis ke saldo pengguna via SubID/PairToken.
class AdsHubScreen extends StatefulWidget {
  final AdsController adsController;

  const AdsHubScreen({Key? key, required this.adsController}) : super(key: key);

  @override
  State<AdsHubScreen> createState() => _AdsHubScreenState();
}

class _AdsHubScreenState extends State<AdsHubScreen> {
  // Daftar Jaringan Offerwall Utama (Ganti App ID / Pub ID sesuai akun dashboard masing-masing)
  static const List<OfferwallProviderItem> _offerwallProviders = [
    OfferwallProviderItem(
      id: 'torox',
      name: 'Torox (OfferToro)',
      badge: '🔥 TOP PAYOUT',
      subtitle: 'Install aplikasi, mainkan game & selesaikan misi cepat.',
      rewardRange: 'Rp 500 - Rp 150.000 / Misi',
      gradientColors: [Color(0xFFFF5E00), Color(0xFFFF9900)],
      icon: Icons.bolt_rounded,
      baseUrl: 'https://torox.io/ifr/show/YOUR_TOROX_PUB_ID/{USER_ID}/YOUR_APP_ID',
    ),
    OfferwallProviderItem(
      id: 'cpalead',
      name: 'CPALead Offerwall',
      badge: '⚡ INSTANT CREDIT',
      subtitle: 'Survey singkat, unduh aplikasi & penawaran CPA instan.',
      rewardRange: 'Rp 300 - Rp 75.000 / Misi',
      gradientColors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
      icon: Icons.rocket_launch_rounded,
      baseUrl: 'https://www.cpalead.com/mobile/locker/?pub=YOUR_CPALEAD_ID&subid={USER_ID}',
    ),
    OfferwallProviderItem(
      id: 'timewall',
      name: 'TimeWall Micro-Tasks',
      badge: '🎯 MUDAH',
      subtitle: 'Klik iklan, tugas mikro & survey harian bayaran tinggi.',
      rewardRange: 'Rp 200 - Rp 50.000 / Tugas',
      gradientColors: [Color(0xFF059669), Color(0xFF10B981)],
      icon: Icons.task_alt_rounded,
      baseUrl: 'https://timewall.io/users/login?oid=YOUR_TIMEWALL_OID&uid={USER_ID}',
    ),
    OfferwallProviderItem(
      id: 'adgate',
      name: 'AdGate Media',
      badge: '💎 PREMIUM',
      subtitle: 'Selesaikan level game populer & penawaran eksklusif.',
      rewardRange: 'Rp 1.000 - Rp 200.000 / Misi',
      gradientColors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
      icon: Icons.diamond_rounded,
      baseUrl: 'https://wall.adgaterewards.com/YOUR_ADGATE_WALL_CODE/{USER_ID}',
    ),
    OfferwallProviderItem(
      id: 'lootably',
      name: 'Lootably Offerwall',
      badge: '🎁 BONUS TINGGI',
      subtitle: 'Tonton video, kuisioner & uji coba aplikasi baru.',
      rewardRange: 'Rp 400 - Rp 100.000 / Misi',
      gradientColors: [Color(0xFFE11D48), Color(0xFFFB7185)],
      icon: Icons.card_giftcard_rounded,
      baseUrl: 'https://wall.lootably.com/?placementID=YOUR_LOOTABLY_ID&sid={USER_ID}',
    ),
    OfferwallProviderItem(
      id: 'ayetstudios',
      name: 'ayeT-Studios',
      badge: '🎮 GAMING CPA',
      subtitle: 'Misi instalasi & pencapaian level aplikasi Android.',
      rewardRange: 'Rp 1.000 - Rp 120.000 / Misi',
      gradientColors: [Color(0xFFD97706), Color(0xFFFBBF24)],
      icon: Icons.sports_esports_rounded,
      baseUrl: 'https://www.ayetstudios.com/offers/web_offerwall/YOUR_AYET_ADSLOT?external_identifier={USER_ID}',
    ),
  ];

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

  void _openOfferwallProvider(OfferwallProviderItem provider) {
    final userId = widget.adsController.pairToken.isNotEmpty
        ? widget.adsController.pairToken
        : 'guest_user';
    final targetUrl = provider.buildUrl(userId);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: provider.gradientColors),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(provider.icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          provider.rewardRange,
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📌 Cara Kerja Otomatis:',
                      style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '1. Pilih penawaran aplikasi / survey di halaman Offerwall.\n'
                      '2. Selesaikan instruksi sampai tuntas.\n'
                      '3. Saldo Rupiah otomatis masuk ke akun Anda melalui Postback Server.',
                      style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, height: 1.45),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'SubID Tracking Anda: $userId',
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: provider.gradientColors.first,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    DeepLinkService.openExternalUrl(targetUrl);
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: Text(
                    'Buka ${provider.name}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.adsController;
    const bgDark = Color(0xFF070B14);

    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. HEADER OFFERWALL & SALDO
              _buildHeader(controller),
              const SizedBox(height: 16),

              // 2. QUICK REWARDED VIDEO ADMOB CARD
              _buildQuickVideoCard(controller),
              const SizedBox(height: 20),

              // 3. JUDUL DAFTAR MITRA OFFERWALL (TOROX, CPALEAD, DLL)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '🔥 Jaringan Offerwall & CPA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Auto Postback',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Selesaikan tugas install aplikasi, game, atau survey dari Torox, CPALead & mitra resmi untuk klaim saldo besar.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.35),
              ),
              const SizedBox(height: 14),

              // 4. GRID / LIST KARTU PROVIDER OFFERWALL
              ..._offerwallProviders.map((p) => _buildOfferwallCard(p)),

              const SizedBox(height: 12),

              // 5. BANNER AD
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: const BannerAdWidget(),
              ),
              const SizedBox(height: 16),

              // 6. KARTU SINKRONISASI TELEGRAM
              _buildTelegramSyncCard(controller),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AdsController controller) {
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
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offerwall & CPA Hub',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Torox • CPALead • TimeWall • AdGate',
                  style: TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1A30),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFF9900).withOpacity(0.35)),
          ),
          child: Row(
            children: [
              const Icon(Icons.monetization_on_rounded, color: Color(0xFFFF9900), size: 16),
              const SizedBox(width: 6),
              Text(
                'Rp ${controller.balanceAds.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickVideoCard(AdsController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF141E33), Color(0xFF0B1120)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFF5E00).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFF5E00).withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFFFF9E00), size: 28),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Video Iklan Instan (AdMob)',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 3),
                Text(
                  'Tonton video singkat untuk klaim saldo instan.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5E00),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: controller.isLoading ? null : () => controller.watchRewardedAd(context),
            child: controller.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Tonton',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferwallCard(OfferwallProviderItem provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: provider.gradientColors.first.withOpacity(0.32)),
        boxShadow: [
          BoxShadow(
            color: provider.gradientColors.first.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openOfferwallProvider(provider),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: provider.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(provider.icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              provider.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: provider.gradientColors.first.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              provider.badge,
                              style: TextStyle(
                                color: provider.gradientColors.last,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider.subtitle,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        provider.rewardRange,
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: provider.gradientColors),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Buka',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTelegramSyncCard(AdsController controller) {
    final token = controller.pairToken.isNotEmpty ? controller.pairToken : 'Generating...';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF0284C7).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.telegram, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sinkronisasi Saldo ke Telegram Bot',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
                const SizedBox(height: 2),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: token));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('SubID / Token Pairing disalin ke clipboard!')),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () => DeepLinkService.openBotPairing(controller.pairToken),
            child: const Text('Pair Bot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
