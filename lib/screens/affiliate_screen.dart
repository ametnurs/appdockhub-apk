import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/currency_service.dart';
import '../services/deep_link_service.dart';
import '../widgets/banner_ad_widget.dart';

/// AffiliateScreen: Tab Khusus Program Kemitraan Afiliasi 2-Tier Multi-Currency
/// Otomatis menampilkan mata uang lokal sesuai negara pengguna (IDR, USD, EUR, dll).
class AffiliateScreen extends StatelessWidget {
  final String pairToken;

  const AffiliateScreen({Key? key, required this.pairToken}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF080C14);
    const cardColor = Color(0xFF0F172A);
    const primaryOrange = Color(0xFFF97316);

    final cur = CurrencyService.current;
    final t1Formatted = CurrencyService.format(cur.tier1Commission);
    final t2Formatted = CurrencyService.format(cur.tier2Commission);

    const refLink = 'https://t.me/AppDockHub_Bot?start=affiliate';
    final promoCopy = '🚀 Automate your business with Reddit, Facebook, & TikTok Multi-Screen tools! '
        'Buy official licenses or earn daily passive income via our 2-Tier Partner Program: $refLink';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Program Afiliasi 2-Tier', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: cardColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BannerAdWidget(),
            const SizedBox(height: 16),

            // Card Penjelasan Komisi 2-Tier
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.indigo.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.stars_rounded, color: Colors.amber, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Sistem Komisi Dua Tingkat (2-Tier)',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTierRow('Tier 1 (Direct Seller)', '30%', t1Formatted, 'Setiap Anda menjual 1 lisensi software.', primaryOrange),
                  const Divider(color: Colors.white12, height: 20),
                  _buildTierRow('Tier 2 (Sponsor Pasif)', '5%', t2Formatted, 'Setiap kali teman yang Anda ajak berhasil menjual.', const Color(0xFF38BDF8)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card Hadiah Milestone Level Game Referral (Level 10 - 100)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF064E3B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.videogame_asset_rounded, color: Color(0xFF10B981), size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Bonus Milestone Game Referral',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildMilestoneRow(
                    'Bonus Level Game Teman',
                    'Rp 50 / 10 Lvl',
                    'Diberikan setiap teman Anda menaikkan 10 level game (hingga Level 2000).',
                    const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.stars_rounded, color: Color(0xFF10B981), size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '🔥 Dapatkan komisi pasif terus-menerus setiap kali teman yang Anda undang aktif bermain game!',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card Link Referral Pribadi
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Link Afiliasi Bot Telegram Anda', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(12)),
                    child: const Row(
                      children: [
                        Icon(Icons.link_rounded, color: primaryOrange, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            refLink,
                            style: TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryOrange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => DeepLinkService.openAffiliateProgram(),
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                      label: const Text('Buka Bot & Ambil Kode Unik', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card Swipe File Promosi
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Materi Promosi Siap Sebar (Swipe Copy)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      promoCopy,
                      style: const TextStyle(color: Colors.grey, fontSize: 11, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: promoCopy));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Teks promosi disalin ke clipboard! Siap sebar.')),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 16),
                    label: const Text('Salin Teks Promosi', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierRow(String title, String percent, String rupiah, String subtitle, Color color) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: Center(
            child: Text(percent, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  const Spacer(),
                  Text(rupiah, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneRow(String title, String reward, String subtitle, Color color) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: Center(
            child: Icon(Icons.military_tech_rounded, color: color, size: 24),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  const Spacer(),
                  Text(reward, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }
}
