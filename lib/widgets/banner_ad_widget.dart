import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// BannerAdWidget: Komponen Banner Ads Responsif untuk Penghasilan Tambahan
/// Mendukung Google Mobile Ads SDK (AdMob) dengan fallback visual jika iklan sedang loading/offline.
class BannerAdWidget extends StatefulWidget {
  final AdSize adSize;
  final String? customAdUnitId;

  const BannerAdWidget({
    Key? key,
    this.adSize = AdSize.banner, // 320x50 standar banner
    this.customAdUnitId,
  }) : super(key: key);

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  // Google AdMob Test Banner Unit ID untuk Android
  // Ganti dengan Ad Unit ID asli Anda dari dashboard AdMob saat rilis
  static const String _defaultTestAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    // Hindari load pada lingkungan web / non-mobile
    if (kIsWeb) return;

    final adUnitId = widget.customAdUnitId ?? _defaultTestAdUnitId;

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: widget.adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          debugPrint('✅ Banner Ad berhasil dimuat: ${ad.adUnitId}');
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('❌ Gagal memuat Banner Ad: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
            });
          }
        },
      ),
    );

    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Jika iklan berhasil dimuat, tampilkan widget iklan asli
    if (_isAdLoaded && _bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }

    // Fallback Mock Banner (Placeholder Elegan bertema Gelap saat AdMob loading)
    return Container(
      width: widget.adSize.width.toDouble() > 0 ? widget.adSize.width.toDouble() : double.infinity,
      height: widget.adSize.height.toDouble() > 0 ? widget.adSize.height.toDouble() : 50,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.amber.withOpacity(0.4)),
            ),
            child: const Text(
              'AD',
              style: TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'AppDock Hub Monetization Space • Penghasilan Pasif Tambahan',
              style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.open_in_new_rounded, color: Colors.grey, size: 14),
        ],
      ),
    );
  }
}
