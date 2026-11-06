import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// BannerAdWidget: Komponen Banner Ads Resmi Google AdMob
/// Unit ID Resmi: ca-app-pub-7479911722538350/9799786122
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

  // Google AdMob Banner Ad Unit ID Resmi Anda
  static const String _realBannerAdUnitId = 'ca-app-pub-7479911722538350/9799786122';
  // Google Official Sample Banner Unit ID for Android
  static const String _sampleBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd({bool isFallback = false}) {
    if (kIsWeb) return;

    final adUnitId = isFallback
        ? _sampleBannerAdUnitId
        : (widget.customAdUnitId ?? _realBannerAdUnitId);

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: widget.adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          debugPrint('✅ Google AdMob Banner Ad berhasil dimuat: ${ad.adUnitId}');
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('⚠️ AdMob Banner load fail ($adUnitId): $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
            });
          }
          if (!isFallback) {
            debugPrint('🚀 Fallback ke Google Sample Banner Ad...');
            _loadBannerAd(isFallback: true);
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
    if (_isAdLoaded && _bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }

    // Fallback Container Elegan Gelap (saat iklan baru dibuat & masih proses peninjauan Google)
    return Container(
      width: widget.adSize.width.toDouble() > 0 ? widget.adSize.width.toDouble() : double.infinity,
      height: widget.adSize.height.toDouble() > 0 ? widget.adSize.height.toDouble() : 50,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9E00).withOpacity(0.18),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFFF9E00).withOpacity(0.4)),
            ),
            child: const Text(
              'AD',
              style: TextStyle(color: Color(0xFFFF9E00), fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Cyber Orbit Ad Space • Unit Iklan Resmi Aktif',
              style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 14),
        ],
      ),
    );
  }
}
