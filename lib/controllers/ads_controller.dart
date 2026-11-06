import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/currency_service.dart';
import '../services/deep_link_service.dart';
import '../services/security_service.dart';

/// AdsController: State management traffic retention, limit 10 iklan harian,
/// dan Smart Rewarded Ad Engine:
/// 1. Mencoba memutar Real AdMob Rewarded Ad (jika akun AdMob sudah disetujui).
/// 2. Jika AdMob belum ready / belum ada di Play Store, otomatis menayangkan
///    Full-Screen Rewarded Interstitial Timer (15 detik) dari jaringan aktif Anda
///    (Monetag / Adsterra / Mobidea) sehingga Anda tetap menghasilkan uang nyata!
class AdsController extends ChangeNotifier {
  final String backendBaseUrl;

  AdsController({this.backendBaseUrl = 'https://appdockhub.yourdomain.workers.dev'});

  // Identitas Unik Game Ini (Untuk Opsi A: Dompet Terpisah per Game di Bot Telegram)
  // Saat rilis game baru tiap minggu, cukup ganti gameId & gameName di sini!
  static const String gameId = 'cyber_orbit';
  static const String gameName = 'Cyber Orbit';

  // Unit ID Rewarded Resmi Google AdMob Anda
  static const String realRewardedAdUnitId = 'ca-app-pub-7479911722538350/7720417695';

  // Daftar URL Monetisasi Aktif Anda (Tanpa perlu Play Store!)
  // Bergantian otomatis setiap kali pemain menonton iklan naik game/level
  static const List<String> activeRewardedUrls = [
    // 1. Monetag Direct Link Resmi Anda
    'https://uplcm.com/4/12204291?var={USER_ID}',
    // 2. Adsterra Smartlink Resmi Anda
    'https://asiafilm.org/4/86ef29736adda09bc43e293a1e401d5e?subid={USER_ID}',
    // 3. Mobidea Smartlink Resmi Anda
    'https://www.avoidthecroud.help/?sl=6169576-d57f7&pub_click_id={USER_ID}&site=cyber_orbit&pub_sub_id={USER_ID}',
  ];

  static const int maxDailyQuota = 60;
  static const double maxDailyRewardIdr = 600.0;
  // 5 Iklan Pertama Harian dibuat besar agar menarik user:
  // Iklan 1 = Rp 50, Iklan 2 = Rp 20, Iklan 3 = Rp 40, Iklan 4 = Rp 25, Iklan 5 = Rp 30 (Total 5 awal = Rp 165)
  static const List<int> initialBoostRewards = [50, 20, 40, 25, 30];

  static const String keyPairToken = 'app_pair_token';
  static const String keyWatchedCount = 'ads_watched_today';
  static const String keyLastDate = 'last_ad_watch_date';
  static const String keyBalance = 'local_ads_balance';
  static const String keyRotationTurn = 'ad_network_rotation_turn';
  static const String keyDailyEarnedIdr = 'daily_earned_idr';

  String _pairToken = '';
  int _adsWatchedToday = 0;
  double _dailyEarnedIdr = 0.0;
  double _balanceAds = 0.0;
  bool _isLoading = false;
  bool _isLimitReached = false;
  int _urlRotationIndex = 0;

  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;

  // Getters
  String get pairToken => _pairToken;
  int get adsWatchedToday => _adsWatchedToday;
  int get remainingQuota => max(0, maxDailyQuota - _adsWatchedToday);
  double get balanceAds => _balanceAds;
  bool get isLoading => _isLoading;
  bool get isLimitReached => _isLimitReached || _adsWatchedToday >= maxDailyQuota;

  /// Nilai reward rata-rata default (untuk kompatibilitas getter)
  double get rewardPerAd => CurrencyService.adReward;

