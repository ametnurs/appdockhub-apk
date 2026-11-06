import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/deep_link_service.dart';

/// AdsController: State management untuk traffic retention nonton video iklan,
/// pembatasan limit harian (maks 10 iklan @ Rp 10), integrasi SDK Google AdMob,
/// sinkronisasi saldo ke Cloudflare Worker, dan Modal Konversi Afiliasi 2-Tier.
class AdsController extends ChangeNotifier {
  final String backendBaseUrl;

  AdsController({this.backendBaseUrl = 'https://appdockhub.yourdomain.workers.dev'});

  // Unit ID Rewarded Resmi Google AdMob Anda
  static const String realRewardedAdUnitId = 'ca-app-pub-7479911722538350/7720417695';

  // Nilai Reward Rp 10 per Iklan
  static const double rewardPerAd = 10.0;
  static const int maxDailyQuota = 10;

  static const String keyPairToken = 'app_pair_token';
  static const String keyWatchedCount = 'ads_watched_today';
  static const String keyLastDate = 'last_ad_watch_date';
  static const String keyBalance = 'local_ads_balance';

  String _pairToken = '';
  int _adsWatchedToday = 0;
  double _balanceAds = 0.0;
  bool _isLoading = false;
  bool _isLimitReached = false;

  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;

  // Getters
  String get pairToken => _pairToken;
  int get adsWatchedToday => _adsWatchedToday;
  int get remainingQuota => max(0, maxDailyQuota - _adsWatchedToday);
  double get balanceAds => _balanceAds;
  bool get isLoading => _isLoading;
  bool get isLimitReached => _isLimitReached || _adsWatchedToday >= maxDailyQuota;

  /// Inisialisasi token perangkat & sinkronisasi data lokal
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    String? token = prefs.getString(keyPairToken);
    if (token == null || token.isEmpty) {
      token = 'DEV_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}';
      await prefs.setString(keyPairToken, token);
    }
    _pairToken = token;

    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = prefs.getString(keyLastDate) ?? '';

    if (lastDate != todayStr) {
      _adsWatchedToday = 0;
      await prefs.setString(keyLastDate, todayStr);
      await prefs.setInt(keyWatchedCount, 0);
    } else {
      _adsWatchedToday = prefs.getInt(keyWatchedCount) ?? 0;
    }

    _balanceAds = prefs.getDouble(keyBalance) ?? 0.0;
    _isLimitReached = _adsWatchedToday >= maxDailyQuota;
    notifyListeners();

    // Pre-load Rewarded Ad agar siap diputar saat level selesai
    _preloadRewardedAd();
  }

  void _preloadRewardedAd() {
    if (kIsWeb || _isAdLoading || _rewardedAd != null) return;
    _isAdLoading = true;

    RewardedAd.load(
      adUnitId: realRewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('✅ AdMob Rewarded Ad berhasil di-load!');
          _rewardedAd = ad;
          _isAdLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('⚠️ AdMob Rewarded load error (masih review): $error');
          _rewardedAd = null;
          _isAdLoading = false;
        },
      ),
    );
  }

  /// Memutar Rewarded Ad & mencatat reward Rp 10 ke Backend
  Future<void> watchRewardedAd(BuildContext context) async {
    if (isLimitReached) {
      showConversionFunnelDialog(context);
      return;
    }

    _isLoading = true;
    notifyListeners();

    final completer = Completer<bool>();

    if (_rewardedAd != null) {
      // 1. Tampilkan Iklan AdMob Resmi jika sudah siap
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          _preloadRewardedAd(); // Load untuk putaran berikutnya
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _rewardedAd = null;
          _preloadRewardedAd();
          if (!completer.isCompleted) completer.complete(true); // Fallback reward
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          debugPrint('🎉 User selesai menonton AdMob Rewarded Ad!');
          if (!completer.isCompleted) completer.complete(true);
        },
      );
    } else {
      // Fallback: Jika unit AdMob baru dibuat dan masih butuh waktu 1 jam peninjauan Google
      debugPrint('AdMob belum ready / masih review Google, menggunakan fallback visual 1.5 detik.');
      await Future.delayed(const Duration(milliseconds: 1500));
      completer.complete(true);
      _preloadRewardedAd();
    }

    final rewardEarned = await completer.future;

    if (rewardEarned) {
      await _syncRewardToBackend(context);
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Sinkronisasi Saldo Rp 10 ke Cloudflare Worker
  Future<void> _syncRewardToBackend(BuildContext context) async {
    try {
      final response = await http.post(
        Uri.parse('$backendBaseUrl/api/ads/reward'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'pairToken': _pairToken,
          'rewardAmount': rewardPerAd, // Rp 10 per ad
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        _adsWatchedToday = data['adsWatchedToday'] ?? (_adsWatchedToday + 1);
        _balanceAds = (data['currentBalanceAds'] as num?)?.toDouble() ?? (_balanceAds + rewardPerAd);
        _isLimitReached = data['limitReached'] ?? (_adsWatchedToday >= maxDailyQuota);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(keyWatchedCount, _adsWatchedToday);
        await prefs.setDouble(keyBalance, _balanceAds);

        notifyListeners();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF10B981),
              content: Text(
                '🎉 Reward +Rp ${rewardPerAd.toInt()} berhasil masuk! Sisa kuota: $remainingQuota iklan.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        }

        // Jika kuota mencapai 10/10, picu funnel modal afiliasi
        if (isLimitReached && context.mounted) {
          showConversionFunnelDialog(context);
        }
      }
    } catch (e) {
      debugPrint('Error sync reward: $e');
      // Tetap catat lokal agar pengalaman bermain tidak terganggu
      _adsWatchedToday += 1;
      _balanceAds += rewardPerAd;
      _isLimitReached = _adsWatchedToday >= maxDailyQuota;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(keyWatchedCount, _adsWatchedToday);
      await prefs.setDouble(keyBalance, _balanceAds);
      notifyListeners();
    }
  }

  /// DIALOG POP-UP KONVERSI AFILIASI 2-TIER SAAT KUOTA 10 HABIS
  void showConversionFunnelDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: const Color(0xFF0F172A),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_clock_rounded, color: Colors.amber, size: 36),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Kuota 10 Iklan Hari Ini Habis!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),

                const Text(
                  'Jangan batasi diri hanya dengan Rp 100/hari. Raih Rp 29.700 per penjualan tanpa batas kuota via Program Afiliasi 2-Tier!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(
                    children: const [
                      Row(
                        children: [
                          Icon(Icons.monetization_on_rounded, color: Color(0xFFF97316), size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Tier 1: Komisi Langsung 30%\n(Rp 29.700 per software terjual)',
                              style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.groups_rounded, color: Color(0xFF38BDF8), size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Tier 2: Komisi Pasif Tim 5%\n(Rp 4.950 per closing dari sponsor tim)',
                              style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      DeepLinkService.openAffiliateProgram();
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Mulai Cuan di Telegram',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Nanti Saja', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
