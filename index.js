/**
 * APPDOCK HUB ECOSYSTEM - CLOUDFLARE WORKER (index.js)
 * Architecture: Cloudflare Workers + D1 Database (SQLite) + Telegram Webhook
 * Multi-Product License Manager, 2-Tier Affiliate System, Rewarded Ads Quota Engine
 */

// ============================================================================
// ⚙️ KONFIGURASI GLOBAL
// ============================================================================
const CONFIG = {
  BOT_TOKEN: '8844891986:AAHXnpu00vewiq0mva8Wra7TJbi8nBChCYQ',
  ADMIN_TELEGRAM_ID: '8916556502',
  BOT_USERNAME: 'AppDockHub_Bot',
  QRIS_IMAGE_URL: 'https://i.ibb.co.com/RkvpWdTm/qris.jpg',
  TIER1_RATE: 0.30, // 30% Komisi Penjual Langsung
  TIER2_RATE: 0.05, // 5% Komisi Pasif Sponsor Tim
  MAX_DAILY_ADS: 10, // Batas harian nonton iklan rewarded
  AD_REWARD_AMOUNT: 10 // Rp 10 per iklan ditonton
};

// Daftar Katalog Software Digital Resmi AppDock Hub
const PRODUCTS = {
  'reddit_pro': {
    name: 'Reddit Manager Pro',
    price: 99000,
    formattedPrice: 'Rp 99.000',
    prefix: 'RD-PRO'
  },
  'fb_pro': {
    name: 'Facebook Account Manager Pro',
    price: 99000,
    formattedPrice: 'Rp 99.000',
    prefix: 'FB-PRO'
  },
  'tiktok_pro': {
    name: 'TikTok Multi-Screen Pro',
    price: 99000,
    formattedPrice: 'Rp 99.000',
    prefix: 'TK-PRO'
  },
  'linkedin_pro': {
    name: 'LinkedIn Manager Pro',
    price: 99000,
    formattedPrice: 'Rp 99.000',
    prefix: 'IN-PRO'
  },
  'pinterest_pro': {
    name: 'Pinterest Manager Pro',
    price: 99000,
    formattedPrice: 'Rp 99.000',
    prefix: 'PIN-PRO'
  },
  'x_pro': {
    name: 'X (Twitter) Manager Pro',
    price: 99000,
    formattedPrice: 'Rp 99.000',
    prefix: 'X-PRO'
  },
  'soft_a': {
    name: 'Jualin Aja',
    price: 299000,
    formattedPrice: 'Rp 299.000',
    prefix: 'JA-PRO'
  }
};

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization'
};

const MAIN_KEYBOARD = {
  keyboard: [
    [{ text: '📦 Beli Software' }, { text: '🔗 Link Afiliasi Saya' }],
    [{ text: '💳 Cek Saldo' }, { text: '💸 Tarik Saldo' }]
  ],
  resize_keyboard: true,
  is_persistent: true
};

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    // Tangani Preflight CORS
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: CORS_HEADERS });
    }

    try {
      // ----------------------------------------------------------------------
      // ROUTE 1: GET / -> RENDER WEB PORTAL AKTIVASI HWID
      // ----------------------------------------------------------------------
      if (url.pathname === '/' && request.method === 'GET') {
        const ref = url.searchParams.get('ref') || 'direct';
        return new Response(renderActivationPageHtml(ref), {
          headers: { 'Content-Type': 'text/html; charset=utf-8' }
        });
      }

      // ----------------------------------------------------------------------
      // ROUTE 2: POST /activate -> VALIDASI & IKAT LISENSI KE HWID (1 DEVICE)
      // ----------------------------------------------------------------------
      if (url.pathname === '/activate' && request.method === 'POST') {
        return await handleLicenseActivation(request, env);
      }

      // ----------------------------------------------------------------------
      // ROUTE 3: POST /api/ads/reward -> TRACKING REWARDED ADS & LIMIT 10/HARI
      // ----------------------------------------------------------------------
      if (url.pathname === '/api/ads/reward' && request.method === 'POST') {
        return await handleAdsReward(request, env);
      }

      // ----------------------------------------------------------------------
      // ROUTE 3B: POST /api/game/level-cleared -> BONUS MILESTONE REFERRAL GAME
      // ----------------------------------------------------------------------
      if (url.pathname === '/api/game/level-cleared' && request.method === 'POST') {
        return await handleGameLevelCleared(request, env);
      }

      // ----------------------------------------------------------------------
      // ROUTE 4: GET /verify -> CEK STATUS LISENSI HWID OLEH DESKTOP/APK
      // ----------------------------------------------------------------------
      if (url.pathname === '/verify') {
        return await handleVerifyLicense(request, env, url);
      }

      // ----------------------------------------------------------------------
      // ROUTE 5: POST /set-webhook -> REGISTER BOT TELEGRAM WEBHOOK OTOMATIS
      // ----------------------------------------------------------------------
      if (url.pathname === '/set-webhook') {
        const workerWebhook = `https://${url.hostname}/telegram-webhook`;
        const res = await fetch(`https://api.telegram.org/bot${CONFIG.BOT_TOKEN}/setWebhook?url=${encodeURIComponent(workerWebhook)}&drop_pending_updates=true`);
        const data = await res.json();
        return new Response(JSON.stringify(data, null, 2), {
          headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' }
        });
      }

      // ----------------------------------------------------------------------
      // ROUTE 6: POST /telegram-webhook & /bot-webhook -> TELEGRAM BOT HANDLER
      // ----------------------------------------------------------------------
      if ((url.pathname === '/telegram-webhook' || url.pathname === '/bot-webhook') && request.method === 'POST') {
        let update;
        try {
          update = await request.json();
        } catch {
          return new Response('Invalid JSON Payload', { status: 400 });
        }
        await handleTelegramUpdate(update, env);
        return new Response('OK');
      }

      return new Response('Not Found', { status: 404, headers: CORS_HEADERS });

    } catch (err) {
      console.error('Global Worker Exception:', err);
      return new Response(JSON.stringify({ error: err.message, stack: err.stack }), {
        status: 500,
        headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' }
      });
    }
  }
};

