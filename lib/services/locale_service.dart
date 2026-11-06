import 'dart:ui';
import 'package:flutter/foundation.dart';

/// LocaleService: Deteksi otomatis bahasa perangkat pengguna
/// Default ke Bahasa Indonesia (sesuai ekosistem IDR Rupiah).
class LocaleService {
  static bool? _isIndonesian;

  /// Gunakan Bahasa Indonesia secara default
  static bool get isIndonesian {
    return true;
  }

  // =========================================================================
  // KAMUS TERJEMAHAN UI (DUAL-LANGUAGE DICTIONARY)
  // =========================================================================

  // Navigasi Bottom Dock
  static String get navGame => 'Cyber Orbit';
  static String get navHwid => isIndonesian ? 'Software HWID' : 'HWID License';
  static String get navAffiliate => isIndonesian ? 'Afiliasi 2-Tier' : '2-Tier Partner';
  static String get navWallet => isIndonesian ? 'Dompet' : 'Wallet';

  // Game HTML strings
  static String get gameLevelCleared => isIndonesian ? 'LEVEL SELESAI!' : 'LEVEL CLEARED!';
  static String get gameStageCleared => isIndonesian ? 'GAME SELESAI!' : 'GAME CLEARED!';
  static String get gameClaimBtn => isIndonesian ? '📺 NONTON IKLAN & LANJUTKAN' : '📺 WATCH AD & CONTINUE';
  static String get gameWatchVideo => '';
  static String get gameSkipBtn => isIndonesian ? 'LEWATI KE GAME BERIKUTNYA' : 'NEXT GAME';
  static String get gameNextStageBtn => isIndonesian ? 'LANJUT KE GAME BERIKUTNYA' : 'NEXT GAME';
  static String get gameNextLevelBtn => isIndonesian ? 'LANJUT KE LEVEL BERIKUTNYA' : 'NEXT LEVEL';
  static String get gameRetryBtn => isIndonesian ? 'COBA LAGI' : 'RETRY GAME';
  static String get gameRewardLabel => isIndonesian ? 'Reward Saldo' : 'Reward Balance';
  static String get gameTotalScore => isIndonesian ? 'Total Skor' : 'Total Score';
  static String get gameStartDesc => isIndonesian
      ? 'Selesaikan game di setiap level dan tonton video iklan untuk mengklaim reward saldo serta membuka level berikutnya!'
      : 'Clear games in each level and watch video ads to claim rewarded balance and unlock the next level!';
  static String get gameStartBtn => isIndonesian ? 'MULAI GAME' : 'START GAME';

  // Top HUD
  static String get adsLimitReached => isIndonesian ? '🔒 Kuota 10/10 Habis' : '🔒 Limit 10/10 Reached';
  static String adsQuota(int watched, int max) => isIndonesian ? '📺 Iklan: $watched/$max' : '📺 Ads: $watched/$max';

  // Dompet / Wallet Screen
  static String get walletTitle => isIndonesian ? 'Dompet & Penarikan Saldo' : 'Wallet & Cashout';
  static String get totalWithdrawable => isIndonesian ? 'Total Saldo Dapat Ditarik' : 'Total Withdrawable Balance';
  static String minWithdraw(String formatted) => isIndonesian ? 'Minimal Penarikan: $formatted' : 'Min Cashout: $formatted';
  static String get breakdownTitle => isIndonesian ? 'Rincian Sumber Pendapatan' : 'Earnings Breakdown';
  static String get breakdownAds => isIndonesian ? '📺 Saldo Nonton Iklan (APK)' : '📺 Rewarded Ads Earnings (App)';
  static String get breakdownT1 => isIndonesian ? '🥇 Komisi Afiliasi Direct (30%)' : '🥇 Direct Affiliate Bonus (30%)';
  static String get breakdownT2 => isIndonesian ? '🥈 Komisi Pasif Tim Sponsor (5%)' : '🥈 Passive Team Bonus (5%)';
  static String get syncedInBot => isIndonesian ? 'Tersinkron di Bot' : 'Synced in Bot';
  static String get withdrawBtn => isIndonesian ? 'Tarik Saldo via Bot Telegram' : 'Withdraw via Telegram Bot';

  // Afiliasi / Partner Screen
  static String get affiliateTitle => isIndonesian ? 'Program Afiliasi 2-Tier' : '2-Tier Affiliate Program';
  static String get affiliateCardTitle => isIndonesian ? 'Sistem Komisi Dua Tingkat (2-Tier)' : 'Two-Tier Commission System';
  static String get tier1Title => isIndonesian ? 'Tier 1 (Direct Seller)' : 'Tier 1 (Direct Seller)';
  static String get tier1Desc => isIndonesian ? 'Setiap Anda menjual 1 lisensi software.' : 'Earned on every direct software license sold.';
  static String get tier2Title => isIndonesian ? 'Tier 2 (Sponsor Pasif)' : 'Tier 2 (Team Passive)';
  static String get tier2Desc => isIndonesian ? 'Setiap kali teman yang Anda ajak berhasil menjual.' : 'Earned from sales made by members you invited.';
  static String get yourRefLink => isIndonesian ? 'Link Afiliasi Bot Telegram Anda' : 'Your Telegram Referral Link';
  static String get openBotBtn => isIndonesian ? 'Buka Bot & Ambil Kode Unik' : 'Open Bot & Claim Ref Link';
  static String get promoKitTitle => isIndonesian ? 'Materi Promosi Siap Sebar (Swipe Copy)' : 'Ready-to-Share Marketing Copy';
  static String get copyPromoBtn => isIndonesian ? 'Salin Teks Promosi' : 'Copy Promo Text';
  static String get copiedSnackBar => isIndonesian ? 'Teks promosi disalin ke clipboard!' : 'Promo text copied to clipboard!';

  // Aktivasi HWID / License Screen
  static String get hwidTitle => isIndonesian ? 'Aktivasi Perangkat HWID' : 'HWID Device Activation';
  static String get hwidSubtitle => '1 Device = 1 Physical License Protocol';
  static String get yourHwidLabel => isIndonesian ? 'Hardware ID (HWID) Perangkat Anda' : 'Your Device Hardware ID (HWID)';
  static String get enterKeyLabel => isIndonesian ? 'Masukkan License Key' : 'Enter License Key';
  static String get activateBtn => isIndonesian ? 'Aktivasi Sekarang' : 'Activate Now';
  static String get buyLicenseBtn => isIndonesian ? 'Belum punya lisensi? Beli via Bot Telegram' : 'Need a license? Buy via Telegram Bot';
  static String get hwidCopied => isIndonesian ? 'HWID disalin ke papan klip!' : 'HWID copied to clipboard!';
}