  /// Menghitung nominal reward dinamis untuk iklan berikutnya:
  /// - Iklan ke-1 s/d ke-5: [Rp 50, Rp 20, Rp 40, Rp 25, Rp 30]
  /// - Iklan ke-6 s/d ke-60: Random antara Rp 2 s/d Rp 30 dengan pengunci target
  ///   sehingga total 60 iklan tepat menghasilkan Rp 600 / hari.
  double _calculateDynamicNextReward() {
    final int adNum = _adsWatchedToday + 1;
    if (adNum >= 1 && adNum <= initialBoostRewards.length) {
      return initialBoostRewards[adNum - 1].toDouble();
    }

    final int remAds = max(1, maxDailyQuota - adNum + 1);
    final int remBudget = max(remAds * 2, (maxDailyRewardIdr - _dailyEarnedIdr).round());

    if (remAds <= 1) {
      return remBudget.clamp(2, 30).toDouble();
    }

    final int minSafe = max(2, remBudget - (remAds - 1) * 30);
    final int maxSafe = min(30, remBudget - (remAds - 1) * 2);
    if (minSafe >= maxSafe) {
      return minSafe.toDouble();
    }

    final double avg = remBudget / remAds;
    final int capMax = min(maxSafe, max(minSafe, (avg * 2.6).round()));
    final rng = Random();
    int val;
    if (rng.nextDouble() < 0.20) {
      val = minSafe + rng.nextInt(max(1, capMax - minSafe + 1));
    } else {
      final int midMax = min(capMax, max(minSafe, (avg * 1.6).round()));
      val = minSafe + rng.nextInt(max(1, midMax - minSafe + 1));
    }
    return val.clamp(minSafe, maxSafe).toDouble();
  }

