import 'package:flutter/material.dart';
import '../services/deep_link_service.dart';
import '../widgets/banner_ad_widget.dart';

/// WalletScreen: Tab Dompet Digital & Pencairan Saldo
/// Menampilkan saldo transparan dari Iklan Rewarded, Komisi Direct 30%, dan Komisi Pasif 5%,
/// lengkap dengan integrasi pencairan e-wallet & Banner Ads pendukung.
class WalletScreen extends StatelessWidget {
  final double adsBalance;

  const WalletScreen({Key? key, required this.adsBalance}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF080C14);
    const cardColor = Color(0xFF0F172A);
    const primaryOrange = Color(0xFFF97316);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Dompet & Penarikan Saldo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: cardColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner Ads Atas
            const BannerAdWidget(),
            const SizedBox(height: 16),

            // Card Total Saldo
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF065F46), Color(0xFF064E3B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF065F46).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Column(
                children: [
                  const Text('Total Saldo Dapat Ditarik', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(
                    'Rp ${adsBalance.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Minimal Penarikan: Rp 50.000',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Rincian Saldo 3 Sumber
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rincian Sumber Pendapatan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 14),
                  _buildBalanceItem('📺 Saldo Nonton Iklan (APK)', 'Rp ${adsBalance.toStringAsFixed(0)}', Colors.amber),
                  const Divider(color: Colors.white10, height: 16),
                  _buildBalanceItem('🥇 Komisi Afiliasi Direct (30%)', 'Tersinkron di Bot', primaryOrange),
                  const Divider(color: Colors.white10, height: 16),
                  _buildBalanceItem('🥈 Komisi Pasif Tim Sponsor (5%)', 'Tersinkron di Bot', const Color(0xFF38BDF8)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tombol Request Pencairan via Bot Telegram
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
                onPressed: () => DeepLinkService.openAffiliateProgram(),
                icon: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                label: const Text(
                  'Tarik Saldo via Bot Telegram (DANA/BCA)',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceItem(String title, String amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(amount, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}