// ============================================================================
// 1. HANDLER AKTIVASI LISENSI (1 Device = 1 License)
// ============================================================================
async function handleLicenseActivation(request, env) {
  let body = {};
  try {
    body = await request.json();
  } catch (e) {
    return jsonResponse({ valid: false, status: 'error', message: 'Payload JSON tidak valid' }, 400);
  }

  const hwid = (body.hwid || '').trim();
  const licenseKey = (body.licenseKey || body.key || '').trim().toUpperCase();

  if (!hwid || !licenseKey) {
    return jsonResponse({
      valid: false,
      status: 'error',
      message: 'Kode HWID dan License Key wajib diisi!'
    }, 400);
  }

  // Jika D1 database binding tersedia
  if (env.DB) {
    // Cari lisensi di database
    const lic = await env.DB.prepare('SELECT * FROM licenses WHERE license_key = ?').bind(licenseKey).first();

    if (!lic) {
      return jsonResponse({
        valid: false,
        status: 'not_found',
        message: 'Kunci lisensi tidak ditemukan atau belum terdaftar!'
      }, 404);
    }

    if (lic.status === 'REVOKED') {
      return jsonResponse({
        valid: false,
        status: 'revoked',
        message: 'Lisensi ini telah dinonaktifkan oleh Administrator.'
      }, 403);
    }

    // Jika lisensi sudah aktif sebelumnya
    if (lic.status === 'ACTIVE') {
      if (lic.hwid === hwid) {
        return jsonResponse({
          valid: true,
          status: 'success',
          product: lic.product_name,
          licenseKey,
          hwid,
          message: 'Lisensi aktif untuk perangkat ini!'
        });
      } else {
        return jsonResponse({
          valid: false,
          status: 'mismatch',
          message: 'Lisensi sudah terikat ke perangkat lain! 1 License = 1 Device.'
        }, 409);
      }
    }

    // Jika status AVAILABLE, ikat HWID dan ubah ke ACTIVE
    if (lic.status === 'AVAILABLE') {
      await env.DB.prepare(
        'UPDATE licenses SET hwid = ?, status = ?, activated_at = CURRENT_TIMESTAMP WHERE license_key = ?'
      ).bind(hwid, 'ACTIVE', licenseKey).run();

      return jsonResponse({
        valid: true,
        status: 'success',
        product: lic.product_name,
        licenseKey,
        hwid,
        message: `Aktivasi ${lic.product_name} Berhasil! Software siap digunakan.`
      });
    }
  }

  // Fallback ke KV jika D1 belum terikat
  if (env.LICENSE_KV) {
    const raw = await env.LICENSE_KV.get(hwid);
    if (raw) {
      const data = JSON.parse(raw);
      if (data.licenseKey === licenseKey && data.status === 'active') {
        return jsonResponse({ valid: true, status: 'success', product: data.product, message: 'Lisensi Aktif!' });
      }
    }
  }

  return jsonResponse({
    valid: false,
    status: 'error',
    message: 'Lisensi belum terdaftar di sistem.'
  }, 400);
}

// ============================================================================
// 2. HANDLER REWARDED ADS (Limit 10 Iklan / Hari & Reset Otomatis)
// ============================================================================
async function handleAdsReward(request, env) {
  let body = {};
  try {
    body = await request.json();
  } catch {
    return jsonResponse({ success: false, message: 'Invalid payload' }, 400);
  }

  const pairToken = (body.pairToken || body.app_pair_token || '').trim();
  const rewardToAdd = body.rewardAmount ? parseFloat(body.rewardAmount) : CONFIG.AD_REWARD_AMOUNT;

  if (!pairToken) {
    return jsonResponse({ success: false, message: 'Pair token diperlukan' }, 400);
  }

  if (!env.DB) {
    return jsonResponse({ success: false, message: 'Database D1 belum terkonfigurasi' }, 500);
  }

  // Format tanggal lokal YYYY-MM-DD
  const todayStr = new Date().toISOString().slice(0, 10);

  // Cari user berdasarkan app_pair_token
  let user = await env.DB.prepare('SELECT * FROM users WHERE app_pair_token = ?').bind(pairToken).first();

  if (!user) {
    // Buat record user sementara jika belum pairing ke Telegram
    const tempTelegramId = `temp_${pairToken.slice(0, 8)}`;
    await env.DB.prepare(
      'INSERT INTO users (telegram_id, app_pair_token, balance_direct, balance_team, balance_ads, ads_watched_today, last_ad_watch_date) VALUES (?, ?, 0, 0, 0, 0, ?)'
    ).bind(tempTelegramId, pairToken, todayStr).run();

    user = await env.DB.prepare('SELECT * FROM users WHERE app_pair_token = ?').bind(pairToken).first();
  }

  // Cek apakah tanggal sudah berganti (Auto-Reset Harian)
  let watchedToday = user.ads_watched_today || 0;
  if (user.last_ad_watch_date !== todayStr) {
    watchedToday = 0;
  }

  // CEK KUOTA LIMIT 10 IKLAN / HARI
  if (watchedToday >= CONFIG.MAX_DAILY_ADS) {
    return jsonResponse({
      success: false,
      limitReached: true,
      adsWatchedToday: CONFIG.MAX_DAILY_ADS,
      remainingQuota: 0,
      currentBalanceAds: user.balance_ads,
      message: 'Kuota 10 iklan harian Anda telah habis! Beralihlah ke Program Afiliasi 2-Tier untuk komisi tanpa batas kuota.',
      funnelOffer: {
        title: 'Unlimited Earning via Afiliasi 2-Tier',
        directCommission: 'Rp 29.700 per closing (30%)',
        teamCommission: 'Rp 4.950 per closing tim (5%)',
        botLink: `https://t.me/${CONFIG.BOT_USERNAME}?start=affiliate`
      }
    });
  }

  // Tambahkan reward & naikkan counter iklan
  watchedToday += 1;
  const newBalanceAds = (user.balance_ads || 0) + rewardToAdd;

  await env.DB.prepare(
    'UPDATE users SET ads_watched_today = ?, balance_ads = ?, last_ad_watch_date = ? WHERE app_pair_token = ?'
  ).bind(watchedToday, newBalanceAds, todayStr, pairToken).run();

  const isLimitNow = watchedToday >= CONFIG.MAX_DAILY_ADS;
  const remaining = CONFIG.MAX_DAILY_ADS - watchedToday;

  // Notifikasi instan ke Telegram jika user sudah terhubung
  if (user.telegram_id && !user.telegram_id.startsWith('temp_')) {
    let notifyMsg = `📺 *REWARDED AD BERHASIL DITONTON!*\n\n` +
      `💰 Saldo Bertambah: *+Rp ${rewardToAdd.toLocaleString('id-ID')}*\n` +
      `🎯 Kuota Hari Ini: *${watchedToday}/${CONFIG.MAX_DAILY_ADS}*\n` +
      `💵 Total Saldo Iklan: *Rp ${newBalanceAds.toLocaleString('id-ID')}*`;

    if (isLimitNow) {
      notifyMsg += `\n\n🔒 *KUOTA HARIAN HABIS (10/10)!*\n` +
        `Mau dapat Rp 30.000 / closing tanpa batas kuota? Ketik /daftar untuk aktivasi link Afiliasi Anda!`;
    }

    await sendTelegramMessage(user.telegram_id, notifyMsg);
  }

  return jsonResponse({
    success: true,
    limitReached: isLimitNow,
    adsWatchedToday: watchedToday,
    remainingQuota: remaining,
    rewardAdded: rewardToAdd,
    currentBalanceAds: newBalanceAds,
    message: isLimitNow
      ? 'Selamat! Kuota 10 iklan harian selesai ditonton.'
      : `Iklan ke-${watchedToday} sukses. Sisa kuota hari ini: ${remaining} iklan.`
  });
}

