import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../controllers/ads_controller.dart';
import '../services/deep_link_service.dart';
import '../widgets/banner_ad_widget.dart';

/// Model Provider Offerwall, Smartlink & CPA
class OfferwallProviderItem {
  final String id;
  final String name;
  final String badge;
  final String subtitle;
  final String rewardRange;
  final List<Color> gradientColors;
  final IconData icon;
  final String baseUrl;
  final String? embeddedHtml;

  const OfferwallProviderItem({
    required this.id,
    required this.name,
    required this.badge,
    required this.subtitle,
    required this.rewardRange,
    required this.gradientColors,
    required this.icon,
    required this.baseUrl,
    this.embeddedHtml,
  });

  String buildUrl(String userId) => baseUrl.replaceAll('{USER_ID}', Uri.encodeComponent(userId));

  String? buildHtml(String userId) {
    if (embeddedHtml == null) return null;
    return embeddedHtml!.replaceAll('{USER_ID}', Uri.encodeComponent(userId));
  }
}

/// Layar In-App WebView untuk menampilkan Offerwall / Script CPA langsung di dalam APK
/// tanpa membuka browser eksternal.
class InAppOfferwallViewer extends StatefulWidget {
  final String title;
  final String? url;
  final String? htmlContent;
  final String subId;
  final Color accentColor;

  const InAppOfferwallViewer({
    Key? key,
    required this.title,
    this.url,
    this.htmlContent,
    required this.subId,
    required this.accentColor,
  }) : super(key: key);

  @override
  State<InAppOfferwallViewer> createState() => _InAppOfferwallViewerState();
}

