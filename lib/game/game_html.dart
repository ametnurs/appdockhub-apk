/// game_html.dart: Mengemas seluruh kode game HTML5 Canvas + Web Audio API
/// dari Arena.ai ("Cyber Orbit: Quantum Core") dengan jembatan FlutterBridge.
const String cyberOrbitGameHtml = '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover" />
  <title>Cyber Orbit: Quantum Core</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Orbitron:wght@500;700;900&family=Rajdhani:wght@500;600;700&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg-deep: #050811;
      --bg-panel: rgba(9, 15, 32, 0.9);
      --cyan: #00f0ff;
      --cyan-dim: rgba(0, 240, 255, 0.22);
      --amber: #ff9900;
      --amber-dim: rgba(255, 153, 0, 0.25);
      --red: #ff1e56;
      --red-dim: rgba(255, 30, 86, 0.28);
      --text-main: #e8f7ff;
      --text-muted: #7da2be;
    }

    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
      user-select: none;
      -webkit-user-select: none;
      -webkit-tap-highlight-color: transparent;
    }

    html, body {
      width: 100%;
      height: 100%;
      overflow: hidden;
      background-color: var(--bg-deep);
      color: var(--text-main);
      font-family: 'Rajdhani', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      touch-action: manipulation;
    }

    #game-wrapper {
      position: relative;
      width: 100vw;
      height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      overflow: hidden;
      background: radial-gradient(circle at 50% 42%, #0c1733 0%, #060a16 62%, #03050b 100%);
    }

    canvas#gameCanvas {
      display: block;
      width: 100%;
      height: 100%;
      cursor: pointer;
    }

    /* HUD Overlay */
    #hud {
      position: absolute;
      top: 0;
      left: 50%;
      transform: translateX(-50%);
      width: 100%;
      max-width: 520px;
      padding: max(14px, env(safe-area-inset-top)) 18px 10px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      pointer-events: none;
      z-index: 10;
    }

    .hud-group {
      display: flex;
      align-items: center;
      gap: 10px;
    }

    .hud-pill {
      background: rgba(7, 13, 28, 0.78);
      border: 1px solid rgba(0, 240, 255, 0.28);
      box-shadow: 0 0 14px rgba(0, 240, 255, 0.12), inset 0 0 10px rgba(0, 240, 255, 0.06);
      backdrop-filter: blur(8px);
      border-radius: 10px;
      padding: 6px 12px;
      display: flex;
      flex-direction: column;
      min-width: 78px;
    }

    .hud-label {
      font-size: 10px;
      font-weight: 700;
      letter-spacing: 1.6px;
      text-transform: uppercase;
      color: var(--text-muted);
      line-height: 1;
    }

    .hud-value {
      font-family: 'Orbitron', monospace;
      font-size: 17px;
      font-weight: 700;
      color: var(--cyan);
      text-shadow: 0 0 10px rgba(0, 240, 255, 0.55);
      line-height: 1.25;
      margin-top: 2px;
    }

    .hud-value.amber {
      color: var(--amber);
      text-shadow: 0 0 10px rgba(255, 153, 0, 0.5);
    }

    .hud-btn {
      pointer-events: auto;
      width: 40px;
      height: 40px;
      border-radius: 10px;
      background: rgba(7, 13, 28, 0.82);
      border: 1px solid rgba(0, 240, 255, 0.34);
      color: var(--cyan);
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      box-shadow: 0 0 12px rgba(0, 240, 255, 0.14);
    }

    .hud-btn svg {
      width: 19px;
      height: 19px;
      fill: currentColor;
    }

    /* Modal Screens */
    .overlay-screen {
      position: absolute;
      inset: 0;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 20px;
      z-index: 20;
      background: radial-gradient(circle at 50% 45%, rgba(6, 11, 24, 0.62) 0%, rgba(4, 7, 16, 0.88) 100%);
      backdrop-filter: blur(6px);
      opacity: 1;
      transition: opacity 0.22s ease;
    }

    .overlay-screen.hidden {
      opacity: 0;
      pointer-events: none;
    }

    .panel {
      width: 100%;
      max-width: 400px;
      background: var(--bg-panel);
      border: 1px solid rgba(0, 240, 255, 0.38);
      border-radius: 18px;
      padding: 26px 24px;
      box-shadow:
        0 18px 50px rgba(0, 0, 0, 0.72),
        0 0 32px rgba(0, 240, 255, 0.18),
        inset 0 0 24px rgba(0, 240, 255, 0.06);
      text-align: center;
      position: relative;
      overflow: hidden;
      animation: panelPop 0.26s cubic-bezier(0.2, 0.9, 0.3, 1.15);
    }

    .panel::before {
      content: '';
      position: absolute;
      top: 0;
      left: 12%;
      right: 12%;
      height: 2px;
      background: linear-gradient(90deg, transparent, var(--cyan), transparent);
      box-shadow: 0 0 12px var(--cyan);
    }

    .panel.danger {
      border-color: rgba(255, 30, 86, 0.55);
      box-shadow:
        0 18px 50px rgba(0, 0, 0, 0.78),
        0 0 36px rgba(255, 30, 86, 0.24);
    }

    .panel.victory {
      border-color: rgba(0, 240, 255, 0.6);
      box-shadow:
        0 18px 50px rgba(0, 0, 0, 0.75),
        0 0 40px rgba(0, 240, 255, 0.28);
    }

    @keyframes panelPop {
      0% { transform: scale(0.92) translateY(10px); opacity: 0; }
      100% { transform: scale(1) translateY(0); opacity: 1; }
    }

    .eyebrow {
      font-size: 11px;
      font-weight: 700;
      letter-spacing: 3px;
      text-transform: uppercase;
      color: var(--amber);
      text-shadow: 0 0 10px rgba(255, 153, 0, 0.45);
      margin-bottom: 6px;
    }

    .title-main {
      font-family: 'Orbitron', sans-serif;
      font-size: 28px;
      font-weight: 900;
      letter-spacing: 2px;
      line-height: 1.08;
      color: #ffffff;
      text-shadow: 0 0 18px rgba(0, 240, 255, 0.75);
    }

    .title-sub {
      font-family: 'Orbitron', sans-serif;
      font-size: 13px;
      font-weight: 700;
      letter-spacing: 5px;
      color: var(--cyan);
      margin-top: 4px;
      margin-bottom: 16px;
    }

    .title-danger {
      color: #ff4775;
      text-shadow: 0 0 20px rgba(255, 30, 86, 0.8);
    }

    .desc-text {
      font-size: 14px;
      line-height: 1.45;
      color: #b4d2e7;
      margin-bottom: 18px;
    }

    .key-badge {
      display: inline-block;
      padding: 1px 7px;
      border-radius: 5px;
      font-family: 'Orbitron', monospace;
      font-size: 11px;
      font-weight: 700;
      color: var(--cyan);
      background: rgba(0, 240, 255, 0.12);
      border: 1px solid rgba(0, 240, 255, 0.4);
    }

    .btn-primary {
      width: 100%;
      padding: 14px 20px;
      border: none;
      border-radius: 12px;
      font-family: 'Orbitron', sans-serif;
      font-size: 14px;
      font-weight: 800;
      letter-spacing: 1.5px;
      text-transform: uppercase;
      color: #04101d;
      background: linear-gradient(135deg, #00f0ff 0%, #39fffa 50%, #00c4ff 100%);
      box-shadow: 0 0 22px rgba(0, 240, 255, 0.55), 0 4px 14px rgba(0, 0, 0, 0.45);
      cursor: pointer;
    }

    .btn-primary.reward-btn {
      color: #ffffff;
      background: linear-gradient(135deg, #ff5e00 0%, #ff9e00 100%);
      box-shadow: 0 0 24px rgba(255, 94, 0, 0.6);
      margin-bottom: 10px;
    }

    .btn-primary.danger-btn {
      color: #fff;
      background: linear-gradient(135deg, #ff1e56 0%, #ff4b78 100%);
      box-shadow: 0 0 22px rgba(255, 30, 86, 0.55);
    }

    .btn-secondary {
      width: 100%;
      padding: 11px 16px;
      border-radius: 11px;
      font-family: 'Orbitron', sans-serif;
      font-size: 12px;
      font-weight: 700;
      letter-spacing: 1.8px;
      text-transform: uppercase;
      color: var(--cyan);
      background: rgba(0, 240, 255, 0.08);
      border: 1px solid rgba(0, 240, 255, 0.32);
      cursor: pointer;
    }

    /* Stars Display */
    .stars-row {
      display: flex;
      justify-content: center;
      gap: 14px;
      margin: 14px 0 16px;
    }

    .star-icon {
      width: 38px;
      height: 38px;
      color: rgba(255, 255, 255, 0.14);
      transform: scale(0.75);
      transition: transform 0.3s ease, color 0.3s ease;
    }

    .star-icon.earned {
      color: var(--amber);
      filter: drop-shadow(0 0 12px rgba(255, 153, 0, 0.85));
      transform: scale(1.08);
    }

    .stats-grid {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 10px;
      margin-bottom: 18px;
    }

    .stat-box {
      background: rgba(4, 9, 20, 0.72);
      border: 1px solid rgba(0, 240, 255, 0.2);
      border-radius: 10px;
      padding: 10px 8px;
    }

    .stat-box .label {
      font-size: 11px;
      letter-spacing: 1.4px;
      text-transform: uppercase;
      color: var(--text-muted);
    }

    .stat-box .val {
      font-family: 'Orbitron', monospace;
      font-size: 18px;
      font-weight: 700;
      color: #fff;
      margin-top: 2px;
    }

    .stat-box .val.cyan { color: var(--cyan); }
    .stat-box .val.amber { color: var(--amber); }

    .hint-footer {
      margin-top: 10px;
      font-size: 11px;
      letter-spacing: 1px;
      color: var(--text-muted);
    }
  </style>
</head>
<body>
  <div id="game-wrapper">
    <canvas id="gameCanvas"></canvas>

    <!-- Top HUD -->
    <div id="hud">
      <div class="hud-group">
        <div class="hud-pill">
          <span class="hud-label">Sector</span>
          <span class="hud-value amber" id="hud-level">LVL 01</span>
        </div>
        <div class="hud-pill">
          <span class="hud-label">Score</span>
          <span class="hud-value" id="hud-score">0</span>
        </div>
      </div>

      <div class="hud-group">
        <button class="hud-btn" id="btn-sound" tabindex="-1" title="Toggle Audio">
          <svg id="icon-sound-on" viewBox="0 0 24 24">
            <path d="M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02zM14 3.23v2.06c2.89.86 5 3.54 5 6.71s-2.11 5.85-5 6.71v2.06c4.01-.91 7-4.49 7-8.77s-2.99-7.86-7-8.77z"/>
          </svg>
          <svg id="icon-sound-off" viewBox="0 0 24 24" style="display:none;">
            <path d="M16.5 12c0-1.77-1.02-3.29-2.5-4.03v2.21l2.45 2.45c.03-.2.05-.41.05-.63zm2.5 0c0 .94-.2 1.82-.54 2.64l1.51 1.51C20.63 14.91 21 13.5 21 12c0-4.28-2.99-7.86-7-8.77v2.06c2.89.86 5 3.54 5 6.71zM4.27 3L3 4.27 7.73 9H3v6h4l5 5v-6.73l4.25 4.25c-.67.52-1.42.93-2.25 1.18v2.06c1.38-.31 2.63-.95 3.69-1.81L19.73 21 21 19.73l-9-9L4.27 3zM12 4L9.91 6.09 12 8.18V4z"/>
          </svg>
        </button>
      </div>
    </div>

    <!-- START SCREEN -->
    <div class="overlay-screen" id="screen-start">
      <div class="panel">
        <div class="eyebrow">AppDock Hub Gaming Protocol</div>
        <h1 class="title-main">CYBER ORBIT</h1>
        <div class="title-sub">QUANTUM CORE</div>
        <p class="desc-text">
          Ketuk layar untuk mengunci energy node ke orbit. Selesaikan level untuk klaim saldo bonus Rp 300!
        </p>
        <button class="btn-primary" id="btn-start">MULAI GAME</button>
      </div>
    </div>

    <!-- LEVEL CLEARED SCREEN -->
    <div class="overlay-screen hidden" id="screen-clear">
      <div class="panel victory">
        <div class="eyebrow" id="clear-sector-label">Sector 01 Synchronized</div>
        <h2 class="title-main" style="font-size:25px;">LEVEL SELESAI!</h2>

        <div class="stars-row" id="clear-stars">
          <svg class="star-icon" viewBox="0 0 24 24"><path fill="currentColor" d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg>
          <svg class="star-icon" viewBox="0 0 24 24"><path fill="currentColor" d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg>
          <svg class="star-icon" viewBox="0 0 24 24"><path fill="currentColor" d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg>
        </div>

        <div class="stats-grid">
          <div class="stat-box">
            <div class="label">Reward Saldo</div>
            <div class="val amber" id="clear-bonus">+Rp 10</div>
          </div>
          <div class="stat-box">
            <div class="label">Total Score</div>
            <div class="val cyan" id="clear-score">1,250</div>
          </div>
        </div>

        <!-- Tombol Klaim Reward Ad (Terhubung ke Flutter) -->
        <button class="btn-primary reward-btn" id="btn-claim-reward">
          🎁 KLAIM +RP 10 (NONTON VIDEO)
        </button>
        <button class="btn-secondary" id="btn-next-level">LEWATI KE LEVEL BERIKUTNYA</button>
      </div>
    </div>

    <!-- GAME OVER SCREEN -->
    <div class="overlay-screen hidden" id="screen-gameover">
      <div class="panel danger">
        <div class="eyebrow" style="color:#ff4775;">Node Collision Detected</div>
        <h2 class="title-main title-danger" style="font-size:25px; margin-bottom:10px;">CORE BREACHED</h2>

        <div class="stats-grid">
          <div class="stat-box">
            <div class="label">Final Score</div>
            <div class="val cyan" id="gameover-score">0</div>
          </div>
          <div class="stat-box">
            <div class="label">Level Terakhir</div>
            <div class="val amber" id="gameover-level">LVL 01</div>
          </div>
        </div>

        <button class="btn-primary danger-btn" id="btn-retry">COBA LAGI</button>
      </div>
    </div>
  </div>

  <script>
    (() => {
      'use strict';

      // 1. PROCEDURAL WEB AUDIO
      class SoundEngine {
        constructor() {
          this.ctx = null;
          this.muted = false;
        }

        init() {
          if (!this.ctx) {
            const AudioCtx = window.AudioContext || window.webkitAudioContext;
            if (AudioCtx) this.ctx = new AudioCtx();
          }
          if (this.ctx && this.ctx.state === 'suspended') {
            this.ctx.resume().catch(() => {});
          }
        }

        toggleMute() {
          this.muted = !this.muted;
          return this.muted;
        }

        playShoot() {
          if (this.muted) return;
          this.init();
          if (!this.ctx) return;
          const now = this.ctx.currentTime;
          const osc = this.ctx.createOscillator();
          const gain = this.ctx.createGain();
          osc.type = 'triangle';
          osc.frequency.setValueAtTime(980, now);
          osc.frequency.exponentialRampToValueAtTime(210, now + 0.11);
          gain.gain.setValueAtTime(0.18, now);
          gain.gain.exponentialRampToValueAtTime(0.001, now + 0.12);
          osc.connect(gain);
          gain.connect(this.ctx.destination);
          osc.start(now);
          osc.stop(now + 0.12);
        }

        playLock() {
          if (this.muted) return;
          this.init();
          if (!this.ctx) return;
          const now = this.ctx.currentTime;
          const osc = this.ctx.createOscillator();
          const gain = this.ctx.createGain();
          osc.type = 'sine';
          osc.frequency.setValueAtTime(659.25, now);
          osc.frequency.exponentialRampToValueAtTime(880, now + 0.15);
          gain.gain.setValueAtTime(0.2, now);
          gain.gain.exponentialRampToValueAtTime(0.001, now + 0.2);
          osc.connect(gain);
          gain.connect(this.ctx.destination);
          osc.start(now);
          osc.stop(now + 0.2);
        }

        playLevelClear() {
          if (this.muted) return;
          this.init();
          if (!this.ctx) return;
          const now = this.ctx.currentTime;
          const notes = [523.25, 659.25, 783.99, 1046.5];
          notes.forEach((freq, idx) => {
            const t = now + idx * 0.08;
            const osc = this.ctx.createOscillator();
            const gain = this.ctx.createGain();
            osc.type = 'sine';
            osc.frequency.setValueAtTime(freq, t);
            gain.gain.setValueAtTime(0.18, t);
            gain.gain.exponentialRampToValueAtTime(0.001, t + 0.35);
            osc.connect(gain);
            gain.connect(this.ctx.destination);
            osc.start(t);
            osc.stop(t + 0.36);
          });
        }

        playCrash() {
          if (this.muted) return;
          this.init();
          if (!this.ctx) return;
          const now = this.ctx.currentTime;
          const osc = this.ctx.createOscillator();
          const gain = this.ctx.createGain();
          osc.type = 'sawtooth';
          osc.frequency.setValueAtTime(160, now);
          osc.frequency.exponentialRampToValueAtTime(40, now + 0.4);
          gain.gain.setValueAtTime(0.3, now);
          gain.gain.exponentialRampToValueAtTime(0.001, now + 0.42);
          osc.connect(gain);
          gain.connect(this.ctx.destination);
          osc.start(now);
          osc.stop(now + 0.42);
        }
      }

      function getLevelConfig(level) {
        const obstacles = Math.min(5, Math.floor(level / 2));
        const nodesToShoot = Math.min(12, 4 + level);
        const baseSpeed = Math.min(2.6, 1.35 + level * 0.12);
        return {
          nodesToShoot,
          obstacles,
          baseSpeed,
          direction: level % 2 === 0 ? -1 : 1
        };
      }

      class CyberOrbitGame {
        constructor() {
          this.canvas = document.getElementById('gameCanvas');
          this.ctx = this.canvas.getContext('2d');
          this.sound = new SoundEngine();

          this.hudLevel = document.getElementById('hud-level');
          this.hudScore = document.getElementById('hud-score');
          this.screenStart = document.getElementById('screen-start');
          this.screenClear = document.getElementById('screen-clear');
          this.screenGameover = document.getElementById('screen-gameover');

          this.state = 'START';
          this.level = 1;
          this.score = 0;
          this.orbitAngle = 0;
          this.direction = 1;
          this.currentAngularVel = 1.4;

          this.attachedNodes = [];
          this.projectiles = [];
          this.remainingToShoot = 5;
          this.particles = [];
          this.shockwaves = [];
          this.lastFrameTime = performance.now();

          this.resize();
          this.bindEvents();
          this.setupDemoOrbit();
          requestAnimationFrame((t) => this.loop(t));
        }

        resize() {
          this.width = window.innerWidth;
          this.height = window.innerHeight;
          this.canvas.width = this.width;
          this.canvas.height = this.height;
          this.cx = this.width * 0.5;
          this.cy = this.height * 0.38;
          this.coreRadius = 42;
          this.orbitRadius = 120;
          this.nodeRadius = 12;
          this.launcherY = Math.min(this.height - 110, this.cy + this.orbitRadius + 150);
        }

        setupDemoOrbit() {
          this.attachedNodes = [];
          for (let i = 0; i < 5; i++) {
            this.attachedNodes.push({ angle: (i / 5) * Math.PI * 2, type: 'player' });
          }
        }

        startNewGame() {
          this.sound.init();
          this.level = 1;
          this.score = 0;
          this.loadLevel(1);
          this.setState('PLAYING');
        }

        loadLevel(lvl) {
          this.level = lvl;
          this.config = getLevelConfig(lvl);
          this.orbitAngle = 0;
          this.direction = this.config.direction;
          this.currentAngularVel = this.config.baseSpeed * this.direction;
          this.projectiles = [];
          this.attachedNodes = [];
          this.remainingToShoot = this.config.nodesToShoot;

          for (let i = 0; i < this.config.obstacles; i++) {
            this.attachedNodes.push({
              angle: (i / this.config.obstacles) * Math.PI * 2,
              type: 'obstacle'
            });
          }
          this.hudLevel.textContent = 'LVL ' + String(this.level).padStart(2, '0');
          this.hudScore.textContent = this.score.toLocaleString();

          // Beritahu Flutter bahwa level dimulai
          if (window.FlutterBridge) {
            window.FlutterBridge.postMessage(JSON.stringify({ event: 'LEVEL_START', level: this.level }));
          }
        }

        setState(newState) {
          this.state = newState;
          this.screenStart.classList.toggle('hidden', newState !== 'START');
          this.screenClear.classList.toggle('hidden', newState !== 'LEVEL_CLEAR');
          this.screenGameover.classList.toggle('hidden', newState !== 'GAME_OVER');
        }

        bindEvents() {
          window.addEventListener('resize', () => this.resize());
          this.canvas.addEventListener('pointerdown', (e) => {
            e.preventDefault();
            this.sound.init();
            if (this.state === 'PLAYING') this.fireNode();
          });

          document.getElementById('btn-start').addEventListener('click', () => this.startNewGame());
          document.getElementById('btn-next-level').addEventListener('click', () => this.advanceNextLevel());
          document.getElementById('btn-retry').addEventListener('click', () => this.startNewGame());

          // Bridge: Klaim reward nonton video
          document.getElementById('btn-claim-reward').addEventListener('click', () => {
            if (window.FlutterBridge) {
              window.FlutterBridge.postMessage(JSON.stringify({
                event: 'WATCH_AD',
                level: this.level
              }));
            }
          });

          document.getElementById('btn-sound').addEventListener('click', () => {
            this.sound.toggleMute();
            document.getElementById('icon-sound-on').style.display = this.sound.muted ? 'none' : 'block';
            document.getElementById('icon-sound-off').style.display = this.sound.muted ? 'block' : 'none';
          });
        }

        advanceNextLevel() {
          this.loadLevel(this.level + 1);
          this.setState('PLAYING');
        }

        fireNode() {
          if (this.state !== 'PLAYING' || this.remainingToShoot <= 0) return;
          const num = this.remainingToShoot;
          this.remainingToShoot--;
          this.projectiles.push({
            y: this.launcherY - 15,
            speed: 1500,
            label: String(num)
          });
          this.sound.playShoot();
        }

        loop(now) {
          const dt = Math.min((now - this.lastFrameTime) / 1000, 0.05);
          this.lastFrameTime = now;
          this.update(dt);
          this.render();
          requestAnimationFrame((t) => this.loop(t));
        }

        update(dt) {
          const deltaAngle = this.currentAngularVel * dt;
          this.orbitAngle = (this.orbitAngle + deltaAngle) % (Math.PI * 2);

          for (const node of this.attachedNodes) {
            node.angle = (node.angle + deltaAngle) % (Math.PI * 2);
          }

          if (this.state !== 'PLAYING') return;

          const impactY = this.cy + this.orbitRadius;
          const entryAngle = Math.PI * 0.5;
          const minSafeAngle = (this.nodeRadius * 2) / this.orbitRadius;

          for (let i = this.projectiles.length - 1; i >= 0; i--) {
            const p = this.projectiles[i];
            p.y -= p.speed * dt;

            if (p.y <= impactY) {
              let collided = false;
              for (const existing of this.attachedNodes) {
                let diff = Math.abs(((entryAngle - existing.angle) % (Math.PI * 2)));
                if (diff > Math.PI) diff = Math.PI * 2 - diff;
                if (diff < minSafeAngle) {
                  collided = true;
                  break;
                }
              }

              this.projectiles.splice(i, 1);

              if (collided) {
                this.sound.playCrash();
                this.setState('GAME_OVER');
                document.getElementById('gameover-score').textContent = this.score.toLocaleString();
                document.getElementById('gameover-level').textContent = 'LVL ' + String(this.level).padStart(2, '0');
                if (window.FlutterBridge) {
                  window.FlutterBridge.postMessage(JSON.stringify({ event: 'GAME_OVER', level: this.level, score: this.score }));
                }
                return;
              } else {
                this.sound.playLock();
                this.attachedNodes.push({ angle: entryAngle, type: 'player', label: p.label });
                this.score += 100;
                this.hudScore.textContent = this.score.toLocaleString();

                if (this.remainingToShoot === 0 && this.projectiles.length === 0) {
                  this.sound.playLevelClear();
                  this.setState('LEVEL_CLEAR');
                  document.getElementById('clear-score').textContent = this.score.toLocaleString();
                  const stars = document.querySelectorAll('#clear-stars .star-icon');
                  stars.forEach((s, idx) => {
                    setTimeout(() => s.classList.add('earned'), idx * 150);
                  });

                  if (window.FlutterBridge) {
                    window.FlutterBridge.postMessage(JSON.stringify({
                      event: 'LEVEL_CLEARED',
                      level: this.level,
                      score: this.score
                    }));
                  }
                }
              }
            }
          }
        }

        render() {
          const ctx = this.ctx;
          ctx.clearRect(0, 0, this.width, this.height);

          // Orbit Track
          ctx.strokeStyle = 'rgba(0, 240, 255, 0.45)';
          ctx.lineWidth = 2.5;
          ctx.beginPath();
          ctx.arc(this.cx, this.cy, this.orbitRadius, 0, Math.PI * 2);
          ctx.stroke();

          // Nodes
          for (const node of this.attachedNodes) {
            const nx = this.cx + Math.cos(node.angle) * this.orbitRadius;
            const ny = this.cy + Math.sin(node.angle) * this.orbitRadius;
            const isObs = node.type === 'obstacle';

            ctx.strokeStyle = isObs ? '#ff9900' : '#00f0ff';
            ctx.lineWidth = 2;
            ctx.beginPath();
            ctx.moveTo(this.cx, this.cy);
            ctx.lineTo(nx, ny);
            ctx.stroke();

            ctx.fillStyle = isObs ? '#ff9900' : '#00f0ff';
            ctx.beginPath();
            ctx.arc(nx, ny, this.nodeRadius, 0, Math.PI * 2);
            ctx.fill();

            if (node.label) {
              ctx.fillStyle = '#000';
              ctx.font = '700 10px monospace';
              ctx.textAlign = 'center';
              ctx.textBaseline = 'middle';
              ctx.fillText(node.label, nx, ny);
            }
          }

          // Center Core
          ctx.fillStyle = '#070f24';
          ctx.strokeStyle = '#00f0ff';
          ctx.lineWidth = 3;
          ctx.beginPath();
          ctx.arc(this.cx, this.cy, this.coreRadius, 0, Math.PI * 2);
          ctx.fill();
          ctx.stroke();

          ctx.fillStyle = '#ffffff';
          ctx.font = '900 24px Orbitron, monospace';
          ctx.textAlign = 'center';
          ctx.textBaseline = 'middle';
          ctx.fillText(this.state === 'START' ? 'Q' : String(this.remainingToShoot), this.cx, this.cy);

          // Projectiles
          for (const p of this.projectiles) {
            ctx.fillStyle = '#00f0ff';
            ctx.beginPath();
            ctx.arc(this.cx, p.y, this.nodeRadius, 0, Math.PI * 2);
            ctx.fill();
          }

          // Launcher
          if (this.state === 'PLAYING') {
            ctx.fillStyle = '#ff9900';
            ctx.beginPath();
            ctx.arc(this.cx, this.launcherY, this.nodeRadius, 0, Math.PI * 2);
            ctx.fill();
          }
        }
      }

      window.addEventListener('DOMContentLoaded', () => {
        window.gameInstance = new CyberOrbitGame();
      });

      // Callback dari Flutter saat Reward berhasil masuk
      window.onRewardSuccess = function(amountText) {
        alert('🎉 Saldo +' + amountText + ' Berhasil Masuk ke Akun Anda!');
        if (window.gameInstance) {
          window.gameInstance.advanceNextLevel();
        }
      };

      // Konfigurasi Bahasa & Mata Uang Dinamis dari Flutter (IDR, USD, EUR, dll)
      window.setGameLocale = function(cfg) {
        if (!cfg) return;
        const bonusEl = document.getElementById('clear-bonus');
        const btnClaimEl = document.getElementById('btn-claim-reward');
        const titleClearEl = document.querySelector('#screen-clear h2');
        const btnSkipEl = document.getElementById('btn-next-level');
        const btnRetryEl = document.getElementById('btn-retry');
        const startDescEl = document.querySelector('#screen-start .desc-text');
        const startBtnEl = document.getElementById('btn-start');

        if (bonusEl && cfg.rewardText) bonusEl.textContent = cfg.rewardText;
        if (btnClaimEl && cfg.btnClaimText) btnClaimEl.textContent = cfg.btnClaimText;
        if (titleClearEl && cfg.titleClear) titleClearEl.textContent = cfg.titleClear;
        if (btnSkipEl && cfg.btnSkip) btnSkipEl.textContent = cfg.btnSkip;
        if (btnRetryEl && cfg.btnRetry) btnRetryEl.textContent = cfg.btnRetry;
        if (startDescEl && cfg.startDesc) startDescEl.textContent = cfg.startDesc;
        if (startBtnEl && cfg.startBtn) startBtnEl.textContent = cfg.startBtn;
      };

      window.setCurrency = function(rewardText) {
        window.setGameLocale({ rewardText: rewardText });
      };
    })();
  </script>
</body>
</html>
''';