// ============================================================================
// 2B. HANDLER MILESTONE REFERRAL GAME (TIAP 10 LEVEL = RP 50, MAKS LEVEL 2000 = 10K IDR)
// ============================================================================
async function handleGameLevelCleared(request, env) {
  let body = {};
  try {
    body = await request.json();
  } catch {
    return jsonResponse({ success: false, message: 'Invalid payload' }, 400);
  }

  const pairToken = (body.pairToken || '').trim();
  const level = parseInt(body.level) || 0;

  if (!pairToken || level <= 0) {
    return jsonResponse({ success: false, message: 'pairToken & valid level required' }, 400);
  }

  if (!env.DB) {
    return jsonResponse({ success: true, level });
  }

  const user = await env.DB.prepare('SELECT * FROM users WHERE app_pair_token = ?').bind(pairToken).first();
  if (!user) {
    return jsonResponse({ success: true, level });
  }

  // Update max_level user
  const curMax = user.max_level || 1;
  const newMax = Math.max(curMax, level);
  await env.DB.prepare('UPDATE users SET max_level = ? WHERE app_pair_token = ?').bind(newMax, pairToken).run();

  // Cek apakah mencapai milestone kelipatan 10 (Level 10, 20, 30, ... maks Level 2000)
  if (level % 10 === 0 && level <= 2000) {
    const lastAwarded = user.last_milestone_awarded || 0;
    if (lastAwarded < level) {
      // Aturan: Tiap 10 level dapat Rp 50 (Maks Level 2000 = 200 milestone x Rp 50 = Rp 10.000 / 10k IDR per referral)
      const milestoneBonus = 50;

      // Berikan reward ke Sponsor (referrer_id) jika ada
      if (user.referrer_id && user.referrer_id !== user.telegram_id) {
        await env.DB.prepare(
          'UPDATE users SET balance_team = balance_team + ? WHERE telegram_id = ?'
        ).bind(milestoneBonus, user.referrer_id).run();

        const playerName = user.telegram_id && !user.telegram_id.startsWith('temp_')
            ? `ID: ${user.telegram_id}`
            : 'Referral Anda';

        // Notifikasi Telegram instan ke Pengundang / Sponsor
        await sendTelegramMessage(user.referrer_id,
          `🎯 *BONUS MILESTONE LEVEL REFERRAL MASUK!*\n\n` +
          `Luar biasa! Teman yang Anda undang (*${playerName}*) baru saja menembus *Level ${level}* di Cyber Orbit!\n` +
          `💰 Bonus Referral Masuk: *+Rp ${milestoneBonus.toLocaleString('id-ID')}*\n\n` +
          `🔥 Anda mendapatkan Rp 50 setiap referral menembus kelipatan 10 level (hingga Level 2000)! Terus bagikan link Anda!`
        );
      }

      await env.DB.prepare('UPDATE users SET last_milestone_awarded = ? WHERE app_pair_token = ?').bind(level, pairToken).run();

      return jsonResponse({
        success: true,
        milestoneAwarded: true,
        level,
        milestoneBonus,
        message: `Milestone Level ${level} berhasil dicatat!`
      });
    }
  }

  return jsonResponse({ success: true, level });
}

// ============================================================================
// 3. HANDLER VERIFIKASI LISENSI (/verify)
// ============================================================================
async function handleVerifyLicense(request, env, url) {
  let hwid = url.searchParams.get('hwid');
  if (request.method === 'POST') {
    try {
      const b = await request.json();
      if (b && b.hwid) hwid = b.hwid;
    } catch {}
  }

  if (!hwid) {
    return jsonResponse({ valid: false, message: 'HWID parameter is missing' }, 400);
  }

  if (env.DB) {
    const lic = await env.DB.prepare('SELECT * FROM licenses WHERE hwid = ? AND status = ?').bind(hwid.trim(), 'ACTIVE').first();
    if (lic) {
      return jsonResponse({
        valid: true,
        status: 'active',
        hwid,
        licenseKey: lic.license_key,
        productName: lic.product_name,
        activatedAt: lic.activated_at
      });
    }
  }

  return jsonResponse({
    valid: false,
    status: 'unregistered',
    message: 'Perangkat ini belum memiliki lisensi aktif.'
  });
}

