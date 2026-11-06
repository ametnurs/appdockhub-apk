import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// DeepLinkService: Menangani navigasi cerdas ke Telegram Bot AppDock Hub
/// untuk keperluan Pairing Token APK, Pembelian Lisensi, maupun Program Afiliasi 2-Tier.
class DeepLinkService {
  static const String botUsername = 'AppDockHub_Bot';

  /// Membuka URL di browser eksternal atau aplikasi Telegram native
  static Future<bool> _launchUrl(String urlString) async {
    final Uri uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Tidak dapat membuka URL: $urlString');
        return false;
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      return false;
    }
  }

  /// 1. Pairing Akun APK ke Telegram Bot via Token Unik
  /// Endpoint Telegram: https://t.me/AppDockHub_Bot?start=pair_<TOKEN>
  static Future<bool> openBotPairing(String pairToken) async {
    final String url = 'https://t.me/$botUsername?start=pair_$pairToken';
    return await _launchUrl(url);
  }

  /// 2. Buka Menu Afiliasi 2-Tier di Bot Telegram
  static Future<bool> openAffiliateProgram([String? uplineId]) async {
    final String startParam = uplineId != null && uplineId.isNotEmpty
        ? 'ref_$uplineId'
        : 'affiliate';
    final String url = 'https://t.me/$botUsername?start=$startParam';
    return await _launchUrl(url);
  }

  /// 3. Buka Katalog Pembelian Software Tertentu (misal: reddit_pro)
  static Future<bool> openSoftwareOrder(String productKey, {String refCode = 'direct'}) async {
    final String url = 'https://t.me/$botUsername?start=buy_${productKey}_ref_$refCode';
    return await _launchUrl(url);
  }
}