class _InAppOfferwallViewerState extends State<InAppOfferwallViewer> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF070B14))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      );

    if (widget.htmlContent != null && widget.htmlContent!.isNotEmpty) {
      _controller.loadHtmlString(
        widget.htmlContent!,
        baseUrl: 'https://playabledownload.com/',
      );
    } else if (widget.url != null && widget.url!.isNotEmpty) {
      _controller.loadRequest(Uri.parse(widget.url!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
            ),
            Text(
              'ID: ${widget.subId}',
              style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Muat Ulang',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: () {
              setState(() => _isLoading = true);
              if (widget.htmlContent != null && widget.htmlContent!.isNotEmpty) {
                _controller.loadHtmlString(
                  widget.htmlContent!,
                  baseUrl: 'https://playabledownload.com/',
                );
              } else {
                _controller.reload();
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: widget.accentColor),
                  const SizedBox(height: 12),
                  const Text(
                    'Memuat Misi Offerwall...',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// AdsHubScreen (Offerwall & Smartlink Center):
/// Menampilkan jaringan yang sudah ACC & Instant Approval langsung di dalam APK (In-App WebView):
/// CPAGrip (ID 1920856), OGAds, Adsterra, Monetag, Mobidea, CPALead, dan TimeWall.
class AdsHubScreen extends StatefulWidget {
  final AdsController adsController;

  const AdsHubScreen({Key? key, required this.adsController}) : super(key: key);

  @override
  State<AdsHubScreen> createState() => _AdsHubScreenState();
}

class _AdsHubScreenState extends State<AdsHubScreen> {
  // Script HTML Resmi CPAGrip Anda (ID: 1920856) dengan dukungan Tracking SubID otomatis
  static const String _cpaGripHtmlTemplate = '''<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>CPAGrip Offerwall</title>
  <style>
    html, body {
      margin: 0;
      padding: 0;
      width: 100%;
      height: 100%;
      background-color: #070B14;
      color: #ffffff;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    }
  </style>
</head>
<body>
  <script type="text/javascript">var lck = false;</script>
  <script type="text/javascript" src="https://playabledownload.com/script_include.php?id=1920856&tracking_id={USER_ID}"></script>
  <script type="text/javascript">if(!lck){top.location = 'https://playabledownload.com/help/ablk.php?lkt=4'; }</script>
  <noscript>Please enable JavaScript to access this page.<meta http-equiv="refresh" content="0;url=https://playabledownload.com/help/enable_javascript.php?lkt=4" ></meta></noscript>
</body>
</html>''';

  static const List<OfferwallProviderItem> _offerwallProviders = [
    OfferwallProviderItem(
      id: 'cpagrip',
      name: 'CPAGrip Offerwall',
      badge: '🔥 AKTIF & INSTAN',
      subtitle: 'Selesaikan misi aplikasi, kuisioner singkat & klaim reward langsung di dalam aplikasi.',
      rewardRange: 'Rp 500 - Rp 85.000 / Misi',
      gradientColors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
      icon: Icons.card_giftcard_rounded,
      baseUrl: 'https://playabledownload.com/script_include.php?id=1920856&tracking_id={USER_ID}',
      embeddedHtml: _cpaGripHtmlTemplate,
    ),
    OfferwallProviderItem(
      id: 'ogads',
      name: 'OGAds Mobile Offerwall',
      badge: '🔥 TOP MOBILE CPI',
      subtitle: 'Install aplikasi Android & selesaikan misi singkat.',
      rewardRange: 'Rp 500 - Rp 100.000 / Misi',
      gradientColors: [Color(0xFFFF5E00), Color(0xFFFF9900)],
      icon: Icons.phone_android_rounded,
      baseUrl: 'https://locked1.com/cl/i/YOUR_OGADS_LOCKER_ID?aff_sub4={USER_ID}',
    ),
    OfferwallProviderItem(
      id: 'adsterra',
      name: 'Adsterra Smartlink',
      badge: '⚡ INSTANT TASK',
      subtitle: 'Kunjungi halaman sponsor & klaim bonus kunjungan.',
      rewardRange: 'Rp 100 - Rp 25.000 / Tugas',
      gradientColors: [Color(0xFFE11D48), Color(0xFFFB7185)],
      icon: Icons.ads_click_rounded,
      baseUrl: 'https://www.highratecpm.com/YOUR_ADSTERRA_SMARTLINK_KEY?subid={USER_ID}',
    ),
    OfferwallProviderItem(
      id: 'monetag',
      name: 'Monetag Direct Task',
      badge: '💎 CEPAT CAIR',
      subtitle: 'Buka penawaran sponsor instan & selesaikan aksi mudah.',
      rewardRange: 'Rp 100 - Rp 30.000 / Tugas',
      gradientColors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
      icon: Icons.flash_on_rounded,
      baseUrl: 'https://otieu.com/4/YOUR_MONETAG_ZONE_ID?var={USER_ID}',
    ),
    OfferwallProviderItem(
      id: 'mobidea',
      name: 'Mobidea SmartCPA',
      badge: '🚀 HIGH PAYOUT',
      subtitle: 'Penawaran aplikasi & konten premium otomatis sesuai operator.',
      rewardRange: 'Rp 500 - Rp 120.000 / Misi',
      gradientColors: [Color(0xFF059669), Color(0xFF10B981)],
      icon: Icons.rocket_launch_rounded,
      baseUrl: 'https://www.mobidea.com/smartlink/?id=YOUR_MOBIDEA_ID&subid={USER_ID}',
    ),
    OfferwallProviderItem(
      id: 'cpalead',
      name: 'CPALead Offerwall',
      badge: '✅ AUTO APPROVE',
      subtitle: 'Survey singkat, unduh aplikasi & penawaran CPA instan.',
      rewardRange: 'Rp 300 - Rp 75.000 / Misi',
      gradientColors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
      icon: Icons.bolt_rounded,
      baseUrl: 'https://www.cpalead.com/mobile/locker/?pub=YOUR_CPALEAD_ID&subid={USER_ID}',
    ),
    OfferwallProviderItem(
      id: 'timewall',
      name: 'TimeWall Micro-Tasks',
      badge: '🎯 TUGAS HARIAN',
      subtitle: 'Klik iklan, lihat situs web & tugas mikro harian.',
      rewardRange: 'Rp 200 - Rp 50.000 / Tugas',
      gradientColors: [Color(0xFFD97706), Color(0xFFFBBF24)],
      icon: Icons.task_alt_rounded,
      baseUrl: 'https://timewall.io/users/login?oid=YOUR_TIMEWALL_OID&uid={USER_ID}',
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

  /// Langsung membuka Offerwall di dalam aplikasi (In-App WebView) tanpa keluar ke browser
  void _openOfferwallInApp(OfferwallProviderItem provider) {
    final userId = widget.adsController.pairToken.isNotEmpty
        ? widget.adsController.pairToken
        : 'guest_user';
    final targetUrl = provider.buildUrl(userId);
    final targetHtml = provider.buildHtml(userId);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InAppOfferwallViewer(
          title: provider.name,
          url: targetUrl,
          htmlContent: targetHtml,
          subId: userId,
          accentColor: provider.gradientColors.first,
        ),
      ),
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

              // 3. JUDUL DAFTAR MITRA OFFERWALL (CPAGRIP, OGADS, ADSTERRA, MONETAG, MOBIDEA, DLL)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '🔥 Offerwall & Smartlink Tugas',
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
                      'In-App Viewer',
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
                'Klik salah satu jaringan di bawah untuk membuka daftar misi langsung di dalam aplikasi tanpa keluar ke browser.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.35),
              ),
              const SizedBox(height: 14),

              // 4. LIST KARTU PROVIDER OFFERWALL
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
                  'CPAGrip • OGAds • Adsterra • Monetag',
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
          onTap: () => _openOfferwallInApp(provider),
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