// ============================================================================
// 4. TELEGRAM BOT HANDLER (COMMANDS, 2-TIER AFILIASI, QRIS, & PAYMENTS)
// ============================================================================
async function handleTelegramUpdate(update, env) {
  // A. CALLBACK QUERY (Tombol Inline)
  if (update.callback_query) {
    const cb = update.callback_query;
    const action = cb.data;
    const chatId = cb.message.chat.id;

    // Jawab callback Telegram agar loading berhenti
    await fetch(`https://api.telegram.org/bot${CONFIG.BOT_TOKEN}/answerCallbackQuery`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ callback_query_id: cb.id })
    });

    // 1. Order Produk
    if (action.startsWith('buy_')) {
      const parts = action.replace('buy_', '').split('_ref_');
      const prodKey = parts[0];
      const refCode = parts[1] || 'direct';

      const prod = PRODUCTS[prodKey] || PRODUCTS['reddit_pro'];
      const caption = generateQrisCaption(prod.name, prod.formattedPrice, refCode);

      // Simpan pending order ke D1 jika ada
      if (env.DB) {
        await env.DB.prepare(
          'INSERT INTO transactions (buyer_telegram_id, product_name, amount, tier1_seller_id, status) VALUES (?, ?, ?, ?, ?)'
        ).bind(String(chatId), prod.name, prod.price, refCode, 'PENDING').run();
      }

      await sendTelegramPhoto(chatId, CONFIG.QRIS_IMAGE_URL, caption);

      // Notifikasi Admin Ada Lead Baru
      await sendTelegramMessage(CONFIG.ADMIN_TELEGRAM_ID,
        `🛒 *LEAD BARU MASUK!*\n\n` +
        `👤 *Pembeli:* ${cb.from.first_name || 'User'} (\`${chatId}\`)\n` +
        `📦 *Paket:* ${prod.name} (${prod.formattedPrice})\n` +
        `👥 *Afiliator (Tier 1):* \`${refCode}\`\n` +
        `⏳ *Status:* Menunggu transfer & upload bukti scan QRIS`
      );
    }

    // 2. Admin Menyetujui Pembayaran & Distribusi Komisi 2-Tier
    else if (action.startsWith('approve:')) {
      // Format: approve:buyerId:productKey:sellerId:hwid
      const parts = action.split(':');
      const buyerId = parts[1];
      const prodKey = parts[2];
      const sellerId = parts[3];
      const hwid = parts.slice(4).join(':').trim();

      await processOrderApproval(env, buyerId, prodKey, sellerId, hwid);
    }

    // 3. Admin Menolak Transaksi
    else if (action.startsWith('reject:')) {
      const buyerId = action.split(':')[1];
      await sendTelegramMessage(buyerId, '❌ Pembayaran belum dapat diverifikasi atau ditolak oleh Admin. Hubungi kami jika ini kekeliruan.');
      await sendTelegramMessage(CONFIG.ADMIN_TELEGRAM_ID, `⚠️ Pembelian oleh user \`${buyerId}\` telah ditolak.`);
    }

    return;
  }

  // B. PESAN TEKS & MEDIA DARI USER
  if (update.message) {
    const msg = update.message;
    const chatId = String(msg.chat.id);
    const rawText = (msg.text || '').trim();
    const lowerText = rawText.toLowerCase();
    const userName = msg.from ? msg.from.first_name : 'Pengguna';
    const photo = msg.photo;

    // Pastikan user tercatat di D1
    if (env.DB) {
      await ensureUserExists(env.DB, chatId);
    }

    // 1. COMMAND: /start DENGAN PARAMETER
    if (lowerText.startsWith('/start')) {
      const parts = rawText.split(' ');
      const startParam = parts[1] || '';

      // A. Pairing APK -> Bot (/start pair_<token>)
      if (startParam.startsWith('pair_')) {
        const token = startParam.replace('pair_', '').trim();
        if (env.DB) {
          // Cari user dengan pair token tersebut
          const existing = await env.DB.prepare('SELECT * FROM users WHERE app_pair_token = ?').bind(token).first();
          if (existing) {
            // Update telegram_id ke akun yang sedang chat
            await env.DB.prepare('UPDATE users SET telegram_id = ? WHERE app_pair_token = ?').bind(chatId, token).run();
          } else {
            await env.DB.prepare(
              'INSERT INTO users (telegram_id, app_pair_token) VALUES (?, ?) ON CONFLICT(telegram_id) DO UPDATE SET app_pair_token = ?'
            ).bind(chatId, token, token).run();
          }
        }
        await sendTelegramMessage(chatId,
          `✅ *PAIRING BERHASIL!*\n\n` +
          `Aplikasi Android (APK) Anda telah terhubung dengan akun Telegram ini.\n` +
          `Poin nonton iklan rewarded dan notifikasi lisensi Anda akan disinkronkan secara otomatis!`
        );
        return;
      }

      // B. Referral Sponsor Afiliasi (/start ref_<uplineId>)
      if (startParam.startsWith('ref_')) {
        const uplineId = startParam.replace('ref_', '').trim();
        if (env.DB && uplineId !== chatId) {
          const me = await env.DB.prepare('SELECT * FROM users WHERE telegram_id = ?').bind(chatId).first();
          if (me && !me.referrer_id) {
            await env.DB.prepare('UPDATE users SET referrer_id = ? WHERE telegram_id = ?').bind(uplineId, chatId).run();
            // Notifikasi Upline
            await sendTelegramMessage(uplineId,
              `👥 *MITRA TIM BARU TERDAFTAR!*\n\n` +
              `Pengguna baru *${userName}* bergabung lewat link referral Anda.\n` +
              `Anda berhak atas *Komisi Pasif 5% (Tier 2)* dari setiap penjualan software yang mereka hasilkan! 🔥`
            );
          }
        }
      }

      // Menu Utama Sambutan
      await sendTelegramMessage(chatId,
        `Halo ${userName}! 👋\n` +
        `Selamat datang di *AppDock Hub Ecosystem*.\n\n` +
        `🚀 *Pusat Software Otomatisasi & Bisnis Digital 2026*\n` +
        `Dapatkan software otomatisasi kelas industri dan bangun passive income harian via *Sistem Afiliasi 2-Tier*:\n\n` +
        `🥇 *Tier 1 (Direct Seller):* Komisi 30% (~Rp 29.700 / software)\n` +
        `🥈 *Tier 2 (Sponsor Tim):* Komisi Pasif 5% (~Rp 4.950 / penjualan tim)\n` +
        `📺 *Rewarded Ads Quota:* Nonton iklan maks 10x/hari di APK.\n\n` +
        `Gunakan menu tombol di bawah untuk navigasi:`,
        MAIN_KEYBOARD
      );
      return;
    }

    // 2. MENU: 📦 BELI SOFTWARE
    if (lowerText === '📦 beli software' || lowerText === '/buy' || lowerText === 'beli') {
      let refId = 'direct';
      if (env.DB) {
        const u = await env.DB.prepare('SELECT referrer_id FROM users WHERE telegram_id = ?').bind(chatId).first();
        if (u && u.referrer_id) refId = u.referrer_id;
      }

      const keyboard = {
        inline_keyboard: [
          [{ text: '🔥 Reddit Manager Pro (Rp 99.000)', callback_data: `buy_reddit_pro_ref_${refId}` }],
          [{ text: '🔵 Facebook Account Manager Pro (Rp 99.000)', callback_data: `buy_fb_pro_ref_${refId}` }],
          [{ text: '📱 TikTok Multi-Screen Pro (Rp 99.000)', callback_data: `buy_tiktok_pro_ref_${refId}` }],
          [{ text: '💼 LinkedIn Manager Pro (Rp 99.000)', callback_data: `buy_linkedin_pro_ref_${refId}` }],
          [{ text: '📌 Pinterest Manager Pro (Rp 99.000)', callback_data: `buy_pinterest_pro_ref_${refId}` }],
          [{ text: '🐦 X (Twitter) Manager Pro (Rp 99.000)', callback_data: `buy_x_pro_ref_${refId}` }],
          [{ text: '🛒 Jualin Aja (Rp 299.000)', callback_data: `buy_soft_a_ref_${refId}` }]
        ]
      };

      await sendTelegramMessage(chatId,
        `📦 *KATALOG SOFTWARE DIGITAL RESMI:*\n\n` +
        `Pilih software otomatisasi yang ingin Anda aktifkan lisensinya:\n` +
        `_1 Lisensi = 1 Perangkat Fisik (HWID Locked)_`,
        keyboard
      );
      return;
    }

    // 3. MENU: 🔗 LINK AFILIASI SAYA (2-TIER FUNNEL)
    if (lowerText === '🔗 link afiliasi saya' || lowerText === '/affiliate' || lowerText === '/link' || lowerText.includes('afiliasi')) {
      const refLink = `https://t.me/${CONFIG.BOT_USERNAME}?start=ref_${chatId}`;
      const directReward = 'Rp 29.700 (30%)';
      const teamReward = 'Rp 4.950 (5%)';

      await sendTelegramMessage(chatId,
        `🌟 *PROGRAM KEMITRAAN AFILIASI 2-TIER APPDOCK HUB*\n\n` +
        `Dapatkan penghasilan tanpa batas cukup dengan membagikan link Anda:\n\n` +
        `🔗 *Link Referral Unik Anda:*\n` +
        `\`${refLink}\`\n\n` +
        `🎮 *Bonus Progres Level Game Referral (NEW!):*\n` +
        `• Dapatkan *Rp 50* setiap referral menembus kelipatan 10 level (hingga Level 2000)!\n\n` +
        `💰 *Komisi Penjualan Software Digital:*\n` +
        `• *Tier 1 (Jual Langsung):* ${directReward} per lisensi software\n` +
        `• *Tier 2 (Bonus Sponsor Pasif):* ${teamReward} setiap kali teman yang Anda ajak berhasil closing!\n\n` +
        `📢 *Materi Promo Siap Sebar:*\n` +
        `_"Main game seru Cyber Orbit & otomatisasi bisnis digital! Dapatkan bonus harian atau mulai kemitraan tanpa modal di: ${refLink}"_`
      );
      return;
    }

    // 4. MENU: 💳 CEK SALDO (RINCIAN 30%, 5%, ADS, & TOTAL)
    if (lowerText === '💳 cek saldo' || lowerText === '/saldo' || lowerText === 'saldo') {
      let bDirect = 0, bTeam = 0, bAds = 0;
      if (env.DB) {
        const u = await env.DB.prepare('SELECT balance_direct, balance_team, balance_ads FROM users WHERE telegram_id = ?').bind(chatId).first();
        if (u) {
          bDirect = u.balance_direct || 0;
          bTeam = u.balance_team || 0;
          bAds = u.balance_ads || 0;
        }
      }
      const total = bDirect + bTeam + bAds;

      await sendTelegramMessage(chatId,
        `💳 *RINCIAN SALDO DOMPET ANDA*\n\n` +
        `🥇 Komisi Langsung (Tier 1 - 30%): *Rp ${bDirect.toLocaleString('id-ID')}*\n` +
        `🥈 Komisi Tim Sponsor (Tier 2 - 5%): *Rp ${bTeam.toLocaleString('id-ID')}*\n` +
        `📺 Saldo Nonton Iklan (APK): *Rp ${bAds.toLocaleString('id-ID')}*\n` +
        `-----------------------------------------\n` +
        `💵 *TOTAL SALDO DAPAT DICAIRKAN:* *Rp ${total.toLocaleString('id-ID')}*\n\n` +
        `Minimal penarikan adalah Rp 50.000. Klik tombol *💸 Tarik Saldo* untuk pencairan ke E-Wallet.`
      );
      return;
    }

    // 5. MENU: 💸 TARIK SALDO (FORM WITHDRAWAL KE E-WALLET)
    if (lowerText === '💸 tarik saldo' || lowerText === '/tarik' || lowerText === 'tarik') {
      let total = 0;
      if (env.DB) {
        const u = await env.DB.prepare('SELECT balance_direct + balance_team + balance_ads as total FROM users WHERE telegram_id = ?').bind(chatId).first();
        if (u) total = u.total || 0;
      }

      if (total < 50000) {
        await sendTelegramMessage(chatId,
          `⚠️ Saldo Anda saat ini *Rp ${total.toLocaleString('id-ID')}*.\n` +
          `Batas minimal penarikan adalah *Rp 50.000*.\n\n` +
          `Ajak teman atau bagikan link afiliasi Anda untuk mempercepat akumulasi saldo!`
        );
        return;
      }

      await sendTelegramMessage(chatId,
        `💸 *FORM PENCAIRAN SALDO (E-WALLET / BANK)*\n\n` +
        `Saldo Anda: *Rp ${total.toLocaleString('id-ID')}*\n\n` +
        `Silakan balas pesan ini dengan format:\n` +
        `\`tarik <Jumlah> <DANA/GoPay/OVO/BCA> <Nomor Rekening> <Nama Pemilik>\`\n\n` +
        `Contoh:\n` +
        `\`tarik ${total} DANA 08123456789 Budi Santoso\``
      );
      return;
    }

    // 6. PROSES FORM PENARIKAN (TARIK DANA)
    if (lowerText.startsWith('tarik ') && rawText.split(/\s+/).length >= 5) {
      const words = rawText.split(/\s+/);
      const amount = parseInt(words[1]);
      const provider = words[2].toUpperCase();
      const accountNo = words[3];
      const accountName = words.slice(4).join(' ');

      if (isNaN(amount) || amount < 50000) {
        await sendTelegramMessage(chatId, '⚠️ Nominal penarikan minimal Rp 50.000!');
        return;
      }

      if (env.DB) {
        const u = await env.DB.prepare('SELECT * FROM users WHERE telegram_id = ?').bind(chatId).first();
        const curTotal = (u.balance_direct || 0) + (u.balance_team || 0) + (u.balance_ads || 0);

        if (curTotal < amount) {
          await sendTelegramMessage(chatId, `⚠️ Saldo tidak mencukupi! Total saldo Anda: Rp ${curTotal.toLocaleString('id-ID')}`);
          return;
        }

        // Potong saldo secara berurutan: balance_direct -> balance_team -> balance_ads
        let rem = amount;
        let d = u.balance_direct || 0;
        let t = u.balance_team || 0;
        let a = u.balance_ads || 0;

        const cutD = Math.min(d, rem); rem -= cutD; d -= cutD;
        const cutT = Math.min(t, rem); rem -= cutT; t -= cutT;
        const cutA = Math.min(a, rem); rem -= cutA; a -= cutA;

        await env.DB.prepare(
          'UPDATE users SET balance_direct = ?, balance_team = ?, balance_ads = ? WHERE telegram_id = ?'
        ).bind(d, t, a, chatId).run();
      }

      // Notifikasi ke Admin untuk Transfer
      await sendTelegramMessage(CONFIG.ADMIN_TELEGRAM_ID,
        `🚨 *REQUEST PENCAIRAN SALDO BARU!*\n\n` +
        `👤 User: *${userName}* (\`${chatId}\`)\n` +
        `💰 Nominal: *Rp ${amount.toLocaleString('id-ID')}*\n` +
        `🏦 Provider: *${provider}*\n` +
        `🔢 No Rekening/HP: \`${accountNo}\`\n` +
        `📝 Atas Nama: *${accountName}*\n\n` +
        `Silakan transfer lalu kirim bukti ke user.`
      );

      await sendTelegramMessage(chatId,
        `✅ Permintaan pencairan *Rp ${amount.toLocaleString('id-ID')}* telah diteruskan ke Admin.\n` +
        `Dana akan ditransfer ke *${provider} (${accountNo})* dalam waktu maks 1x24 jam kerja.`
      );
      return;
    }

    // 7. USER MENGIRIM BUKTI FOTO ATAU HWID
    const isHwidInput = ['rd-', 'fb-', 'tk-', 'in-', 'pin-', 'x-', 'hwid'].some(pre => lowerText.startsWith(pre));
    if (photo || isHwidInput) {
      if (photo && !isHwidInput) {
        await sendTelegramMessage(chatId,
          `📸 *Bukti transfer diterima!*\n\n` +
          `Sekarang kirimkan *Kode HWID* perangkat Anda untuk pengikatan lisensi (contoh: \`RD-HWID-XXXX-XXXX\`).`
        );
        return;
      }

      const hwid = rawText;
      let pendingProd = 'reddit_pro';
      let pendingSeller = 'direct';

      if (env.DB) {
        const lastTx = await env.DB.prepare(
          'SELECT * FROM transactions WHERE buyer_telegram_id = ? AND status = ? ORDER BY id DESC LIMIT 1'
        ).bind(chatId, 'PENDING').first();

        if (lastTx) {
          pendingProd = Object.keys(PRODUCTS).find(k => PRODUCTS[k].name === lastTx.product_name) || 'reddit_pro';
          pendingSeller = lastTx.tier1_seller_id || 'direct';
        }
      }

      const prod = PRODUCTS[pendingProd] || PRODUCTS['reddit_pro'];
      const comm1 = Math.round(prod.price * CONFIG.TIER1_RATE);
      const comm2 = Math.round(prod.price * CONFIG.TIER2_RATE);

      const approvalKeyboard = {
        inline_keyboard: [
          [
            { text: '✅ Approve & Bagikan Komisi 2-Tier', callback_data: `approve:${chatId}:${pendingProd}:${pendingSeller}:${hwid}` },
            { text: '❌ Tolak', callback_data: `reject:${chatId}` }
          ]
        ]
      };

      await sendTelegramMessage(CONFIG.ADMIN_TELEGRAM_ID,
        `🔔 *VERIFIKASI TRANSAKSI & AKTIVASI LISENSI*\n\n` +
        `👤 *Pembeli:* ${userName} (\`${chatId}\`)\n` +
        `📦 *Produk:* ${prod.name} (${prod.formattedPrice})\n` +
        `🖥️ *HWID Perangkat:* \`${hwid}\`\n` +
        `👥 *Seller Tier 1:* \`${pendingSeller}\` (Komisi 30%: Rp ${comm1.toLocaleString('id-ID')})\n` +
        `👥 *Sponsor Tier 2:* (Komisi 5%: Rp ${comm2.toLocaleString('id-ID')})\n\n` +
        `Periksa bukti transfer di atas sebelum klik tombol di bawah.`,
        approvalKeyboard
      );

      await sendTelegramMessage(chatId,
        `⏳ HWID \`${hwid}\` diterima. Admin sedang memverifikasi pembayaran Anda.\n` +
        `License Key resmi akan dikirim otomatis ke chat ini setelah diverifikasi.`
      );
      return;
    }

    // Default Fallback
    await sendTelegramMessage(chatId, `Halo ${userName}! Silakan pilih menu di bawah:`, MAIN_KEYBOARD);
  }
}

