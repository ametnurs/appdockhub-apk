import 'dart:ui';
import 'package:flutter/foundation.dart';

/// CurrencyConfig: Data konfigurasi mata uang per negara
class CurrencyConfig {
  final String code; // IDR, USD, EUR, etc.
  final String symbol; // Rp, $, €, etc.
  final double adReward; // Nilai reward per 1 ad video
  final double softwarePrice; // Harga software e.g. 99000 or 6.99
  final String softwarePriceFormatted;
  final double tier1Commission; // Komisi 30%
  final double tier2Commission; // Komisi 5%
  final double minWithdrawal; // Minimal penarikan saldo

  const CurrencyConfig({
    required this.code,
    required this.symbol,
    required this.adReward,
    required this.softwarePrice,
    required this.softwarePriceFormatted,
    required this.tier1Commission,
    required this.tier2Commission,
    required this.minWithdrawal,
  });
}

/// CurrencyService: Mendeteksi negara pengguna secara otomatis berdasarkan
/// Device Locale / Sistem Operasi dan menyesuaikan mata uang secara dinamis.
class CurrencyService {
  static CurrencyConfig? _current;

  // Daftar Mata Uang Global Terpopuler
  static final Map<String, CurrencyConfig> _countryMap = {
    // 1. Indonesia
    'ID': const CurrencyConfig(
      code: 'IDR',
      symbol: 'Rp ',
      adReward: 10.0,
      softwarePrice: 99000.0,
      softwarePriceFormatted: 'Rp 99.000',
      tier1Commission: 29700.0,
      tier2Commission: 4950.0,
      minWithdrawal: 50000.0,
    ),
    // 2. Malaysia
    'MY': const CurrencyConfig(
      code: 'MYR',
      symbol: 'RM ',
      adReward: 0.05,
      softwarePrice: 29.90,
      softwarePriceFormatted: 'RM 29.90',
      tier1Commission: 8.97,
      tier2Commission: 1.49,
      minWithdrawal: 15.0,
    ),
    // 3. Philippines
    'PH': const CurrencyConfig(
      code: 'PHP',
      symbol: '₱ ',
      adReward: 0.35,
      softwarePrice: 349.0,
      softwarePriceFormatted: '₱ 349',
      tier1Commission: 104.7,
      tier2Commission: 17.45,
      minWithdrawal: 150.0,
    ),
    // 4. India
    'IN': const CurrencyConfig(
      code: 'INR',
      symbol: '₹ ',
      adReward: 0.50,
      softwarePrice: 499.0,
      softwarePriceFormatted: '₹ 499',
      tier1Commission: 149.7,
      tier2Commission: 24.95,
      minWithdrawal: 250.0,
    ),
    // 5. United Kingdom
    'GB': const CurrencyConfig(
      code: 'GBP',
      symbol: '£ ',
      adReward: 0.005,
      softwarePrice: 5.49,
      softwarePriceFormatted: '£5.49',
      tier1Commission: 1.65,
      tier2Commission: 0.27,
      minWithdrawal: 3.0,
    ),
    // 6. European Union (Germany, France, etc.)
    'DE': const CurrencyConfig(code: 'EUR', symbol: '€ ', adReward: 0.005, softwarePrice: 6.49, softwarePriceFormatted: '€6.49', tier1Commission: 1.95, tier2Commission: 0.32, minWithdrawal: 3.0),
    'FR': const CurrencyConfig(code: 'EUR', symbol: '€ ', adReward: 0.005, softwarePrice: 6.49, softwarePriceFormatted: '€6.49', tier1Commission: 1.95, tier2Commission: 0.32, minWithdrawal: 3.0),
    'ES': const CurrencyConfig(code: 'EUR', symbol: '€ ', adReward: 0.005, softwarePrice: 6.49, softwarePriceFormatted: '€6.49', tier1Commission: 1.95, tier2Commission: 0.32, minWithdrawal: 3.0),
    'IT': const CurrencyConfig(code: 'EUR', symbol: '€ ', adReward: 0.005, softwarePrice: 6.49, softwarePriceFormatted: '€6.49', tier1Commission: 1.95, tier2Commission: 0.32, minWithdrawal: 3.0),
    'NL': const CurrencyConfig(code: 'EUR', symbol: '€ ', adReward: 0.005, softwarePrice: 6.49, softwarePriceFormatted: '€6.49', tier1Commission: 1.95, tier2Commission: 0.32, minWithdrawal: 3.0),
    // 7. Brazil
    'BR': const CurrencyConfig(
      code: 'BRL',
      symbol: 'R\$ ',
      adReward: 0.05,
      softwarePrice: 34.90,
      softwarePriceFormatted: 'R\$ 34,90',
      tier1Commission: 10.47,
      tier2Commission: 1.74,
      minWithdrawal: 15.0,
    ),
  };

  // Default Global Fallback (USD untuk seluruh dunia di luar Indonesia & daftar di atas)
  static const CurrencyConfig _usdGlobalDefault = CurrencyConfig(
    code: 'USD',
    symbol: '\$ ',
    adReward: 0.005, // $0.005 per video
    softwarePrice: 6.99,
    softwarePriceFormatted: '\$6.99',
    tier1Commission: 2.10, // 30% = $2.10
    tier2Commission: 0.35, // 5% = $0.35
    minWithdrawal: 3.00, // Minimal $3
  );

  /// Dapatkan konfigurasi mata uang aktif saat ini
  static CurrencyConfig get current {
    if (_current != null) return _current!;

    try {
      // Deteksi kode negara dari Locale sistem operasi pengguna
      final countryCode = PlatformDispatcher.instance.locale.countryCode?.toUpperCase();
      debugPrint('🌍 Deteksi Negara Pengguna: $countryCode');

      if (countryCode != null && _countryMap.containsKey(countryCode)) {
        _current = _countryMap[countryCode]!;
      } else {
        // Jika user berada di luar negara terdaftar, gunakan standar global USD
        _current = _usdGlobalDefault;
      }
    } catch (e) {
      _current = _usdGlobalDefault;
    }

    return _current!;
  }

  /// Format angka saldo sesuai format mata uang negara pengguna
  static String format(double amount) {
    final cfg = current;
    if (cfg.code == 'IDR') {
      return '${cfg.symbol}${amount.toStringAsFixed(0)}';
    } else {
      return '${cfg.symbol}${amount.toStringAsFixed(3)}';
    }
  }

  /// Simbol mata uang aktif
  static String get symbol => current.symbol;

  /// Nilai reward per 1 video iklan
  static double get adReward => current.adReward;

  /// Format reward singkat (contoh: "+Rp 10" atau "+$0.005")
  static String get formattedReward => '+${format(current.adReward)}';
}
