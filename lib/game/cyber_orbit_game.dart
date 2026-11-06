import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/ads_controller.dart';
import '../services/deep_link_service.dart';
import '../widgets/banner_ad_widget.dart';

/// CyberOrbitGame: Game Kasual Original "Quantum Core: Cyber Orbit"
/// Gameplay: Menembakkan Quantum Energy Node ke cincin orbit yang berputar tanpa bertabrakan.
/// Sesuai kebijakan Google Play Store (Gameplay orisinal, non-deceptive, opt-in rewarded ads).
class CyberOrbitGameScreen extends StatefulWidget {
  final AdsController adsController;

  const CyberOrbitGameScreen({Key? key, required this.adsController}) : super(key: key);

  @override
  State<CyberOrbitGameScreen> createState() => _CyberOrbitGameScreenState();
}

class _CyberOrbitGameScreenState extends State<CyberOrbitGameScreen> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  int _currentLevel = 1;
  int _score = 0;
  int _packetsLeftToShoot = 5;
  double _currentOrbitAngle = 0.0;
  double _rotationSpeed = 1.0; // Radian per detik
  bool _isClockwise = true;

  // Sudut-sudut node yang sudah menempel di orbit (dalam radian)
  final List<double> _attachedPins = [];

  // State permainan
  bool _isGameOver = false;
  bool _isLevelCleared = false;
  bool _isShooting = false;
  double _bulletY = 0.0; // Posisi vertikal peluru animasi

  @override
  void initState() {
    super.initState();
    widget.adsController.initialize();
    widget.adsController.addListener(_onControllerUpdate);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_gameLoop);

    _rotationController.repeat();
    _startLevel(_currentLevel);
  }

  @override
  void dispose() {
    _rotationController.removeListener(_gameLoop);
    _rotationController.dispose();
    widget.adsController.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  /// Inisialisasi parameter level baru
  void _startLevel(int level) {
    setState(() {
      _currentLevel = level;
      _isGameOver = false;
      _isLevelCleared = false;
      _isShooting = false;
      _attachedPins.clear();

      // Formula tingkat kesulitan dinamis
      // Makin tinggi level, node awal lebih banyak dan putaran lebih dinamis
      final initialPinCount = math.min(6, 2 + (level ~/ 2));
      _packetsLeftToShoot = math.min(10, 4 + level);
      _rotationSpeed = 1.2 + (level * 0.15);
      _isClockwise = level % 2 != 0;

      // Sebar pin awal secara merata di orbit
      final angleStep = (2 * math.pi) / initialPinCount;
      for (int i = 0; i < initialPinCount; i++) {
        _attachedPins.add(i * angleStep);
      }
    });
  }

  /// Game Loop 60 FPS untuk rotasi cincin orbit
  void _gameLoop() {
    if (_isGameOver || _isLevelCleared) return;

    final delta = 0.016 * _rotationSpeed; // $\approx$ 60 FPS
    setState(() {
      if (_isClockwise) {
        _currentOrbitAngle = (_currentOrbitAngle + delta) % (2 * math.pi);
      } else {
        _currentOrbitAngle = (_currentOrbitAngle - delta) % (2 * math.pi);
      }
    });
  }

  /// Aksi pemain menembakkan Quantum Node ke arah cincin
  void _shootNode() {
    if (_isShooting || _isGameOver || _isLevelCleared || _packetsLeftToShoot <= 0) return;

    HapticFeedback.lightImpact();

    setState(() {
      _isShooting = true;
    });

    // Node ditembak lurus ke atas tepat di titik bawah orbit ($\pi / 2$ dalam sistem koordinat layar)
    // Sudut relatif terhadap cincin orbit saat ini:
    final landingAngle = ((math.pi / 2) - _currentOrbitAngle) % (2 * math.pi);
    final normalizedLanding = (landingAngle + 2 * math.pi) % (2 * math.pi);

    // Cek tabrakan: jarak sudut minimum dengan node yang sudah ada (toleransi 0.28 radian $\approx 16^\circ$)
    const minSafeAngleDiff = 0.28;
    bool collision = false;

    for (final pin in _attachedPins) {
      final diff = (pin - normalizedLanding).abs();
      final shortestDiff = math.min(diff, (2 * math.pi) - diff);
      if (shortestDiff < minSafeAngleDiff) {
        collision = true;
        break;
      }
    }

    if (collision) {
      // TABRAKAN / GAME OVER
      HapticFeedback.heavyImpact();
      setState(() {
        _isShooting = false;
        _isGameOver = true;
      });
      _showGameOverDialog();
    } else {
      // BERHASIL MENEMPEL DI ORBIT
      setState(() {
        _attachedPins.add(normalizedLanding);
        _packetsLeftToShoot--;
        _score += 10 * _currentLevel;
        _isShooting = false;
      });

      // Cek apakah seluruh node untuk level ini sudah habis ditembakkan
      if (_packetsLeftToShoot <= 0) {
        HapticFeedback.mediumImpact();
        setState(() {
          _isLevelCleared = true;
        });
        _showLevelClearedDialog();
      }
    }
  }

  /// DIALOG KEMENANGAN LEVEL (Tempat Klaim Iklan Rewarded +Rp 300)
  void _showLevelClearedDialog() {
    final controller = widget.adsController;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Trophy / Bintang
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: const Icon(Icons.stars_rounded, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 14),

                Text(
                  'LEVEL $_currentLevel CLEARED!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Skor Level: +${10 * _currentLevel} Poin',
                  style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),

                // Card Reward FinTech Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5E00).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFF5E00).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on_rounded, color: Color(0xFFFF9E00), size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Reward Saldo Level:',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                            const Text(
                              '+Rp 300 Rupiah',
                              style: TextStyle(color: Color(0xFFFF9E00), fontSize: 16, fontWeight: FontWeight.w900),
                            ),
                            Text(
                              'Kuota Klaim Hari Ini: ${controller.adsWatchedToday}/${AdsController.maxDailyQuota}',
                              style: const TextStyle(color: Colors.grey, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // TOMBOL 1: KLAIM REWARD (+Rp 300) VIA NONTON VIDEO IKAN
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: controller.isLimitReached ? Colors.grey.shade800 : const Color(0xFFFF5E00),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: controller.isLimitReached ? 0 : 4,
                    ),
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      if (controller.isLimitReached) {
                        controller.showConversionFunnelDialog(context);
                      } else {
                        await controller.watchRewardedAd(context);
                      }
                      // Lanjut ke level berikutnya
                      _startLevel(_currentLevel + 1);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          controller.isLimitReached ? Icons.lock_clock_rounded : Icons.play_circle_fill_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          controller.isLimitReached
                              ? 'Kuota Habis (Buka Afiliasi 30%)'
                              : 'Klaim +Rp 300 (Tonton Video)',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // TOMBOL 2: LANJUT LEVEL TANPA KLAIM IKAN (Kepatuhan Google Play Policy)
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _startLevel(_currentLevel + 1);
                  },
                  child: const Text(
                    'Lewati & Lanjut Level Berikutnya ➔',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// DIALOG GAME OVER (Revive atau Ulangi)
  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 54),
                const SizedBox(height: 12),
                const Text(
                  'QUANTUM OVERLOAD!',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Node bertabrakan pada cincin orbit.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 20),

                // Ulangi Level
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38BDF8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _startLevel(_currentLevel);
                    },
                    child: const Text('Coba Lagi Level Ini', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgDark = Color(0xFF070B14);
    final controller = widget.adsController;

    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP HUD GAME (Level, Saldo, Status Kuota)
            _buildGameHUD(controller),

            // 2. BANNER AD DI BAWAH HUD
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withOpacity(0.85),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: const BannerAdWidget(),
            ),

            // 3. CANVAS GAME UTAMA (INTERAKTIF TAP UNTUK MENEMBAK)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _shootNode,
                child: Center(
                  child: CustomPaint(
                    size: const Size(double.infinity, double.infinity),
                    painter: _CyberOrbitPainter(
                      currentOrbitAngle: _currentOrbitAngle,
                      attachedPins: _attachedPins,
                      packetsLeft: _packetsLeftToShoot,
                      isGameOver: _isGameOver,
                      currentLevel: _currentLevel,
                    ),
                  ),
                ),
              ),
            ),

            // 4. BOTTOM CONTROLS & SHOOT INSTRUCTION
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
              child: Column(
                children: [
                  const Text(
                    '👆 KETUK DI MANA SAJA UNTUK MENEMBAKKAN NODE',
                    style: TextStyle(
                      color: Color(0xFFFF9E00),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Selesaikan level untuk klaim saldo Rp 300 (${controller.adsWatchedToday}/10 kuota hari ini)',
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Top HUD Widget
  Widget _buildGameHUD(AdsController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Badge Level
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF38BDF8), Color(0xFF0284C7)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF38BDF8).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.flash_on_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  'LEVEL $_currentLevel',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ],
            ),
          ),

          // Badge Saldo & Kuota Iklan
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on_rounded, color: Color(0xFFFF9E00), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Rp ${controller.balanceAds.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Shortcut Pairing Telegram
              IconButton(
                icon: const Icon(Icons.telegram, color: Color(0xFF38BDF8), size: 24),
                tooltip: 'Pair Telegram',
                onPressed: () => DeepLinkService.openBotPairing(controller.pairToken),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// CustomPainter untuk Rendering Grafis Game Orbit 60 FPS
class _CyberOrbitPainter extends CustomPainter {
  final double currentOrbitAngle;
  final List<double> attachedPins;
  final int packetsLeft;
  final bool isGameOver;
  final int currentLevel;

  _CyberOrbitPainter({
    required this.currentOrbitAngle,
    required this.attachedPins,
    required this.packetsLeft,
    required this.isGameOver,
    required this.currentLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 30);
    const orbitRadius = 90.0;
    const centerCoreRadius = 45.0;

    // 1. Gambar Cincin Orbit Berputar
    final orbitPaint = Paint()
      ..color = const Color(0xFF38BDF8).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, orbitRadius, orbitPaint);

    // 2. Gambar Node yang Sudah Menempel di Orbit
    for (final pinAngle in attachedPins) {
      final totalAngle = pinAngle + currentOrbitAngle;
      final pinEnd = Offset(
        center.dx + (orbitRadius + 45) * math.cos(totalAngle),
        center.dy + (orbitRadius + 45) * math.sin(totalAngle),
      );
      final pinStart = Offset(
        center.dx + centerCoreRadius * math.cos(totalAngle),
        center.dy + centerCoreRadius * math.sin(totalAngle),
      );

      // Garis penghubung node ke orbit
      final linePaint = Paint()
        ..color = isGameOver ? const Color(0xFFEF4444) : const Color(0xFF38BDF8)
        ..strokeWidth = 2.0;
      canvas.drawLine(pinStart, pinEnd, linePaint);

      // Kepala node
      final headPaint = Paint()
        ..color = isGameOver ? const Color(0xFFEF4444) : const Color(0xFFFF9E00)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pinEnd, 8.0, headPaint);
    }

    // 3. Gambar Core Tengah (Data Core)
    final coreGlowPaint = Paint()
      ..color = const Color(0xFFFF5E00).withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(center, centerCoreRadius + 5, coreGlowPaint);

    final corePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, centerCoreRadius, corePaint);

    final coreBorderPaint = Paint()
      ..color = const Color(0xFFFF5E00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(center, centerCoreRadius, coreBorderPaint);

    // Teks Jumlah Node Tersisa di Dalam Core
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$packetsLeft',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - (textPainter.width / 2), center.dy - (textPainter.height / 2)),
    );

    // 4. Gambar Launcher Node di Bawah (Siap Ditembak)
    final launcherCenter = Offset(center.dx, center.dy + orbitRadius + 95);
    final launcherPaint = Paint()
      ..color = const Color(0xFFFF9E00)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(launcherCenter, 10.0, launcherPaint);

    // Arah panah launcher
    final arrowPaint = Paint()
      ..color = const Color(0xFFFF9E00).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(launcherCenter, Offset(center.dx, launcherCenter.dy - 20), arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _CyberOrbitPainter oldDelegate) {
    return true; // Repaint setiap frame saat cincin berputar
  }
}