// ============================================================================
// 5. LOGIKA APPROVAL & KOMISI 2-TIER (TIER 1 = 30%, TIER 2 = 5%)
// ============================================================================
async function processOrderApproval(env, buyerId, productKey, sellerId, hwid) {
  const prod = PRODUCTS[productKey] || PRODUCTS['reddit_pro'];
  const t1Amount = Math.round(prod.price * CONFIG.TIER1_RATE); // 30%
  const t2Amount = Math.round(prod.price * CONFIG.TIER2_RATE); // 5%

  // A. Generate Lisensi Baru Terikat HWID
  const randomCode = Math.random().toString(36).substring(2, 6).toUpperCase() + '-' + Math.random().toString(36).substring(2, 6).toUpperCase();
  const licenseKey = `${prod.prefix}-${randomCode}`;

  let sponsorTier2Id = null;

  if (env.DB) {
    // 1. Simpan lisensi baru dengan status ACTIVE terikat HWID
    await env.DB.prepare(
      'INSERT INTO licenses (license_key, product_name, hwid, status, activated_at) VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)'
    ).bind(licenseKey, prod.name, hwid, 'ACTIVE').run();

    // 2. Jika ada penjual langsung (Tier 1)
    if (sellerId && sellerId !== 'direct') {
      // Tambah saldo tier 1
      await env.DB.prepare(
        'UPDATE users SET balance_direct = balance_direct + ? WHERE telegram_id = ?'
      ).bind(t1Amount, sellerId).run();

      // Cek apakah seller punya sponsor upline (Tier 2)
      const seller = await env.DB.prepare('SELECT referrer_id, balance_direct FROM users WHERE telegram_id = ?').bind(sellerId).first();

      if (seller && seller.referrer_id && seller.referrer_id !== sellerId) {
        sponsorTier2Id = seller.referrer_id;
        // Tambah saldo komisi pasif tim Tier 2
        await env.DB.prepare(
          'UPDATE users SET balance_team = balance_team + ? WHERE telegram_id = ?'
        ).bind(t2Amount, sponsorTier2Id).run();
      }

      // 3. Catat transaksi selesai
      await env.DB.prepare(
        'INSERT INTO transactions (buyer_telegram_id, product_name, amount, tier1_seller_id, tier1_commission, tier2_seller_id, tier2_commission, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
      ).bind(buyerId, prod.name, prod.price, sellerId, t1Amount, sponsorTier2Id || 'none', sponsorTier2Id ? t2Amount : 0, 'PAID').run();
    }
  }

  // B. Notifikasi ke Pembeli Berisi License Key
  await sendTelegramMessage(buyerId,
    `🎉 *PEMBAYARAN DISETUJUI & LISENSI RESMI AKTIF!*\n\n` +
    `📦 *Produk:* ${prod.name}\n` +
    `🔑 *License Key:* \`${licenseKey}\`\n` +
    `🖥️ *HWID Terdaftar:* \`${hwid}\`\n\n` +
    `📌 *Panduan Aktivasi:*\n` +
    `1. Buka software di perangkat Anda.\n` +
    `2. Masukkan License Key di atas lalu klik Aktivasi.\n` +
    `3. 1 Lisensi terikat 1 Perangkat Fisik (HWID Lock).\n\n` +
    `🤝 Mau dapat penghasilan tambahan? Bagikan link bot ini di menu *[🔗 Link Afiliasi Saya]*!`
  );

  // C. Notifikasi Instan Tier 1 Seller (30%)
  if (sellerId && sellerId !== 'direct') {
    await sendTelegramMessage(sellerId,
      `🔥 *KOMISI PENJUALAN MASUK (TIER 1 - 30%)!*\n\n` +
      `Selamat! Pembelian software *${prod.name}* dari link Anda telah lunas.\n` +
      `💰 *Komisi Anda:* *+Rp ${t1Amount.toLocaleString('id-ID')}*\n\n` +
      `Ketik /saldo untuk melihat rincian dompet Anda. Terus gas promosi!`
    );
  }

  // D. Notifikasi Instan Tier 2 Sponsor (5%)
  if (sponsorTier2Id) {
    await sendTelegramMessage(sponsorTier2Id,
      `🚀 *KOMISI PASIF TIM MASUK (TIER 2 - 5%)!*\n\n` +
      `Keren! Mitra tim Anda (\`${sellerId}\`) berhasil menjual 1 lisensi *${prod.name}*!\n` +
      `💰 *Bonus Pasif Tim:* *+Rp ${t2Amount.toLocaleString('id-ID')}*\n\n` +
      `Inilah kekuatan 2-tier passive income! Ajak lebih banyak mitra untuk cuan harian otomatis!`
    );
  }

  // E. Konfirmasi ke Admin
  await sendTelegramMessage(CONFIG.ADMIN_TELEGRAM_ID,
    `✅ *Aktivasi Sukses & Komisi Selesai Didistribusikan!*\n\n` +
    `📦 Produk: *${prod.name}*\n` +
    `🔑 Key: \`${licenseKey}\`\n` +
    `🖥️ HWID: \`${hwid}\`\n` +
    `👤 Pembeli: \`${buyerId}\`\n` +
    `🥇 Tier 1 (\`${sellerId}\`): Rp ${t1Amount.toLocaleString('id-ID')}\n` +
    `🥈 Tier 2 (\`${sponsorTier2Id || 'none'}\`): Rp ${(sponsorTier2Id ? t2Amount : 0).toLocaleString('id-ID')}`
  );
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================
async function ensureUserExists(db, telegramId) {
  try {
    await db.prepare(
      'INSERT OR IGNORE INTO users (telegram_id, balance_direct, balance_team, balance_ads, ads_watched_today) VALUES (?, 0, 0, 0, 0)'
    ).bind(telegramId).run();
  } catch (e) {}
}

async function sendTelegramMessage(chatId, text, replyMarkup = null) {
  const body = {
    chat_id: chatId,
    text,
    parse_mode: 'Markdown'
  };
  if (replyMarkup) body.reply_markup = replyMarkup;

  return fetch(`https://api.telegram.org/bot${CONFIG.BOT_TOKEN}/sendMessage`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
  });
}

