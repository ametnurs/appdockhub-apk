import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/about_security_screen.dart';

/// SecurityService: Sistem Pertahanan Anti-Banned Play Store & AdNetwork
/// 1. Deteksi VPN / Tunnel (`tun0`, `ppp0`, `wg0`, `tap0`, `utun`, `pptp`).
/// 2. Deteksi HTTP Proxy Sistem (`http.proxyHost`, `https.proxyHost`, environment proxy).
/// 3. Deteksi IP Publik & ISP/Datacenter (mencegah VPN/Proxy/RDP/Bot).
/// 4. Deteksi 2 Akses Akun/Perangkat pada 1 IP yang Sama via Backend Cloudflare D1.
/// 5. Cooldown Anti-Spam Klik Iklan & Peringatan Keras "Tutup Aplikasi atau Banned Permanen".
class SecurityService {
  static const String _keyLocalWarnings = 'sec_ip_proxy_warnings';
  static const String _keyLocalBanned = 'sec_is_device_banned';
  static const String _keyBanReason = 'sec_ban_reason';

  static bool _isDialogShowing = false;
  static DateTime? _lastAdFinishedTime;
  static bool? _cachedEmulatorResult;
  static DateTime? _lastRemoteSecurityCheck;
  static const int _remoteCacheMinutes = 15;

  /// Cooldown minimal 8 detik antar tayangan iklan agar AdNetwork tidak mendeteksi spam klik/bot
  static const int minAdCooldownSeconds = 8;

