import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import '../controllers/ads_controller.dart';
import '../services/currency_service.dart';
import '../services/deep_link_service.dart';
import '../services/locale_service.dart';
import 'game_html.dart';

/// CyberOrbitGameScreen: Menjalankan Game Orisinal "Cyber Orbit: Quantum Core"
/// melalui WebView dengan performa 60 FPS Canvas & Web Audio API, terhubung
/// langsung ke Cloudflare D1 Backend, AdMob Rewarded Ads, dan Afiliasi 2-Tier
/// dengan dukungan Multi-Currency & Otomatisasi Bahasa (ID / EN Global).
class CyberOrbitGameScreen extends StatefulWidget {
  final AdsController adsController;

  const CyberOrbitGameScreen({Key? key, required this.adsController}) : super(key: key);

  @override
  State<CyberOrbitGameScreen> createState() => _CyberOrbitGameScreenState();
}

class _CyberOrbitGameScreenState extends State<CyberOrbitGameScreen> {
  late final WebViewController _webViewController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    widget.adsController.initialize();
    widget.adsController.addListener(_onControllerUpdate);

    _initWebView();
  }

  @override
  void dispose() {
    widget.adsController.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF050811))
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (JavaScriptMessage message) {
          _handleGameBridgeMessage(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              // Suntikkan konfigurasi bahasa & mata uang dinamis ke game JavaScript
              final rewardText = CurrencyService.formattedReward;
              final btnClaimText = LocaleService.gameClaimBtn;
              final jsConfig = jsonEncode({
                'rewardText': rewardText,
                'btnClaimText': btnClaimText,
                'titleClear': LocaleService.gameLevelCleared,
                'titleStageClear': LocaleService.gameStageCleared,
                'btnNextStage': LocaleService.gameNextStageBtn,
                'btnNextLevel': LocaleService.gameNextLevelBtn,
                'btnSkip': LocaleService.gameSkipBtn,
                'btnRetry': LocaleService.gameRetryBtn,
                'startDesc': LocaleService.gameStartDesc,
                'startBtn': LocaleService.gameStartBtn,
              });
              _webViewController.runJavaScript("window.setGameLocale($jsConfig);");
            }
          },
        ),
      )
      ..loadHtmlString(cyberOrbitGameHtml);
  }

  /// Menangani pesan dari game JavaScript (Klaim Iklan, Level Selesai, dll)
  void _handleGameBridgeMessage(String rawMessage) async {
    try {
      final data = jsonDecode(rawMessage);
      final event = data['event'];

      if (event == 'WATCH_AD') {
        if (widget.adsController.isLimitReached) {
          widget.adsController.showConversionFunnelDialog(context);
        } else {
          final success = await widget.adsController.watchRewardedAd(context);
          if (success) {
            final rewardText = CurrencyService.format(widget.adsController.rewardPerAd);
            if (mounted) {
              setState(() {});
              // Jalankan transisi ke game berikutnya segera & ulangi setelah Activity fokus kembali
              Future<void> triggerNextStage() async {
                if (!mounted) return;
                try {
                  await _webViewController.runJavaScript(
                    "if(window.onRewardSuccess){window.onRewardSuccess('$rewardText');}"
                  );
                } catch (e) {
                  debugPrint('Error running onRewardSuccess JS: $e');
                }
              }

              await triggerNextStage();
              Future.delayed(const Duration(milliseconds: 350), triggerNextStage);
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFFE11D48),
                  behavior: SnackBarBehavior.floating,
                  content: Text('⚠️ Anda wajib menonton video iklan sampai selesai untuk membuka ronde/level berikutnya!'),
                ),
              );
            }
          }
        }
      } else if (event == 'STAGE_CLEARED') {
        debugPrint('🎯 Game ${data['stage']}/5 di Level ${data['level']} Selesai! Skor: ${data['score']}');
      } else if (event == 'LEVEL_CLEARED') {
        final level = (data['level'] is int) ? data['level'] as int : int.tryParse('${data['level']}') ?? 1;
        debugPrint('🎉 Level $level Selesai Penuh (5/5 Game)! Skor: ${data['score']}');
        _notifyLevelCleared(level);
      } else if (event == 'GAME_OVER') {
        debugPrint('💥 Game Over di Level ${data['level']} (Game ${data['stage'] ?? 1}/5)');
      }
    } catch (e) {
      debugPrint('Error parsing bridge message: $e');
    }
  }

  /// Melaporkan penyelesaian level ke backend Cloudflare D1
  /// Menghitung milestone kelipatan 10 (Lvl 10 = Rp100, Lvl 20..100 = Rp50) untuk sponsor
  Future<void> _notifyLevelCleared(int level) async {
    try {
      final response = await http.post(
        Uri.parse('${widget.adsController.backendBaseUrl}/api/game/level-cleared'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'pairToken': widget.adsController.pairToken,
          'level': level,
        }),
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['milestoneAwarded'] == true && mounted) {
          final bonus = resData['milestoneBonus'] ?? 50;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF00E676),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              content: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🎯 Milestone Level $level Tercapai!',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          'Sponsor pengundang Anda mendapatkan bonus referral Rp $bonus!',
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
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
    } catch (e) {
      debugPrint('Error reporting level cleared: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgDark = Color(0xFF050811);
    final controller = widget.adsController;

    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP HUD GAME STATUS (Saldo & Bahasa Dinamis)
            _buildTopHUD(controller),

            // 2. WEBVIEW GAME ENGINE (HTML5 CANVAS 60 FPS)
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: _webViewController),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(color: Color(0xFF00F0FF)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHUD(AdsController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF070D1C),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Saldo Poin Iklan (Format Mata Uang Dinamis)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1A30),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFF9900).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on_rounded, color: Color(0xFFFF9900), size: 16),
                const SizedBox(width: 6),
                Text(
                  CurrencyService.format(controller.balanceAds),
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

          // Indikator Kuota Iklan Hari Ini (Maks 10)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: controller.isLimitReached
                  ? const Color(0xFF7F1D1D)
                  : const Color(0xFF0284C7).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: controller.isLimitReached
                    ? Colors.redAccent
                    : const Color(0xFF38BDF8).withOpacity(0.4),
              ),
            ),
            child: Text(
              controller.isLimitReached
                  ? LocaleService.adsLimitReached
                  : LocaleService.adsQuota(controller.adsWatchedToday, AdsController.maxDailyQuota),
              style: TextStyle(
                color: controller.isLimitReached ? Colors.amber : const Color(0xFF38BDF8),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Shortcut Pairing Telegram
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => DeepLinkService.openBotPairing(controller.pairToken),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF0284C7).withOpacity(0.4)),
              ),
              child: const Icon(Icons.telegram, color: Color(0xFF38BDF8), size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