async function sendTelegramPhoto(chatId, photoUrl, caption, replyMarkup = null) {
  const body = {
    chat_id: chatId,
    photo: photoUrl,
    caption,
    parse_mode: 'Markdown'
  };
  if (replyMarkup) body.reply_markup = replyMarkup;

  return fetch(`https://api.telegram.org/bot${CONFIG.BOT_TOKEN}/sendPhoto`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
  });
}

function generateQrisCaption(productName, priceFormatted, refCode) {
  const affText = (refCode && refCode !== 'direct') ? `\n• *Kode Referral:* \`${refCode}\`` : '';
  return (
    `🛒 *Pesanan: ${productName} (${priceFormatted})*${affText}\n\n` +
    `💳 *PEMBAYARAN VIA QRIS NASIONAL (ALL E-WALLET & BANK)*\n` +
    `🏢 *Merchant:* Cuan Digital\n` +
    `📋 *NMID:* ID1026544552890\n\n` +
    `📌 *Langkah Mudah Pembayaran:*\n` +
    `1. Scan kode QRIS di atas memakai Mobile Banking atau E-Wallet (DANA, GoPay, OVO, ShopeePay).\n` +
    `2. Masukkan nominal pas sesuai paket (${priceFormatted}).\n` +
    `3. Selesai transfer, kirimkan *Foto Bukti Struk & Kode HWID* perangkat Anda ke chat ini.`
  );
}