  static int getRemainingAdCooldown() {
    if (_lastAdFinishedTime == null) return 0;
    final elapsed = DateTime.now().difference(_lastAdFinishedTime!).inSeconds;
    final remaining = minAdCooldownSeconds - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  static void markAdFinished() {
    _lastAdFinishedTime = DateTime.now();
  }

  /// Cek apakah di perangkat ada interface VPN aktif (tun0, ppp0, wg0, dll)
  static Future<bool> isLocalVpnActive() async {
    if (kIsWeb) return false;
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.any,
      );
      for (final interface in interfaces) {
        final name = interface.name.toLowerCase();
        if (name.contains('tun') ||
            name.contains('tap') ||
            name.contains('ppp') ||
            name.contains('pptp') ||
            name.contains('l2tp') ||
            name.contains('ipsec') ||
            name.contains('wg') ||
            name.contains('wireguard') ||
            name.contains('utun')) {
          debugPrint('🚨 [Security] Interface VPN terdeteksi: ${interface.name}');
          return true;
        }
      }
    } catch (e) {
      debugPrint('Info check VPN interface: $e');
    }
    return false;
  }

  /// Cek apakah perangkat menggunakan Proxy HTTP/SOCKS di pengaturan Wi-Fi/Sistem
  static bool isLocalProxyActive() {
    if (kIsWeb) return false;
    try {
      final env = Platform.environment;
      final httpProxy = env['http_proxy'] ?? env['HTTP_PROXY'] ?? '';
      final httpsProxy = env['https_proxy'] ?? env['HTTPS_PROXY'] ?? '';
      final allProxy = env['all_proxy'] ?? env['ALL_PROXY'] ?? '';
      if (httpProxy.isNotEmpty || httpsProxy.isNotEmpty || allProxy.isNotEmpty) {
        debugPrint('🚨 [Security] Environment Proxy terdeteksi!');
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Cek apakah aplikasi dijalankan di dalam Emulator / Virtual Phone / App Cloner / Parallel Space
  static Future<bool> isEmulatorOrVirtualPhone() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    if (_cachedEmulatorResult != null) return _cachedEmulatorResult!;

    try {
      // 1. Deteksi App Cloner / Dual Space / VirtualApp / Parallel Space / Island dari path direktori internal
      // Path normal Android adalah: /data/user/0/com.appdockhub.ecosystem/... atau /data/data/com.appdockhub.ecosystem/...
      final currentDir = Directory.current.path.toLowerCase();
      final envHome = (Platform.environment['HOME'] ?? '').toLowerCase();
      final combinedPath = '$currentDir $envHome';

      const virtualContainerSignatures = [
        'parallel',
        'virtual',
        'dual',
        'cloner',
        'multiaccount',
        'ludashi',
        'qihoo',
        'dkplugin',
        'excelliance',
        'vmos',
        'x8sandbox',
        'f1vm',
        'vphonegaga',
      ];
      for (final sig in virtualContainerSignatures) {
        if (combinedPath.contains(sig)) {
          debugPrint('🚨 [Security] Virtual Phone / Cloner Path terdeteksi: $sig');
          return true;
        }
      }

      // 2. Deteksi File Pipe / Socket Hardware Emulator (QEMU, Goldfish, Ranchu, Nox, LDPlayer, BlueStacks, MEmu, Genymotion)
      const emulatorFiles = [
        '/dev/socket/qemud',
        '/dev/qemu_pipe',
        '/system/lib/libc_malloc_debug_qemu.so',
        '/sys/qemu_trace',
        '/system/bin/qemu-props',
        '/dev/socket/genyd',
        '/dev/socket/baseband_genyd',
        '/system/bin/nox-prop',
        '/system/bin/ttVM-prop',
        '/system/bin/droid4x-prop',
        '/system/bin/windroyed',
        '/system/bin/microvirt-prop',
        '/system/lib/libnoxd.so',
        '/system/priv-app/LDAppStore',
        '/system/app/LDAppStore',
      ];
      for (final path in emulatorFiles) {
        if (await File(path).exists()) {
          debugPrint('🚨 [Security] File Emulator terdeteksi: $path');
          return true;
        }
      }

      // 3. Cek Arsitektur CPU di /proc/cpuinfo (Emulator PC hampir selalu x86 / x86_64 / Intel / AMD / Hypervisor)
      final cpuInfoFile = File('/proc/cpuinfo');
      if (await cpuInfoFile.exists()) {
        final cpuInfo = (await cpuInfoFile.readAsString()).toLowerCase();
        if (cpuInfo.contains('hypervisor') ||
            cpuInfo.contains('goldfish') ||
            cpuInfo.contains('ranchu') ||
            cpuInfo.contains('intel') ||
            cpuInfo.contains('amd ') ||
            cpuInfo.contains('vbox')) {
          debugPrint('🚨 [Security] CPU Emulator/Virtual terdeteksi di /proc/cpuinfo');
          return true;
        }
      }

      // 4. Cek System Properties Android via getprop (ro.product.model, ro.hardware, ro.build.fingerprint, ro.kernel.qemu)
      final propResult = await Process.run('getprop', []);
      if (propResult.exitCode == 0) {
        final props = propResult.stdout.toString().toLowerCase();
        const emuKeywords = [
          '[ro.kernel.qemu]: [1]',
          'goldfish',
          'ranchu',
          'sdk_gphone',
          'google_sdk',
          'vbox86',
          'nox',
          'bluestacks',
          'ldplayer',
          'memu',
          'genymotion',
          'andywin',
          'droid4x',
          'ttvm',
          'titan',
          'vmos',
          'vphonegaga',
          'x8sandbox',
        ];
        for (final kw in emuKeywords) {
          if (props.contains(kw)) {
            debugPrint('🚨 [Security] Property Emulator/Virtual Phone terdeteksi: $kw');
            return true;
          }
        }
      }
    } catch (e) {
      debugPrint('Info check emulator: $e');
    }

    _cachedEmulatorResult = false;
    return false;
  }

  /// Cek eksternal IP & Proxy/Hosting status melalui ip-api / ipwho.is sebagai lapis kedua
  static Future<Map<String, dynamic>> _checkPublicIpIntelligence() async {
    try {
      final res = await http
          .get(Uri.parse('http://ip-api.com/json/?fields=status,message,country,isp,org,as,proxy,hosting,query'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final isProxy = data['proxy'] == true;
        final isHosting = data['hosting'] == true;
        final ip = (data['query'] ?? '').toString();
        return {
          'ip': ip,
          'isProxyOrVpn': isProxy || isHosting,
          'isp': data['isp'] ?? '',
        };
      }
    } catch (_) {}
    return {'ip': '', 'isProxyOrVpn': false, 'isp': ''};
  }

  /// Menjalankan pemeriksaan keamanan menyeluruh (VPN, Proxy, dan 2 Akses pada 1 IP)
  /// Mengembalikan `true` jika AMAN, atau `false` (serta memunculkan Dialog Peringatan Keras / Banned) jika melanggar!
  static Future<bool> verifyAndEnforceSecurity({
    required BuildContext context,
    required String backendBaseUrl,
    required String pairToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Cek apakah perangkat sudah di-BANNED secara lokal
    final bool localBanned = prefs.getBool(_keyLocalBanned) ?? false;
    if (localBanned) {
      final reason = prefs.getString(_keyBanReason) ??
          'Akun & perangkat ini telah diblokir karena pelanggaran Multi-IP / penggunaan Proxy/VPN.';
      if (context.mounted) {
        _showSecurityEnforcementModal(
          context: context,
          isBanned: true,
          warnings: 3,
          maxWarnings: 3,
          ipAddress: 'BLOCKED',
          message: reason,
        );
      }
      return false;
    }

    // 1B. Cek apakah dijalankan di Emulator / Virtual Phone (LDPlayer, Nox, BlueStacks, VMOS, Parallel Space, dll)
    final bool isEmulatorOrVirtual = await isEmulatorOrVirtualPhone();
    if (isEmulatorOrVirtual) {
      const emuMsg =
          'DILARANG MENGGUNAKAN EMULATOR / VIRTUAL PHONE!\n\n'
          'Sistem mendeteksi aplikasi dijalankan di dalam Emulator PC atau Virtual Phone / App Cloner. '
          'Demi keamanan ekosistem, permainan ini hanya diizinkan pada perangkat HP fisik asli. '
          'Segera tutup aplikasi sekarang atau akun Anda akan di-BANNED permanen!';
      if (context.mounted) {
        _showSecurityEnforcementModal(
          context: context,
          isBanned: true,
          warnings: 3,
          maxWarnings: 3,
          ipAddress: 'EMULATOR / VIRTUAL OS',
          message: emuMsg,
        );
      }
      return false;
    }

    // 2. Deteksi VPN & Proxy Lokal di HP (Berjalan <1ms di lokal HP, 0 beban server)
    final bool vpnActive = await isLocalVpnActive();
    final bool proxyActive = isLocalProxyActive();

    // 2B. Optimasi Skala Besar (Anti-Server Overload):
    // Jika VPN & Proxy lokal aman dan server sudah memverifikasi sesi ini aman dalam 15 menit terakhir,
    // gunakan cache sesi agar tidak membanjiri API server / Cloudflare D1 saat ribuan user bermain bersamaan.
    if (!vpnActive &&
        !proxyActive &&
        _lastRemoteSecurityCheck != null &&
        DateTime.now().difference(_lastRemoteSecurityCheck!).inMinutes < _remoteCacheMinutes) {
      return true;
    }

    // 3. Deteksi IP Publik & Proxy/Datacenter
    final ipIntel = await _checkPublicIpIntelligence();
    final String detectedIp = (ipIntel['ip'] ?? '').toString();
    final bool ipIsProxy = ipIntel['isProxyOrVpn'] == true;

    final bool anyProxyOrVpn = vpnActive || proxyActive || ipIsProxy;

    // 4. Verifikasi ke Cloudflare Worker D1 (/api/security/check) untuk cek:
    //    - Apakah ada 2 akun/perangkat mengakses dari 1 IP yang sama
    //    - Apakah IP termasuk ASN VPN/Proxy
    try {
      final response = await http
          .post(
            Uri.parse('$backendBaseUrl/api/security/check'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'pairToken': pairToken,
              'clientVpnDetected': vpnActive,
              'clientProxyDetected': proxyActive || ipIsProxy,
              'clientIp': detectedIp,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bool allowed = data['allowed'] == true;
        final String status = (data['status'] ?? 'SAFE').toString();
        final String ip = (data['ip'] ?? detectedIp).toString();
        final int warnings = (data['warnings'] is int) ? data['warnings'] as int : 1;
        final int maxWarnings = (data['maxWarnings'] is int) ? data['maxWarnings'] as int : 3;
        final String msg = (data['message'] ?? '').toString();

        if (!allowed || status == 'BANNED' || status == 'DUPLICATE_IP_WARNING' || status == 'PROXY_DETECTED') {
          final bool isBannedNow = status == 'BANNED' || warnings >= maxWarnings;
          await prefs.setInt(_keyLocalWarnings, warnings);
          if (isBannedNow) {
            await prefs.setBool(_keyLocalBanned, true);
            await prefs.setString(_keyBanReason, msg);
          }

          if (context.mounted) {
            _showSecurityEnforcementModal(
              context: context,
              isBanned: isBannedNow,
              warnings: warnings,
              maxWarnings: maxWarnings,
              ipAddress: ip,
              message: msg.isNotEmpty
                  ? msg
                  : 'Terdeteksi akses mencurigakan (2 Perangkat dalam 1 IP atau penggunaan Proxy/VPN). Segera tutup aplikasi sekarang atau akun Anda akan di-BANNED!',
            );
          }
          return false;
        }
      }
    } catch (e) {
      debugPrint('Info backend security check: $e');
    }

    // 5. Fallback penegakan lokal jika backend sedang tidak terjangkau namun VPN/Proxy terdeteksi aktif di HP
    if (anyProxyOrVpn) {
      int warnings = (prefs.getInt(_keyLocalWarnings) ?? 0) + 1;
      await prefs.setInt(_keyLocalWarnings, warnings);
      final bool isBannedNow = warnings >= 3;
      final String msg = isBannedNow
          ? 'AKUN & PERANGKAT ANDA TELAH DI-BANNED PERMANEN karena tetap menggunakan Proxy / VPN ($detectedIp) setelah diperingatkan!'
          : 'PERINGATAN KEAMANAN ($warnings/3): Terdeteksi penggunaan Proxy / VPN / Jaringan Tidak Sah ${detectedIp.isNotEmpty ? "($detectedIp)" : ""}! Matikan Proxy/VPN dan tutup aplikasi sekarang, atau akun Anda akan di-BANNED permanen!';

      if (isBannedNow) {
        await prefs.setBool(_keyLocalBanned, true);
        await prefs.setString(_keyBanReason, msg);
      }

      if (context.mounted) {
        _showSecurityEnforcementModal(
          context: context,
          isBanned: isBannedNow,
          warnings: warnings,
          maxWarnings: 3,
          ipAddress: detectedIp.isNotEmpty ? detectedIp : 'VPN/PROXY',
          message: msg,
        );
      }
      return false;
    }

    // Simpan timestamp verifikasi aman agar hemat kuota server selama 15 menit ke depan
    _lastRemoteSecurityCheck = DateTime.now();
    return true;
  }

  /// Menampilkan Dialog Peringatan Keras (Non-Dismissible) yang mewajibkan user menutup aplikasi
  static void _showSecurityEnforcementModal({
    required BuildContext context,
    required bool isBanned,
    required int warnings,
    required int maxWarnings,
    required String ipAddress,
    required String message,
  }) {
    if (_isDialogShowing) return;
    _isDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: const Color(0xFF090D16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(
                color: isBanned ? const Color(0xFFFF1E56) : const Color(0xFFFF9900),
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: (isBanned ? const Color(0xFFFF1E56) : const Color(0xFFFF9900))
                          .withOpacity(0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isBanned ? Icons.gpp_bad_rounded : Icons.warning_amber_rounded,
                      color: isBanned ? const Color(0xFFFF1E56) : const Color(0xFFFF9900),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isBanned ? 'AKUN DI-BANNED PERMANEN' : 'PERINGATAN KEAMANAN IP & PROXY!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isBanned ? const Color(0xFFFF1E56) : const Color(0xFFFF9900),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (ipAddress.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'IP Terdeteksi: $ipAddress • Pelanggaran: $warnings/$maxWarnings',
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 11,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF1E56).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFF1E56).withOpacity(0.3)),
                    ),
                    child: const Text(
                      '⚠️ Aturan Anti-Fraud:\n'
                      '• Dilarang menginstal atau memainkan game di Emulator PC / Virtual Phone / App Cloner.\n'
                      '• Dilarang mengakses game dengan 2 akun/HP pada 1 IP yang sama.\n'
                      '• Dilarang menggunakan VPN, Proxy, DNS Tunneler, atau Auto-Clicker.\n'
                      '• Pelanggaran ke-3 otomatis memblokir akun & menghanguskan seluruh saldo!',
                      style: TextStyle(
                        color: Color(0xFFFCA5A5),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).push(
                        MaterialPageRoute(
                          builder: (_) => const AboutSecurityScreen(pairToken: 'PROTECTED_DEVICE'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.policy_outlined, color: Color(0xFF38BDF8), size: 16),
                    label: const Text(
                      'Baca Kebijakan Keamanan Resmi (About)',
                      style: TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF1E56),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        _isDialogShowing = false;
                        // Tutup aplikasi segera sesuai aturan keamanan
                        SystemNavigator.pop();
                        exit(0);
                      },
                      icon: const Icon(Icons.power_settings_new_rounded, size: 20),
                      label: const Text(
                        'TUTUP APLIKASI SEKARANG',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      _isDialogShowing = false;
    });
  }
}
