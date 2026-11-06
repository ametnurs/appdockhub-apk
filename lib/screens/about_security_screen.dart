import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/deep_link_service.dart';

/// AboutSecurityScreen: Halaman Pengaturan, Informasi Aplikasi & Kebijakan Keamanan Resmi.
/// Menjelaskan seluruh protokol keamanan (Anti-Multi IP, Anti-VPN/Proxy, Anti-Emulator/Virtual Phone,
/// dan Sistem 3x Peringatan) secara profesional sesuai standar kepatuhan Google Play & Ad Network.
class AboutSecurityScreen extends StatelessWidget {
  final String pairToken;

  const AboutSecurityScreen({Key? key, required this.pairToken}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF070B14);
    const cardColor = Color(0xFF0F172A);
    const accentCyan = Color(0xFF00F0FF);
    const accentOrange = Color(0xFFFF9900);
    const accentRed = Color(0xFFFF1E56);
    const accentGreen = Color(0xFF10B981);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Pengaturan & Kebijakan Keamanan',
          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. HEADER IDENTITAS APLIKASI & STATUS PROTEKSI
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F1E3A), Color(0xFF091020)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: accentCyan.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: accentCyan.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: accentCyan.withOpacity(0.5), width: 2),
                    ),
                    child: const Icon(Icons.shield_rounded, color: accentCyan, size: 32),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'CYBER ORBIT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Versi 1.2.0 • Sistem Keamanan Anti-Fraud Aktif',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentGreen.withOpacity(0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user_rounded, color: accentGreen, size: 15),
                        SizedBox(width: 6),
                        Text(
                          'Dilindungi oleh Real-Time Security Shield',
                          style: TextStyle(
                            color: accentGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 2. INFORMASI PERANGKAT & AKUN SINKRONISASI (SETTINGS)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tune_rounded, color: accentCyan, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Informasi Perangkat & Akun',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ID Sinkronisasi Perangkat (Pair Token)',
                                style: TextStyle(color: Colors.white54, fontSize: 10.5),
                              ),
                              SizedBox(height: 3),
                            ],
                          ),
                        ),
                        SelectableText(
                          pairToken,
                          style: const TextStyle(
                            color: accentOrange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: pairToken));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('ID Perangkat berhasil disalin ke papan klip.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: const Icon(Icons.copy_rounded, color: Colors.white70, size: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 3. PENJELASAN PROFESIONAL SELURUH PERINGATAN KEAMANAN
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'STANDAR KEAMANAN & KEPATUHAN PENGGUNA',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            _buildPolicyCard(
              icon: Icons.wifi_tethering_error_rounded,
              iconColor: accentOrange,
              title: '1. Kebijakan Jaringan Tunggal (1 IP = 1 Perangkat)',
              badge: 'Anti-Multi Account',
              description:
                  'Demi menjaga kualitas trafik dan mematuhi regulasi pencegahan Invalid Traffic (IVT), satu alamat IP publik hanya diizinkan untuk mengakses 1 perangkat/akun aktif pada hari yang sama.\n\n'
                  '• Peringatan Sistem: Apabila terdeteksi 2 atau lebih perangkat/akun mengakses aplikasi melalui jaringan Wi-Fi, Hotspot/Tethering, atau alamat IP yang sama, sistem akan menghentikan sementara sesi permainan dan menampilkan peringatan untuk segera menutup aplikasi pada salah satu perangkat.',
            ),
            const SizedBox(height: 12),

            _buildPolicyCard(
              icon: Icons.vpn_lock_rounded,
              iconColor: accentRed,
              title: '2. Larangan Penggunaan VPN, Proxy & Server Hosting',
              badge: 'Network Integrity',
              description:
                  'Pengguna wajib menggunakan koneksi internet seluler (ISP Resmi) atau jaringan rumah tangga standar tanpa perantara pemalsu lokasi/jaringan.\n\n'
                  '• Peringatan Sistem: Penggunaan layanan VPN (OpenVPN, WireGuard, TUN/PPP Tunnel), HTTP/SOCKS Proxy, DNS Anonymizer, maupun koneksi melalui IP Cloud/Datacenter akan langsung ditolak oleh sistem keamanan. Anda wajib mematikan layanan VPN/Proxy sebelum membuka kembali aplikasi.',
            ),
            const SizedBox(height: 12),

            _buildPolicyCard(
              icon: Icons.phonelink_erase_rounded,
              iconColor: accentRed,
              title: '3. Larangan Emulator PC, Virtual Phone & App Cloner',
              badge: 'Hardware Verification',
              description:
                  'Aplikasi ini dirancang eksklusif untuk dijalankan pada perangkat ponsel pintar Android fisik asli (Real Physical Device).\n\n'
                  '• Peringatan Sistem: Sistem keamanan tingkat kernel secara otomatis mendeteksi dan memblokir eksekusi di dalam Emulator PC (LDPlayer, BlueStacks, Nox, MEmu, Genymotion, QEMU/AVD), sistem operasi virtual (VMOS, VPhoneGaGa, X8Sandbox, F1VM), serta aplikasi pengganda/kloning (Parallel Space, Dual Space, Multi Accounts, Island).',
            ),
            const SizedBox(height: 12),

            _buildPolicyCard(
              icon: Icons.gpp_bad_rounded,
              iconColor: accentRed,
              title: '4. Larangan Automasi, Auto-Clicker & Modifikasi APK',
              badge: 'Zero Tolerance',
              description:
                  'Segala bentuk penggunaan alat bantu otomatis (Auto-Clicker, Macro, Bot Script), manipulasi memori, atau modifikasi kode sumber aplikasi merupakan pelanggaran berat terhadap Ketentuan Layanan.',
            ),
            const SizedBox(height: 12),

            // 4. MEKANISME 3X PERINGATAN (3-STRIKE ENFORCEMENT)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1A0B12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accentRed.withOpacity(0.45)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentRed.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.warning_amber_rounded, color: accentRed, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Mekanisme Penindakan & Batas Peringatan (3-Strike Policy)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStrikeStep(
                    step: 'Peringatan 1/3 & 2/3',
                    desc:
                        'Akses permainan dan klaim reward dikunci sementara. Pengguna diwajibkan menekan tombol "Tutup Aplikasi Sekarang" dan memperbaiki kondisi perangkat atau jaringan (mematikan VPN, menutup emulator, atau memisahkan koneksi IP).',
                    color: accentOrange,
                  ),
                  const SizedBox(height: 10),
                  _buildStrikeStep(
                    step: 'Pelanggaran 3/3 (Blokir Permanen)',
                    desc:
                        'Apabila peringatan keamanan diabaikan hingga 3 kali, server secara otomatis menetapkan status BANNED PERMANEN pada akun, nomor identitas perangkat (HWID), serta membatalkan seluruh hak pencairan saldo pada akun yang bersangkutan.',
                    color: accentRed,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 5. KEBIJAKAN PRIVASI & KEPATUHAN DATA
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.privacy_tip_rounded, color: accentCyan, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Kebijakan Privasi & Perlindungan Data',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Aplikasi ini memproses verifikasi jaringan (alamat IP publik & ASN) serta parameter integritas perangkat semata-mata untuk mencegah aktivitas penipuan (anti-fraud), melindungi ekosistem kemitraan, dan menjaga keamanan saldo pengguna. Kami tidak mengambil, menyimpan, atau membagikan data pribadi sensitif seperti kontak, pesan, foto, maupun lokasi GPS presisi perangkat Anda.',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 6. TOMBOL BANTUAN & DUKUNGAN RESMI
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: BorderSide(color: accentCyan.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => DeepLinkService.openBotPairing(pairToken),
                    icon: const Icon(Icons.support_agent_rounded, color: accentCyan, size: 18),
                    label: const Text(
                      'Pusat Bantuan Bot',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.check_circle_outline_rounded, color: accentGreen, size: 18),
                    label: const Text(
                      'Saya Mengerti',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String badge,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: iconColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrikeStep({
    required String step,
    required String desc,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
