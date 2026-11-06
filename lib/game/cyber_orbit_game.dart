import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../controllers/ads_controller.dart';
import '../services/currency_service.dart';
import '../services/deep_link_service.dart';
import '../services/locale_service.dart';
import '../services/security_service.dart';

/// CyberOrbitGameScreen: Native Flutter 60 FPS Canvas Engine ("Cyber Orbit: Quantum Core").
/// Menggantikan WebView sepenuhnya agar 100% bebas crash OpenGL/Renderer di Emulator & HP
/// saat memutar video iklan AdMob full-screen.
class CyberOrbitGameScreen extends StatefulWidget {
  final AdsController adsController;

  const CyberOrbitGameScreen({Key? key, required this.adsController}) : super(key: key);

  @override
  State<CyberOrbitGameScreen> createState() => _CyberOrbitGameScreenState();
}

enum _GameState { start, playing, levelClear, gameOver }

class _OrbitNode {
  double angle;
  final bool isObstacle;
  final String? label;

  _OrbitNode({required this.angle, required this.isObstacle, this.label});
}

class _Projectile {
  double y;
  final double speed;
  final String label;

  _Projectile({required this.y, required this.speed, required this.label});
}

class _CyberOrbitGameScreenState extends State<CyberOrbitGameScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;

  _GameState _state = _GameState.start;
  int _level = 1;
  int _stage = 1;
  int _maxStages = 5;
  int _score = 0;

  double _orbitAngle = 0.0;
  int _direction = 1;
  double _currentAngularVel = 1.4;

  final List<_OrbitNode> _attachedNodes = [];
  final List<_Projectile> _projectiles = [];
  int _remainingToShoot = 5;

  bool _isMuted = false;
  bool _isWatchingAd = false;

  // Ukuran arena dinamis
  double _canvasWidth = 360;
  double _canvasHeight = 520;
  double get _cx => _canvasWidth * 0.5;
  double get _cy => _canvasHeight * 0.38;
  static const double _coreRadius = 42.0;
  static const double _orbitRadius = 115.0;
  static const double _nodeRadius = 12.0;
  double get _launcherY => math.min(_canvasHeight - 75.0, _cy + _orbitRadius + 140.0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.adsController.initialize();
    widget.adsController.addListener(_onControllerUpdate);

    _setupDemoOrbit();
    _ticker = createTicker(_onTick)..start();

    // Cek keamanan saat game pertama kali dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDeviceAndIpSecurity();
    });
  }

  Future<bool> _checkDeviceAndIpSecurity() async {
    if (!mounted) return false;
    return await SecurityService.verifyAndEnforceSecurity(
      context: context,
      backendBaseUrl: widget.adsController.backendBaseUrl,
      pairToken: widget.adsController.pairToken,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    widget.adsController.removeListener(_onControllerUpdate);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Saat iklan video AdMob sedang tampil di layar penuh, pause ticker
    // agar GPU/CPU emulator tidak mengalami lonjakan beban atau crash.
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _lastTick = Duration.zero;
    } else if (state == AppLifecycleState.resumed) {
      _lastTick = Duration.zero;
      if (mounted) {
        setState(() {});
        _checkDeviceAndIpSecurity();
      }
    }
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _setupDemoOrbit() {
    _attachedNodes.clear();
    for (int i = 0; i < 5; i++) {
      _attachedNodes.add(_OrbitNode(
        angle: (i / 5.0) * math.pi * 2.0,
        isObstacle: false,
      ));
    }
  }

  int _getMaxGamesForLevel(int level) {
    // Level 1: 5 game, Level 2: 10 game, Level 3: 15 game, dst (level * 5)
    return math.max(5, level * 5);
  }

  Future<void> _startNewGame() async {
    if (!_isMuted) HapticFeedback.lightImpact();
    final isSafe = await _checkDeviceAndIpSecurity();
    if (!isSafe || !mounted) return;
    setState(() {
      _level = 1;
      _stage = 1;
      _score = 0;
      _loadStage(1, 1);
      _state = _GameState.playing;
    });
  }

  void _loadStage(int lvl, int stg) {
    _level = lvl;
    _stage = stg;
    _maxStages = _getMaxGamesForLevel(lvl);

    // Kesulitan meningkat tajam di tiap level:
    final int obstacles = math.min(6, 1 + ((lvl - 1) * 0.7).floor() + (stg ~/ 4));
    final int nodesToShoot = math.min(14, 4 + lvl + (stg ~/ 3));
    final double baseSpeed = math.min(3.6, 1.4 + (lvl - 1) * 0.18 + (stg - 1) * 0.03);
    final int direction = (lvl > 1 && stg % 2 == 0) ? -1 : 1;

    _orbitAngle = 0.0;
    _direction = direction;
    _currentAngularVel = baseSpeed * _direction;
    _projectiles.clear();
    _attachedNodes.clear();
    _remainingToShoot = nodesToShoot;

    for (int i = 0; i < obstacles; i++) {
      _attachedNodes.add(_OrbitNode(
        angle: (i / obstacles) * math.pi * 2.0,
        isObstacle: true,
      ));
    }
  }

  void _retryGame() {
    if (!_isMuted) HapticFeedback.lightImpact();
    setState(() {
      _loadStage(_level, _stage);
      _state = _GameState.playing;
    });
  }

  void _advanceNext() {
    setState(() {
      if (_stage < _maxStages) {
        _stage++;
        _loadStage(_level, _stage);
        _state = _GameState.playing;
      } else {
        _level++;
        _stage = 1;
        _loadStage(_level, _stage);
        _state = _GameState.playing;
      }
    });
  }

  void _fireNode() {
    if (_state != _GameState.playing || _remainingToShoot <= 0) return;
    if (!_isMuted) HapticFeedback.selectionClick();
    setState(() {
      final numLabel = _remainingToShoot.toString();
      _remainingToShoot--;
      _projectiles.add(_Projectile(
        y: _launcherY - 15.0,
        speed: 1400.0,
        label: numLabel,
      ));
    });
  }

  void _onTick(Duration elapsed) {
    if (!mounted || _isWatchingAd) {
      _lastTick = elapsed;
      return;
    }
    if (_lastTick == Duration.zero) {
      _lastTick = elapsed;
      return;
    }

    double dt = (elapsed - _lastTick).inMicroseconds / 1000000.0;
    _lastTick = elapsed;
    if (dt <= 0 || dt > 0.05) dt = 0.016;

    final deltaAngle = _currentAngularVel * dt;
    _orbitAngle = (_orbitAngle + deltaAngle) % (math.pi * 2.0);
    for (final node in _attachedNodes) {
      node.angle = (node.angle + deltaAngle) % (math.pi * 2.0);
    }

    if (_state != _GameState.playing) {
      setState(() {});
      return;
    }

    final impactY = _cy + _orbitRadius;
    const entryAngle = math.pi * 0.5;
    const minSafeAngle = (_nodeRadius * 2.0) / _orbitRadius;

    for (int i = _projectiles.length - 1; i >= 0; i--) {
      final p = _projectiles[i];
      p.y -= p.speed * dt;

      if (p.y <= impactY) {
        bool collided = false;
        for (final existing in _attachedNodes) {
          double diff = ((entryAngle - existing.angle) % (math.pi * 2.0)).abs();
          if (diff > math.pi) diff = math.pi * 2.0 - diff;
          if (diff < minSafeAngle) {
            collided = true;
            break;
          }
        }

        _projectiles.removeAt(i);

        if (collided) {
          if (!_isMuted) HapticFeedback.heavyImpact();
          _state = _GameState.gameOver;
          setState(() {});
          return;
        } else {
          if (!_isMuted) HapticFeedback.lightImpact();
          _attachedNodes.add(_OrbitNode(
            angle: entryAngle,
            isObstacle: false,
            label: p.label,
          ));
          _score += 100;

          if (_remainingToShoot == 0 && _projectiles.isEmpty) {
            if (!_isMuted) HapticFeedback.mediumImpact();
            _state = _GameState.levelClear;
            if (_stage >= _maxStages) {
              _notifyLevelCleared(_level);
            }
          }
        }
      }
    }

    setState(() {});
  }

  Future<void> _onClaimRewardAndContinue() async {
    if (_isWatchingAd) return;

    if (widget.adsController.isLimitReached) {
      widget.adsController.showConversionFunnelDialog(context);
      return;
    }

    setState(() {
      _isWatchingAd = true;
    });

    final success = await widget.adsController.watchRewardedAd(context);

    if (!mounted) return;
    setState(() {
      _isWatchingAd = false;
    });

    if (success) {
      // Langsung masuk ke game berikutnya tanpa tertahan di halaman continue!
      _advanceNext();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFE11D48),
          behavior: SnackBarBehavior.floating,
          content: Text('⚠️ Wajib menonton video iklan sampai selesai untuk melanjutkan!'),
        ),
      );
    }
  }

  /// Melaporkan penyelesaian level ke backend Cloudflare D1
  /// Menghitung milestone kelipatan 10 (Rp50 tiap 10 level s/d Level 2000) untuk sponsor
  Future<void> _notifyLevelCleared(int level) async {
    try {
      final response = await http
          .post(
            Uri.parse('${widget.adsController.backendBaseUrl}/api/game/level-cleared'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'pairToken': widget.adsController.pairToken,
              'level': level,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['milestoneAwarded'] == true && mounted) {
          final bonus = resData['milestoneBonus'] ?? 50;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF00E676),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              content: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🎯 Milestone Level $level Tercapai!',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          'Sponsor pengundang Anda mendapatkan bonus referral Rp $bonus!',
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error reporting level cleared: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgDark = Color(0xFF050811);
    final controller = widget.adsController;

    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP HUD BAR (Saldo IDR & Kuota Iklan)
            _buildTopHUD(controller),

            // 2. NATIVE 60FPS GAME ARENA
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _canvasWidth = constraints.maxWidth;
                  _canvasHeight = constraints.maxHeight;

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (_) {
                      if (_state == _GameState.playing) {
                        _fireNode();
                      }
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background Radial Gradient + CustomPainter Orbit
                        Container(
                          decoration: const BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment(0.0, -0.15),
                              radius: 0.85,
                              colors: [
                                Color(0xFF0C1733),
                                Color(0xFF060A16),
                                Color(0xFF03050B),
                              ],
                            ),
                          ),
                          child: CustomPaint(
                            painter: _CyberOrbitPainter(
                              cx: _cx,
                              cy: _cy,
                              coreRadius: _coreRadius,
                              orbitRadius: _orbitRadius,
                              nodeRadius: _nodeRadius,
                              launcherY: _launcherY,
                              attachedNodes: _attachedNodes,
                              projectiles: _projectiles,
                              centerText: _state == _GameState.start
                                  ? 'Q'
                                  : _remainingToShoot.toString(),
                              showLauncher: _state == _GameState.playing,
                            ),
                          ),
                        ),

                        // Game HUD Overlay (Level & Score)
                        Positioned(
                          top: 14,
                          left: 18,
                          right: 18,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  _buildHudPill(
                                    label: 'LEVEL',
                                    value: 'LVL ${_level.toString().padLeft(2, '0')}',
                                    valueColor: const Color(0xFFFF9900),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildHudPill(
                                    label: 'SCORE',
                                    value: _score.toString(),
                                    valueColor: const Color(0xFF00F0FF),
                                  ),
                                ],
                              ),
                              InkWell(
                                onTap: () => setState(() => _isMuted = !_isMuted),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF070D1C).withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF00F0FF).withOpacity(0.35),
                                    ),
                                  ),
                                  child: Icon(
                                    _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                    color: const Color(0xFF00F0FF),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Modal: START SCREEN
                        if (_state == _GameState.start) _buildStartModal(),

                        // Modal: GAME / LEVEL CLEARED
                        if (_state == _GameState.levelClear) _buildClearModal(),

                        // Modal: GAME OVER
                        if (_state == _GameState.gameOver) _buildGameOverModal(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHudPill({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF070D1C).withOpacity(0.82),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF7DA2BE),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartModal() {
    return Container(
      color: const Color(0xFF040710).withOpacity(0.82),
      padding: const EdgeInsets.all(22),
      alignment: Alignment.center,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
        decoration: BoxDecoration(
          color: const Color(0xFF090F20).withOpacity(0.95),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.45)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00F0FF).withOpacity(0.18),
              blurRadius: 28,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'APPDOCK HUB GAMING PROTOCOL',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFFF9900),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'CYBER ORBIT',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 27,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'QUANTUM CORE',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF00F0FF),
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 4.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              LocaleService.gameStartDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFB4D2E7),
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startNewGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00F0FF),
                  foregroundColor: const Color(0xFF04101D),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                ),
                child: Text(
                  LocaleService.gameStartBtn,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearModal() {
    final isLevelDone = _stage >= _maxStages;
    final titleText = isLevelDone ? LocaleService.gameLevelCleared : LocaleService.gameStageCleared;

    return Container(
      color: const Color(0xFF040710).withOpacity(0.84),
      padding: const EdgeInsets.all(22),
      alignment: Alignment.center,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
        decoration: BoxDecoration(
          color: const Color(0xFF090F20).withOpacity(0.95),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.55)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00F0FF).withOpacity(0.22),
              blurRadius: 30,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              titleText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.star_rounded, color: Color(0xFFFF9900), size: 42),
                SizedBox(width: 10),
                Icon(Icons.star_rounded, color: Color(0xFFFF9900), size: 42),
                SizedBox(width: 10),
                Icon(Icons.star_rounded, color: Color(0xFFFF9900), size: 42),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9900).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFF9900).withOpacity(0.35)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.lock_rounded, color: Color(0xFFFFB74D), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Wajib tonton video iklan sampai selesai untuk melanjutkan!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFFFB74D),
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isWatchingAd ? null : _onClaimRewardAndContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6D00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                ),
                child: _isWatchingAd
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        LocaleService.gameClaimBtn,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverModal() {
    return Container(
      color: const Color(0xFF040710).withOpacity(0.84),
      padding: const EdgeInsets.all(22),
      alignment: Alignment.center,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
        decoration: BoxDecoration(
          color: const Color(0xFF090F20).withOpacity(0.95),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFF1E56).withOpacity(0.55)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF1E56).withOpacity(0.22),
              blurRadius: 30,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'NODE COLLISION DETECTED',
              style: TextStyle(
                color: Color(0xFFFF4775),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'CORE BREACHED',
              style: TextStyle(
                color: Color(0xFFFF4775),
                fontSize: 25,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF040914).withOpacity(0.75),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'FINAL SCORE',
                          style: TextStyle(color: Color(0xFF7DA2BE), fontSize: 10),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _score.toString(),
                          style: const TextStyle(
                            color: Color(0xFF00F0FF),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF040914).withOpacity(0.75),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'LEVEL TERAKHIR',
                          style: TextStyle(color: Color(0xFF7DA2BE), fontSize: 10),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'LVL ${_level.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: Color(0xFFFF9900),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _retryGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF1E56),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  LocaleService.gameRetryBtn,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHUD(AdsController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF070D1C),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Saldo Poin Iklan (Format Mata Uang IDR)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1A30),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFF9900).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on_rounded, color: Color(0xFFFF9900), size: 16),
                const SizedBox(width: 6),
                Text(
                  CurrencyService.format(controller.balanceAds),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          // Shortcut Pairing Telegram
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => DeepLinkService.openBotPairing(controller.pairToken),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF0284C7).withOpacity(0.4)),
              ),
              child: const Icon(Icons.telegram, color: Color(0xFF38BDF8), size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _CyberOrbitPainter extends CustomPainter {
  final double cx;
  final double cy;
  final double coreRadius;
  final double orbitRadius;
  final double nodeRadius;
  final double launcherY;
  final List<_OrbitNode> attachedNodes;
  final List<_Projectile> projectiles;
  final String centerText;
  final bool showLauncher;

  _CyberOrbitPainter({
    required this.cx,
    required this.cy,
    required this.coreRadius,
    required this.orbitRadius,
    required this.nodeRadius,
    required this.launcherY,
    required this.attachedNodes,
    required this.projectiles,
    required this.centerText,
    required this.showLauncher,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(cx, cy);

    // 1. Orbit Track Circle
    final trackPaint = Paint()
      ..color = const Color(0xFF00F0FF).withOpacity(0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, orbitRadius, trackPaint);

    // 2. Attached Nodes & Spokes
    for (final node in attachedNodes) {
      final nx = cx + math.cos(node.angle) * orbitRadius;
      final ny = cy + math.sin(node.angle) * orbitRadius;
      final nodePos = Offset(nx, ny);
      final color = node.isObstacle ? const Color(0xFFFF9900) : const Color(0xFF00F0FF);

      final linePaint = Paint()
        ..color = color
        ..strokeWidth = 2.0;
      canvas.drawLine(center, nodePos, linePaint);

      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(nodePos, nodeRadius, dotPaint);

      if (node.label != null && node.label!.isNotEmpty) {
        final tp = TextPainter(
          text: TextSpan(
            text: node.label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(nx - tp.width / 2, ny - tp.height / 2));
      }
    }

    // 3. Center Core
    final coreFillPaint = Paint()
      ..color = const Color(0xFF070F24)
      ..style = PaintingStyle.fill;
    final coreStrokePaint = Paint()
      ..color = const Color(0xFF00F0FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(center, coreRadius, coreFillPaint);
    canvas.drawCircle(center, coreRadius, coreStrokePaint);

    final coreTextPainter = TextPainter(
      text: TextSpan(
        text: centerText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    coreTextPainter.paint(
      canvas,
      Offset(cx - coreTextPainter.width / 2, cy - coreTextPainter.height / 2),
    );

    // 4. Projectiles in flight
    final projPaint = Paint()
      ..color = const Color(0xFF00F0FF)
      ..style = PaintingStyle.fill;
    for (final p in projectiles) {
      canvas.drawCircle(Offset(cx, p.y), nodeRadius, projPaint);
    }

    // 5. Bottom Launcher Node (Besar & Mudah Diklik User)
    if (showLauncher) {
      final launcherCenter = Offset(cx, launcherY);
      final glowPaint = Paint()
        ..color = const Color(0xFFFF9900).withOpacity(0.22)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(launcherCenter, 28.0, glowPaint);

      final ringPaint = Paint()
        ..color = const Color(0xFFFF9900).withOpacity(0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(launcherCenter, 20.0, ringPaint);

      final launcherPaint = Paint()
        ..color = const Color(0xFFFF9900)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(launcherCenter, 14.0, launcherPaint);

      final tapTextPainter = TextPainter(
        text: const TextSpan(
          text: 'TAP UNTUK TEMBAK',
          style: TextStyle(
            color: Color(0xFF7DA2BE),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tapTextPainter.paint(
        canvas,
        Offset(cx - tapTextPainter.width / 2, launcherY + 34),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CyberOrbitPainter oldDelegate) => true;
}