function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' }
  });
}

function renderActivationPageHtml(refCode) {
  return `<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Aktivasi Lisensi - AppDock Hub</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700&display=swap');
        body { font-family: 'Plus Jakarta Sans', sans-serif; background-color: #080c14; }
        .glass-card {
            background: rgba(15, 23, 42, 0.75);
            backdrop-filter: blur(20px);
            border: 1px solid rgba(255, 255, 255, 0.08);
        }
    </style>
</head>
<body class="flex items-center justify-center min-h-screen p-4 text-white">
    <div class="glass-card w-full max-w-md p-8 rounded-3xl shadow-2xl text-center relative overflow-hidden">
        <div class="absolute -top-12 -right-12 w-32 h-32 bg-orange-500/10 rounded-full blur-2xl"></div>
        <div class="absolute -bottom-12 -left-12 w-32 h-32 bg-indigo-500/10 rounded-full blur-2xl"></div>

        <div class="mb-6 relative">
            <div class="w-20 h-20 bg-gradient-to-tr from-orange-600 to-amber-500 rounded-2xl flex items-center justify-center mx-auto text-white shadow-xl shadow-orange-500/20">
                <i class="fas fa-shield-alt text-3xl"></i>
            </div>
        </div>

        <h1 class="text-2xl font-bold tracking-tight text-white mb-1">AppDock Hub</h1>
        <p class="text-xs text-orange-400 font-semibold tracking-wider uppercase mb-2">License & Hardware Binding Portal</p>
        <p class="text-gray-400 text-xs mb-6">Masukkan Hardware ID (HWID) dan Kunci Lisensi Anda untuk mengaktifkan software.</p>

        <div class="space-y-4">
            <div class="text-left">
                <label class="text-[11px] text-gray-400 font-medium ml-1 mb-1 block">Hardware ID (HWID)</label>
                <div class="relative">
                    <i class="fas fa-desktop absolute left-4 top-1/2 -translate-y-1/2 text-gray-500 text-sm"></i>
                    <input type="text" id="hwidInput" placeholder="RD-HWID-XXXX-XXXX" 
                        class="w-full pl-11 pr-4 py-3 bg-slate-900/90 border border-slate-700/80 rounded-xl text-white font-mono text-xs placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-orange-500 transition">
                </div>
            </div>

            <div class="text-left">
                <label class="text-[11px] text-gray-400 font-medium ml-1 mb-1 block">License Key</label>
                <div class="relative">
                    <i class="fas fa-key absolute left-4 top-1/2 -translate-y-1/2 text-gray-500 text-sm"></i>
                    <input type="text" id="licenseKey" placeholder="RD-PRO-XXXX-XXXX" 
                        class="w-full pl-11 pr-4 py-3 bg-slate-900/90 border border-slate-700/80 rounded-xl text-white font-mono text-xs placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-orange-500 transition">
                </div>
            </div>

            <button onclick="activateLicense()" id="btnActivate" 
                class="w-full py-3.5 bg-gradient-to-r from-orange-600 to-amber-600 hover:from-orange-500 hover:to-amber-500 text-white font-semibold rounded-xl transition shadow-lg shadow-orange-600/30 flex items-center justify-center gap-2 mt-2">
                <span>Aktivasi Sekarang</span>
                <i class="fas fa-arrow-right text-xs"></i>
            </button>

            <div class="pt-3">
                <a href="https://t.me/${CONFIG.BOT_USERNAME}?start=buy_reddit_pro_ref_${refCode}" target="_blank" 
                   class="text-xs text-orange-400 hover:text-orange-300 transition underline inline-flex items-center gap-1.5">
                    <i class="fab fa-telegram"></i>
                    <span>Belum punya lisensi? Beli via Bot Telegram</span>
                </a>
            </div>
        </div>

        <div class="mt-8 pt-4 border-t border-slate-800/80 flex justify-between items-center text-[10px] text-gray-500">
            <span>Hardware Security Protocol</span>
            <span class="font-mono text-amber-500/80">1 Device = 1 License</span>
        </div>
    </div>

    <script>
        async function activateLicense() {
            const hwid = document.getElementById('hwidInput').value.trim();
            const key = document.getElementById('licenseKey').value.trim();
            const btn = document.getElementById('btnActivate');

            if (!hwid || !key) {
                alert('Silakan masukkan Kode HWID dan License Key!');
                return;
            }

            btn.disabled = true;
            btn.innerHTML = '<i class="fas fa-spinner fa-spin text-sm"></i> Memverifikasi...';

            try {
                const res = await fetch(window.location.origin + '/activate', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ hwid, licenseKey: key })
                });
                const data = await res.json();

                if (data.status === 'success') {
                    alert('✅ Aktivasi Berhasil! ' + (data.message || ''));
                    window.location.reload();
                } else {
                    alert('❌ Gagal Aktivasi: ' + (data.message || 'Key tidak valid'));
                }
            } catch (err) {
                alert('⚠️ Terjadi kesalahan saat menghubungi server aktivasi.');
            } finally {
                btn.disabled = false;
                btn.innerHTML = '<span>Aktivasi Sekarang</span><i class="fas fa-arrow-right text-xs"></i>';
            }
        }
    </script>
</body>
</html>`;
}
