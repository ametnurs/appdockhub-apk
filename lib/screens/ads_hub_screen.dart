import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../controllers/ads_controller.dart';
import '../services/deep_link_service.dart';
import '../widgets/banner_ad_widget.dart';

/// Model Misi Internal Game (Menyembunyikan merek AdNetwork agar terlihat bawaan asli game)
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

/// Layar In-App WebView untuk menampilkan Misi / Quest langsung di dalam APK
/// tanpa membuka browser eksternal dan tanpa menampilkan nama jaringan iklan.
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
            const Text(
              'Cyber Orbit Official Quest',
              style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.w600),
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
                    'Memuat Misi Quantum Core...',
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

/// AdsHubScreen (Pusat Misi & Hadiah Cyber Orbit):
/// Seluruh nama jaringan iklan (OGAds, CPAGrip, Adsterra, Monetag, Mobidea, dll)
/// disembunyikan (White-Label) sehingga pemain menganggapnya fitur bawaan asli game.
class AdsHubScreen extends StatefulWidget {
  final AdsController adsController;

  const AdsHubScreen({Key? key, required this.adsController}) : super(key: key);

  @override
  State<AdsHubScreen> createState() => _AdsHubScreenState();
}

class _AdsHubScreenState extends State<AdsHubScreen> {
  // Script HTML Internal Server 2 (CPAGrip ID: 1920856) dengan Tracking SubID otomatis
  static const String _questServer2HtmlTemplate = '''<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>Cyber Orbit Quest</title>
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

  // Daftar Misi Bawaan Game (Nama jaringan iklan di-hide sepenuhnya)
  static const List<OfferwallProviderItem> _offerwallProviders = [
    OfferwallProviderItem(
      id: 'quest_server_1',
      name: 'Misi Aplikasi & Game (Server 1)',
      badge: '🔥 REWARD BESAR',
      subtitle: 'Coba aplikasi & game pilihan di HP Anda untuk klaim hadiah saldo utama.',
      rewardRange: 'Rp 500 - Rp 100.000 / Misi',
      gradientColors: [Color(0xFFFF5E00), Color(0xFFFF9900)],
      icon: Icons.phone_android_rounded,
      // OGAds Resmi Anda (https://apptrck.net/cl/i/d23g4o) dengan aff_sub4 untuk tracking otomatis
      baseUrl: 'https://apptrck.net/cl/i/d23g4o?aff_sub4={USER_ID}',
    ),
    OfferwallProviderItem(
      id: 'quest_server_2',
      name: 'Misi Kuisioner & Hadiah (Server 2)',
      badge: '⚡ AKTIF & INSTAN',
      subtitle: 'Selesaikan kuisioner singkat & tantangan harian langsung di dalam game.',
      rewardRange: 'Rp 500 - Rp 85.000 / Misi',
      gradientColors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
      icon: Icons.card_giftcard_rounded,
      // CPAGrip Resmi Anda (ID: 1920856)
      baseUrl: 'https://playabledownload.com/script_include.php?id=1920856&tracking_id={USER_ID}',
      embeddedHtml: _questServer2HtmlTemplate,
    ),
    OfferwallProviderItem(
      id: 'quest_daily_visit',
      name: 'Misi Kunjungan Cepat (Server 3)',
      badge: '💎 MUDAH & AKTIF',
      subtitle: 'Buka halaman misi harian selama beberapa detik untuk klaim ekstra poin.',
      rewardRange: 'Rp 100 - Rp 25.000 / Misi',
      gradientColors: [Color(0xFFE11D48), Color(0xFFFB7185)],
      icon: Icons.ads_click_rounded,
      // Adsterra Smartlink Resmi Anda (https://asiafilm.org/4/86ef29736adda09bc43e293a1e401d5e)
      baseUrl: 'https://asiafilm.org/4/86ef29736adda09bc43e293a1e401d5e?subid={USER_ID}',
    ),
    OfferwallProviderItem(
      id: 'quest_flash',
      name: 'Misi Kilat Quantum (Server 4)',
      badge: '🚀 CEPAT CAIR',
      subtitle: 'Selesaikan tugas mikro interaktif dan dapatkan tambahan saldo langsung.',
      rewardRange: 'Rp 100 - Rp 30.000 / Misi',
      gradientColors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
      icon: Icons.flash_on_rounded,
      // Monetag Direct Link Resmi Anda (https://uplcm.com/4/12204291)
      baseUrl: 'https://uplcm.com/4/12204291?var={USER_ID}',
    ),
    OfferwallProviderItem(
      id: 'quest_special',
      name: 'Misi Spesial Operator (Server 5)',
      badge: '🎯 BONUS TINGGI',
      subtitle: 'Tantangan eksklusif sesuai perangkat & jaringan seluler Anda.',
      rewardRange: 'Rp 500 - Rp 120.000 / Misi',
      gradientColors: [Color(0xFF059669), Color(0xFF10B981)],
      icon: Icons.rocket_launch_rounded,
      // Mobidea Smartlink Resmi Anda (sl=6169576-d57f7)
      baseUrl: 'https://www.avoidthecroud.help/?sl=6169576-d57f7&pub_click_id={USER_ID}&site=cyber_orbit&pub_sub_id={USER_ID}',
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

  /// Membuka Misi langsung di dalam aplikasi (In-App WebView) tanpa keluar ke browser
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
              // 1. HEADER PUSAT MISI & SALDO
              _buildHeader(controller),
              const SizedBox(height: 16),

              // 2. VIDEO BONUS HARIAN
              _buildQuickVideoCard(controller),
              const SizedBox(height: 20),

              // 3. JUDUL DAFTAR MISI BAWAAN GAME
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '🔥 Daftar Misi & Tantangan Berhadiah',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
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
                      'Resmi',
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
                'Selesaikan misi resmi Cyber Orbit di bawah ini untuk mengumpulkan hadiah saldo tambahan dengan cepat.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.35),
              ),
              const SizedBox(height: 14),

              // 4. LIST KARTU MISI (WHITE-LABEL)
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
              child: const Icon(Icons.stars_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pusat Misi & Hadiah',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Cyber Orbit Quantum Quest',
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
                  'Misi Video Bonus Harian',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 3),
                Text(
                  'Tonton tayangan singkat untuk klaim hadiah saldo instan.',
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
                    'Mulai',
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
                                fontSize: 14.5,
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
                    'Mulai',
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
                      const SnackBar(content: Text('ID Akun Game disalin ke clipboard!')),
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
