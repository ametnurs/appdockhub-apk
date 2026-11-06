import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/deep_link_service.dart';

/// ActivationScreen: Form Aktivasi Lisensi Digital Terikat HWID (1 Device = 1 License)
/// Sesuai standar keamanan ekosistem AppDock Hub.
class ActivationScreen extends StatefulWidget {
  final String backendBaseUrl;

  const ActivationScreen({
    Key? key,
    this.backendBaseUrl = 'https://appdockhub.yourdomain.workers.dev',
  }) : super(key: key);

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final TextEditingController _hwidController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  bool _isLoading = false;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadDeviceHwid();
  }

  /// Memuat HWID unik perangkat dari SharedPreferences / Hardware
  Future<void> _loadDeviceHwid() async {
    final prefs = await SharedPreferences.getInstance();
    String? hwid = prefs.getString('device_hwid');

    if (hwid == null || hwid.isEmpty) {
      // Buat format HWID terstandarisasi jika belum ada
      final timestamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase();
      hwid = 'RD-HWID-$timestamp';
      await prefs.setString('device_hwid', hwid);
    }

    _hwidController.text = hwid;
  }

  /// Memanggil Endpoint POST /activate di Cloudflare Worker
  Future<void> _activateLicense() async {
    final hwid = _hwidController.text.trim();
    final licenseKey = _licenseController.text.trim().toUpperCase();

    if (hwid.isEmpty || licenseKey.isEmpty) {
      setState(() {
        _statusMessage = 'Harap isi Kode HWID dan License Key!';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${widget.backendBaseUrl}/activate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'hwid': hwid,
          'licenseKey': licenseKey,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_license_active', true);
        await prefs.setString('active_license_key', licenseKey);
        await prefs.setString('active_product', data['product'] ?? 'Software Pro');

        setState(() {
          _isSuccess = true;
          _statusMessage = data['message'] ?? 'Aktivasi Berhasil! 1 Perangkat telah terikat.';
        });
      } else {
        setState(() {
          _isSuccess = false;
          _statusMessage = data['message'] ?? 'Gagal aktivasi. Periksa kembali lisensi Anda.';
        });
      }
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _statusMessage = 'Gagal terhubung ke server aktivasi: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF080C14);
    const cardColor = Color(0xFF0F172A);
    const primaryOrange = Color(0xFFF97316);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Aktivasi Perangkat HWID', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: cardColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo / Icon
                Center(
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primaryOrange, Color(0xFFF59E0B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primaryOrange.withOpacity(0.35),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: const Icon(Icons.security_rounded, color: Colors.white, size: 36),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'AppDock Hub License',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  '1 Device = 1 Physical License Protocol',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: primaryOrange, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8),
                ),
                const SizedBox(height: 24),

                // Notifikasi Status
                if (_statusMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isSuccess ? const Color(0xFF065F46) : const Color(0xFF7F1D1D),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _statusMessage!,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Input Field HWID (Readonly / Copyable)
                const Text(
                  'Hardware ID (HWID) Perangkat Anda',
                  style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _hwidController,
                  readOnly: true,
                  style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.desktop_windows_rounded, color: Colors.grey, size: 18),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.copy_rounded, color: primaryOrange, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _hwidController.text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('HWID disalin ke papan klip!')),
                        );
                      },
                    ),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),

                // Input Field License Key
                const Text(
                  'Masukkan License Key',
                  style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _licenseController,
                  style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'CONTOH: RD-PRO-XXXX-XXXX',
                    hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                    prefixIcon: const Icon(Icons.vpn_key_rounded, color: Colors.grey, size: 18),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),

                // Tombol Submit Aktivasi
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryOrange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                    onPressed: _isLoading ? null : _activateLicense,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Aktivasi Sekarang',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Beli via Telegram
                Center(
                  child: TextButton.icon(
                    onPressed: () => DeepLinkService.openSoftwareOrder('reddit_pro'),
                    icon: const Icon(Icons.shopping_cart_rounded, color: primaryOrange, size: 16),
                    label: const Text(
                      'Belum punya lisensi? Beli via Bot Telegram (Rp 99.000)',
                      style: TextStyle(color: primaryOrange, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
