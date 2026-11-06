import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/deep_link_service.dart';

/// AdsController: State management untuk traffic retention nonton video iklan,
/// pembatasan limit harian (maks 10 iklan), sinkronisasi saldo ke Cloudflare Worker,
/// dan penguncian tombol dengan Modal Konversi Afiliasi 2-Tier saat kuota habis.
class AdsController extends ChangeNotifier {
  // URL Endpoint Cloudflare Worker Anda
  final String backendBaseUrl;

  AdsController({this.backendBaseUrl = 'https://appdockhub.yourdomain.workers.dev'});

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

    // Generate token unik perangkat jika belum ada
    String? token = prefs.getString(keyPairToken);
    if (token == null || token.isEmpty) {
      token = 'DEV_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}';
      await prefs.setString(keyPairToken, token);
    }
    _pairToken = token;

    // Cek tanggal lokal untuk auto-reset harian
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
  }

  /// Memutar Rewarded Ad & mencatat reward ke Backend
  Future<void> watchRewardedAd(BuildContext context) async {
    if (isLimitReached) {
      showConversionFunnelDialog(context);
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // 1. SIMULASI / INTEGRASI SDK AD NETWORK (AdMob / Unity / AppLovin)
      // Pada implementasi produksi, panggil:
      // await RewardedAd.load(...) -> rewardedAd.show(onUserEarnedReward: ...)
      await Future.delayed(const Duration(seconds: 2)); // Simulasi ad playback

      // 2. SINKRONISASI KE CLOUDFLARE WORKER ENDPOINT (/api/ads/reward)
      final response = await http.post(
        Uri.parse('$backendBaseUrl/api/ads/reward'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'pairToken': _pairToken,
          'rewardAmount': 300, // Rp 300 per ad
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        _adsWatchedToday = data['adsWatchedToday'] ?? (_adsWatchedToday + 1);
        _balanceAds = (data['currentBalanceAds'] as num?)?.toDouble() ?? (_balanceAds + 300);
        _isLimitReached = data['limitReached'] ?? (_adsWatchedToday >= maxDailyQuota);

        // Simpan state ke SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(keyWatchedCount, _adsWatchedToday);
        await prefs.setDouble(keyBalance, _balanceAds);

        notifyListeners();

        // Tampilkan snackbar reward
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF10B981),
              content: Text(
                '🎉 Reward +Rp 300 berhasil masuk! Sisa kuota: $remainingQuota iklan.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        }

        // 3. JIKA KUOTA SUDAH HABIS (10/10), PICU POP-UP KONVERSI AFILIASI
        if (isLimitReached && context.mounted) {
          showConversionFunnelDialog(context);
        }
      } else {
        throw Exception('Server mengembalikan kode status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error watching ad: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Gagal memproses reward: $e'),
          ),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// DIALOG POP-UP KONVERSI: Mengarahkan pengguna dari iklan ke program afiliasi 2-tier
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
                // Icon Lock Badge
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_clock_rounded,
                    color: Colors.amber,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),

                // Judul Pop-up
                const Text(
                  'Kuota 10 Iklan Hari Ini Habis!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                // Copywriting Friction to Conversion
                const Text(
                  'Mengapa membatasi diri pada ratusan rupiah jika Anda bisa mencetak '
                  'komisi puluhan hingga ratusan ribu setiap hari?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 16),

                // Box Benefit Afiliasi 2-Tier
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
                              'Tier 1: Komisi Langsung 30%\n(Rp 29.700 per closing software)',
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

                // Tombol CTA Meluncur ke Telegram Bot
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

                // Tombol Tutup
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
