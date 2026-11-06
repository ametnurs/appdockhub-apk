import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/currency_service.dart';
import '../services/deep_link_service.dart';

/// AdsController: State management traffic retention, limit 10 iklan harian,
/// dan otomatisasi konversi mata uang dinamis sesuai negara pengguna (IDR, USD, EUR, MYR, dll).
class AdsController extends ChangeNotifier {
  final String backendBaseUrl;

  AdsController({this.backendBaseUrl = 'https://appdockhub.yourdomain.workers.dev'});

  // Unit ID Rewarded Resmi Google AdMob Anda
  static const String realRewardedAdUnitId = 'ca-app-pub-7479911722538350/7720417695';

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

  /// Nilai reward per 1 video iklan berdasarkan negara pengguna
  double get rewardPerAd => CurrencyService.adReward;

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
          debugPrint('⚠️ AdMob Rewarded load info: $error');
          _rewardedAd = null;
          _isAdLoading = false;
        },
      ),
    );
  }

  /// Memutar Rewarded Ad & mencatat reward lokal ke Backend
  Future<void> watchRewardedAd(BuildContext context) async {
    if (isLimitReached) {
      showConversionFunnelDialog(context);
      return;
    }

    _isLoading = true;
    notifyListeners();

    final completer = Completer<bool>();

    if (_rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          _preloadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _rewardedAd = null;
          _preloadRewardedAd();
          if (!completer.isCompleted) completer.complete(true);
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          debugPrint('🎉 User selesai menonton AdMob Rewarded Ad!');
          if (!completer.isCompleted) completer.complete(true);
        },
      );
    } else {
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

  /// Sinkronisasi Saldo ke Cloudflare Worker
  Future<void> _syncRewardToBackend(BuildContext context) async {
    final rewardAmt = rewardPerAd;
    final currencyCode = CurrencyService.current.code;

    try {
      final response = await http.post(
        Uri.parse('$backendBaseUrl/api/ads/reward'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'pairToken': _pairToken,
          'rewardAmount': rewardAmt,
          'currency': currencyCode,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        _adsWatchedToday = data['adsWatchedToday'] ?? (_adsWatchedToday + 1);
        _balanceAds = (data['currentBalanceAds'] as num?)?.toDouble() ?? (_balanceAds + rewardAmt);
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
                '🎉 Reward ${CurrencyService.format(rewardAmt)} berhasil masuk! Sisa kuota: $remainingQuota.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        }

        if (isLimitReached && context.mounted) {
          showConversionFunnelDialog(context);
        }
      }
    } catch (e) {
      debugPrint('Error sync reward: $e');
      _adsWatchedToday += 1;
      _balanceAds += rewardAmt;
      _isLimitReached = _adsWatchedToday >= maxDailyQuota;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(keyWatchedCount, _adsWatchedToday);
      await prefs.setDouble(keyBalance, _balanceAds);
      notifyListeners();
    }
  }

  /// DIALOG POP-UP KONVERSI MULTI-CURRENCY AFILIASI 2-TIER
  void showConversionFunnelDialog(BuildContext context) {
    final cur = CurrencyService.current;
    final t1Text = CurrencyService.format(cur.tier1Commission);
    final t2Text = CurrencyService.format(cur.tier2Commission);
    final dailyCap = CurrencyService.format(cur.adReward * maxDailyQuota);

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
                  'Daily 10-Ads Limit Reached!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),

                Text(
                  'Why cap yourself at $dailyCap/day? Unlock unlimited earnings ($t1Text per direct sale + $t2Text team bonus) via our 2-Tier Partner Program!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
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
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.monetization_on_rounded, color: Color(0xFFF97316), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Tier 1: Direct Commission 30%\n($t1Text per license sold)',
                              style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.groups_rounded, color: Color(0xFF38BDF8), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Tier 2: Team Passive Bonus 5%\n($t2Text from team member sales)',
                              style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
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
                          'Join Affiliate on Telegram',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Close', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