  /// Durasi tayangan iklan menyesuaikan besarnya nominal reward yang didapat:
  /// Semakin besar reward yang keluar, durasi iklan sedikit lebih lama (10 - 20 detik).
  int _getAdCountdownSecondsForReward(double rewardIdr) {
    if (rewardIdr >= 30) return 20;
    if (rewardIdr >= 15) return 16;
    if (rewardIdr >= 7) return 13;
    return 10;
  }

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
      _dailyEarnedIdr = 0.0;
      await prefs.setString(keyLastDate, todayStr);
      await prefs.setInt(keyWatchedCount, 0);
      await prefs.setDouble(keyDailyEarnedIdr, 0.0);
    } else {
      _adsWatchedToday = prefs.getInt(keyWatchedCount) ?? 0;
      _dailyEarnedIdr = prefs.getDouble(keyDailyEarnedIdr) ?? 0.0;
    }

    _balanceAds = prefs.getDouble(keyBalance) ?? 0.0;
    _urlRotationIndex = prefs.getInt(keyRotationTurn) ?? 0;
    _isLimitReached = _adsWatchedToday >= maxDailyQuota;
    notifyListeners();

    _preloadRealAdMob();
  }

  /// Mencoba memuat unit AdMob asli Anda di latar belakang
  void _preloadRealAdMob() {
    if (kIsWeb || _isAdLoading || _rewardedAd != null) return;
    _isAdLoading = true;

    RewardedAd.load(
      adUnitId: realRewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('✅ [AdMob] Real Rewarded Ad SIAP ditayangkan!');
          _rewardedAd = ad;
          _isAdLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('ℹ️ [AdMob] Real unit belum aktif, siap gunakan Smart Rewarded Monetag/Adsterra.');
          _rewardedAd = null;
          _isAdLoading = false;
        },
      ),
    );
  }

  /// Memutar Rewarded Ad:
  /// - Cek Keamanan Anti-Fraud (2 IP Sama, VPN/Proxy, Cooldown Klik) terlebih dahulu!
  /// - Jika Real AdMob tersedia, putar Real AdMob.
  /// - Jika Real AdMob belum tersedia (karena belum ada URL Play Store), putar
  ///   Smart Rewarded Ad Player 15 Detik (Monetag / Adsterra / Mobidea) yang menghasilkan uang nyata!
  Future<bool> watchRewardedAd(BuildContext context) async {
    if (_isLoading) return false;
    if (isLimitReached) {
      showConversionFunnelDialog(context);
      return false;
    }

    // 0A. Cek Cooldown Anti-Spam Klik Iklan agar akun AdNetwork aman dari Invalid Traffic
    final cooldownRemaining = SecurityService.getRemainingAdCooldown();
    if (cooldownRemaining > 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
            content: Text(
              '⏳ Mohon tunggu $cooldownRemaining detik sebelum memutar iklan berikutnya (Proteksi Anti-Spam).',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
      return false;
    }

    _isLoading = true;
    notifyListeners();

    // 0B. Verifikasi Keamanan: Deteksi Proxy/VPN & Deteksi 2 Akun pada 1 IP yang Sama
    final isSecure = await SecurityService.verifyAndEnforceSecurity(
      context: context,
      backendBaseUrl: backendBaseUrl,
      pairToken: _pairToken,
    );
    if (!isSecure) {
      _isLoading = false;
      notifyListeners();
      return false;
    }

    // Hitung nominal reward dinamis (Iklan 1-5 besar: 50, 20, 40, 25, 30; Iklan 6-60 random Rp 2 - Rp 30 dengan target 60 iklan = Rp 600)
    final double plannedReward = _calculateDynamicNextReward();
    final int dynamicDuration = _getAdCountdownSecondsForReward(plannedReward);

    // ROTASI SELANG-SELING TIAP 1 IKLAN (4 Jaringan Berbeda, Maks 60/Hari = 15 Tayangan/Jaringan):
    // Turn 0: Google AdMob (Jika sudah ready; jika belum ready langsung lompat ke Turn 1)
    // Turn 1: Monetag
    // Turn 2: Adsterra
    // Turn 3: Mobidea
    final int currentTurn = _urlRotationIndex % 4;

    // 1. Giliran Turn 0 -> Putar Real AdMob (hanya 1x lalu giliran berikutnya wajib pindah ke Monetag)
    if (currentTurn == 0 && _rewardedAd != null) {
      _urlRotationIndex = (_urlRotationIndex + 1) % 4;
      SharedPreferences.getInstance().then((p) => p.setInt(keyRotationTurn, _urlRotationIndex));

      final completer = Completer<bool>();
      bool earnedReward = false;
      bool rewardProcessed = false;

      Future<void> processRewardIfNeeded() async {
        if (rewardProcessed) return;
        rewardProcessed = true;
        await _syncRewardToBackend(context, plannedReward);
      }

      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) async {
          _rewardedAd = null;
          if (!earnedReward) {
            await Future.delayed(const Duration(milliseconds: 250));
          }
          if (earnedReward) {
            await processRewardIfNeeded();
          }
          if (!completer.isCompleted) {
            completer.complete(earnedReward);
          }
          Future.delayed(const Duration(milliseconds: 1200), () {
            try {
              ad.dispose();
            } catch (_) {}
            _preloadRealAdMob();
          });
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          try {
            ad.dispose();
          } catch (_) {}
          _rewardedAd = null;
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
          earnedReward = true;
          await processRewardIfNeeded();
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        },
      );

      final result = await completer.future;
      _isLoading = false;
      notifyListeners();
      return result;
    }

    // 2. Giliran Turn 1 (Monetag), Turn 2 (Adsterra), Turn 3 (Mobidea)
    //    (Atau jika Turn 0 tapi AdMob belum siap, otomatis bergeser ke Monetag/Adsterra/Mobidea secara bergantian)
    _isLoading = false;
    notifyListeners();

    if (!context.mounted) return false;

    final int effectiveTurn = (currentTurn == 0) ? 1 : currentTurn;
    final int webNetworkIndex = (effectiveTurn - 1) % activeRewardedUrls.length;

    // Majukan jarum rotasi ke jaringan berikutnya untuk iklan selanjutnya
    _urlRotationIndex = (effectiveTurn + 1) % 4;
    SharedPreferences.getInstance().then((p) => p.setInt(keyRotationTurn, _urlRotationIndex));

    final userId = _pairToken.isNotEmpty ? _pairToken : 'guest_user';
    final rawUrl = activeRewardedUrls[webNetworkIndex];
    final adUrl = rawUrl.replaceAll('{USER_ID}', Uri.encodeComponent(userId));

    final bool? completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _SmartRewardedAdScreen(
          adUrl: adUrl,
          countdownSeconds: dynamicDuration,
        ),
      ),
    );

    if (completed == true) {
      if (context.mounted) {
        await _syncRewardToBackend(context, plannedReward);
      }
      return true;
    }

    return false;
  }

  /// Sinkronisasi Saldo Lokal & Cloudflare Worker Secara Instan
  Future<void> _syncRewardToBackend(BuildContext context, double rewardAmt) async {
    final currencyCode = CurrencyService.current.code;

    // 1. Update state lokal secara instan agar UI & Game langsung merespons tanpa jeda
    SecurityService.markAdFinished();
    _adsWatchedToday += 1;
    _dailyEarnedIdr += rewardAmt;
    _balanceAds += rewardAmt;
    _isLimitReached = _adsWatchedToday >= maxDailyQuota || _dailyEarnedIdr >= maxDailyRewardIdr;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(keyWatchedCount, _adsWatchedToday);
      await prefs.setDouble(keyDailyEarnedIdr, _dailyEarnedIdr);
      await prefs.setDouble(keyBalance, _balanceAds);
    } catch (e) {
      debugPrint('Error saving prefs: $e');
    }

    notifyListeners();

    if (context.mounted) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            content: Text(
              '🎉 Reward ${CurrencyService.format(rewardAmt)} berhasil masuk ke saldo Anda!',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      } catch (_) {}
    }

    // 2. Sinkronisasi ke Cloudflare Worker di latar belakang (non-blocking)
    unawaited(_postRewardToServer(rewardAmt, currencyCode));
  }

  Future<void> _postRewardToServer(double rewardAmt, String currencyCode) async {
    try {
      final response = await http
          .post(
            Uri.parse('$backendBaseUrl/api/ads/reward'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'pairToken': _pairToken,
              'gameId': gameId,
              'gameName': gameName,
              'rewardAmount': rewardAmt,
              'currency': currencyCode,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['currentBalanceAds'] != null) {
          _balanceAds = (data['currentBalanceAds'] as num).toDouble();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setDouble(keyBalance, _balanceAds);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Info background sync reward: $e');
    }
  }

  /// DIALOG POP-UP KONVERSI MULTI-CURRENCY AFILIASI 2-TIER
  void showConversionFunnelDialog(BuildContext context) {
    final cur = CurrencyService.current;
    final t1Text = CurrencyService.format(cur.tier1Commission);
    final t2Text = CurrencyService.format(cur.tier2Commission);

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
                  'Batas Iklan Harian Tercapai!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),

                Text(
                  'Ingin penghasilan tanpa batas harian? Dapatkan komisi $t1Text per penjualan langsung + $t2Text bonus tim lewat Program Partner 2-Tier!',
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
                              'Tier 1: Komisi Langsung 30%\n($t1Text per lisensi terjual)',
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
                              'Tier 2: Bonus Pasif Tim 5%\n($t2Text dari penjualan tim)',
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
                          'Gabung Afiliasi di Telegram',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Tutup', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Layar Full-Screen Rewarded Ad (15 Detik Countdown)
/// Menayangkan iklan nyata dari Monetag / Adsterra / Mobidea tanpa membutuhkan URL Play Store!
class _SmartRewardedAdScreen extends StatefulWidget {
  final String adUrl;
  final int countdownSeconds;

  const _SmartRewardedAdScreen({
    Key? key,
    required this.adUrl,
    this.countdownSeconds = 15,
  }) : super(key: key);

  @override
  State<_SmartRewardedAdScreen> createState() => _SmartRewardedAdScreenState();
}

class _SmartRewardedAdScreenState extends State<_SmartRewardedAdScreen> {
  late final WebViewController _webController;
  Timer? _timer;
  late int _remainingSeconds;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.countdownSeconds;

    _webController = WebViewController()
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
      )
      ..loadRequest(Uri.parse(widget.adUrl));

    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDone = _remainingSeconds <= 0;
    final double progress = (widget.countdownSeconds - _remainingSeconds) / widget.countdownSeconds;

    return PopScope(
      canPop: isDone,
      child: Scaffold(
        backgroundColor: const Color(0xFF070B14),
        body: SafeArea(
          child: Column(
            children: [
              // TOP BAR REWARDED TIMER (Persis seperti Rewarded Video Player)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF0B1120),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9900).withOpacity(0.18),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFF9900).withOpacity(0.4)),
                          ),
                          child: const Text(
                            'SPONSORED',
                            style: TextStyle(
                              color: Color(0xFFFF9900),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isDone
                              ? '✅ Reward Siap Diklaim!'
                              : 'Tunggu $_remainingSeconds detik untuk lanjut...',
                          style: TextStyle(
                            color: isDone ? const Color(0xFF10B981) : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    // Tombol X / Klaim & Lanjut (Hanya aktif setelah 15 detik selesai)
                    if (isDone)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                        icon: const Icon(Icons.check_circle_rounded, size: 16),
                        label: const Text(
                          'LANJUTKAN ➔',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                      )
                    else
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          '$_remainingSeconds',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Progress Bar Timer
              LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDone ? const Color(0xFF10B981) : const Color(0xFFFF9900),
                ),
              ),

              // Area Tayangan Iklan Aktif (Monetag / Adsterra / Mobidea)
              Expanded(
                child: Stack(
                  children: [
                    WebViewWidget(controller: _webController),
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
      ),
    );
  }
}
