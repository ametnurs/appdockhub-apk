/**
 * APPDOCKHUB - Cloudflare Worker
 * Multi App Manager + License Manager + Telegram Bot + Affiliate System (30% Commission)
 * Produk Resmi:
 * 1. Reddit Manager Pro (Rp 99.000) [BARU]
 * 2. LinkedIn Manager Pro (Rp 99.000)
 * 3. Pinterest Manager Pro (Rp 99.000)
 * 4. X (Twitter) Manager Pro (Rp 99.000)
 * 5. TikTok Multi-Screen Pro (Rp 99.000)
 * 6. Facebook Account Manager Pro (Rp 99.000)
 * 7. Jualin Aja (Rp 299.000)
 */

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const hostname = url.hostname.toLowerCase();

    // ==========================================================================
    // ⚙️ KONFIGURASI UTAMA
    // ==========================================================================
    const BOT_TOKEN = '8844891986:AAHXnpu00vewiq0mva8Wra7TJbi8nBChCYQ';
    const YOUR_ADMIN_TELEGRAM_ID = '8916556502'; // ID Telegram Admin Anda
    const BOT_USERNAME = 'AppDockHub_Bot';

    // Gambar QRIS Pembayaran Cuan Digital
    const QRIS_IMAGE_URL = 'https://i.ibb.co.com/RkvpWdTm/qris.jpg';

    // Daftar Produk & Komisi Afiliasi (30%)
    const PRODUCTS = {
      'reddit_pro': {
        name: 'Reddit Manager Pro',
        priceNumber: 99000,
        priceFormatted: 'Rp 99.000',
        commissionRate: 0.30,
        type: 'reddit'
      },
      'linkedin_pro': {
        name: 'LinkedIn Manager Pro',
        priceNumber: 99000,
        priceFormatted: 'Rp 99.000',
        commissionRate: 0.30,
        type: 'linkedin'
      },
      'pinterest_pro': {
        name: 'Pinterest Manager Pro',
        priceNumber: 99000,
        priceFormatted: 'Rp 99.000',
        commissionRate: 0.30,
        type: 'pinterest'
      },
      'x_pro': {
        name: 'X (Twitter) Manager Pro',
        priceNumber: 99000,
        priceFormatted: 'Rp 99.000',
        commissionRate: 0.30,
        type: 'x_twitter'
      },
      'tiktok_pro': {
        name: 'TikTok Multi-Screen Pro',
        priceNumber: 99000,
        priceFormatted: 'Rp 99.000',
        commissionRate: 0.30,
        type: 'tiktok'
      },
      'fb_pro': {
        name: 'Facebook Account Manager Pro',
        priceNumber: 99000,
        priceFormatted: 'Rp 99.000',
        commissionRate: 0.30,
        type: 'facebook'
      },
      'soft_a': {
        name: 'Jualin Aja',
        priceNumber: 299000,
        priceFormatted: 'Rp 299.000',
        commissionRate: 0.30,
        type: 'jualin'
      }
    };

    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    };

    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    try {
      // ==========================================================================
      // 🔗 1. ENDPOINT REDIRECT TOMBOL "BELI" (/beli atau /order)
      // ==========================================================================
      if (url.pathname === '/beli' || url.pathname === '/order') {
        const item = url.searchParams.get('item') || (hostname.includes('reddit') ? 'reddit_pro' : (hostname.includes('linkedin') ? 'linkedin_pro' : (hostname.includes('pinterest') ? 'pinterest_pro' : (hostname.includes('fb') ? 'fb_pro' : (hostname.includes('tiktok') ? 'tiktok_pro' : 'soft_a')))));
        const refCookie = getCookie(request, 'aff_ref');
        const refParam = url.searchParams.get('ref') || refCookie || 'direct';

        const actualBotUsername = (env.LICENSE_KV ? await env.LICENSE_KV.get('BOT_USERNAME') : null) || BOT_USERNAME;
        const teleUrl = `https://t.me/${actualBotUsername}?start=buy_${item}_ref_${refParam}`;
        return Response.redirect(teleUrl, 302);
      }

      // ==========================================================================
      // ⚙️ 2. ENDPOINT SET WEBHOOK TELEGRAM OTOMATIS (/set-webhook)
      // ==========================================================================
      if (url.pathname === '/set-webhook') {
        const workerUrl = `https://${url.hostname}/bot-webhook`;
        const tgRes = await fetch(`https://api.telegram.org/bot${BOT_TOKEN}/setWebhook?url=${encodeURIComponent(workerUrl)}&drop_pending_updates=true`);
        const tgData = await tgRes.json();

        // Ambil info bot username
        try {
          const meRes = await fetch(`https://api.telegram.org/bot${BOT_TOKEN}/getMe`);
          const meData = await meRes.json();
          if (meData.ok && meData.result.username && env.LICENSE_KV) {
            await env.LICENSE_KV.put('BOT_USERNAME', meData.result.username);
          }
        } catch (e) {}

        // Daftarkan menu perintah resmi Telegram (Menu Button)
        try {
          await fetch(`https://api.telegram.org/bot${BOT_TOKEN}/setMyCommands`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              commands: [
                { command: 'start', description: 'Mulai & Tampilkan Menu' },
                { command: 'buy', description: 'Beli Software & Lisensi' },
                { command: 'daftar', description: 'Daftar Afiliasi (Komisi 30%)' },
                { command: 'saldo', description: 'Cek Saldo Komisi' },
                { command: 'tarik', description: 'Tarik Saldo Komisi' }
              ]
            })
          });
        } catch (e) {}

        return new Response(JSON.stringify(tgData, null, 2), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });
      }

      // ==========================================================================
      // 🤖 3. TELEGRAM BOT WEBHOOK & HANDLER (/bot-webhook)
      // ==========================================================================
      if (url.pathname === '/bot-webhook') {
        if (request.method !== 'POST') {
          return new Response('Method Not Allowed', { status: 405 });
        }

        let update;
        try {
          update = await request.json();
        } catch (err) {
          return new Response('Invalid JSON', { status: 400 });
        }

        // A. MENANGANI KLIK TOMBOL INLINE (Callback Query)
        if (update.callback_query) {
          const cb = update.callback_query;
          const action = cb.data;
          const chatId = cb.message.chat.id;

          await fetch(`https://api.telegram.org/bot${BOT_TOKEN}/answerCallbackQuery`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ callback_query_id: cb.id })
          });

          // A1. Beli Produk
          if (action.startsWith('buy_')) {
            const parts = action.replace('buy_', '').split('_ref_');
            const softKey = parts[0];
            const refCode = parts[1] || 'direct';

            if (env.LICENSE_KV) {
              await env.LICENSE_KV.put(`user_pending_order:${chatId}`, JSON.stringify({
                productKey: softKey,
                refCode,
                userName: cb.from.first_name || 'User',
                time: new Date().toISOString()
              }), { expirationTtl: 86400 });

              await recordNewLead(env.LICENSE_KV, {
                chatId,
                userName: cb.from.first_name || 'User',
                userTag: cb.from.username || null,
                productKey: softKey,
                refCode,
                time: new Date().toISOString()
              });
            }

            const selected = PRODUCTS[softKey] || { name: 'Reddit Manager Pro', priceFormatted: 'Rp 99.000' };
            const caption = generateQrisCaption(selected.name, selected.priceFormatted, refCode);

            await sendTelegramPhoto(BOT_TOKEN, chatId, QRIS_IMAGE_URL, caption);

            // Notifikasi ke Admin
            const leadKeyboard = {
              inline_keyboard: [
                [{ text: '💬 Follow Up Calon Pembeli', callback_data: `remind_${chatId}_${softKey}` }]
              ]
            };
            await sendTelegram(BOT_TOKEN, YOUR_ADMIN_TELEGRAM_ID,
              `👀 *LEAD BARU MASUK!*\n\n` +
              `👤 *Calon Pembeli:* ${cb.from.first_name || 'User'} (\`${chatId}\`)\n` +
              `📦 *Pilihan:* *${selected.name}* (${selected.priceFormatted})\n` +
              `👥 *Afiliator:* \`${refCode}\`\n` +
              `⏳ *Status:* Menunggu Pembayaran QRIS\n\n` +
              `Klik tombol di bawah untuk kirim follow up ke pembeli ini.`,
              { parse_mode: 'Markdown', reply_markup: leadKeyboard }
            );
          }

          // A2. Admin Follow Up
          else if (action.startsWith('remind_')) {
            const parts = action.split('_');
            const targetChatId = parts[1];
            const softKey = parts[2];
            const product = PRODUCTS[softKey] || { name: 'Software', priceFormatted: 'Harga Promo' };

            await sendTelegram(BOT_TOKEN, targetChatId,
              `Halo kak! 👋\n\n` +
              `Pesanan *${product.name} (${product.priceFormatted})* Anda masih tersimpan di sistem kami.\n\n` +
              `Apakah ada kendala saat scan QRIS atau transfer pembayaran? Butuh bantuan aktivasi? Silakan balas chat ini ya kak! 🙏`,
              { parse_mode: 'Markdown' }
            );

            await sendTelegram(BOT_TOKEN, YOUR_ADMIN_TELEGRAM_ID,
              `✅ *Follow Up Terkirim!*\nPesan pengingat dikirim ke pembeli (\`${targetChatId}\`).`,
              { parse_mode: 'Markdown' }
            );
          }

          // A3. Tips Afiliasi
          else if (action.startsWith('aff_tips_')) {
            const myCode = action.replace('aff_tips_', '');
            await sendTelegram(BOT_TOKEN, chatId,
              `📱 *TIPS PROMOSI AFILIASI (KOMISI 30%)*\n\n` +
              `1️⃣ *Media Sosial:*\n` +
              `• Rekam video Multi-Screen Live View saat kelola 4-12 akun Reddit atau posting massal.\n` +
              `• Pasang link bot Telegram di bio media sosial Anda.\n\n` +
              `2️⃣ *WhatsApp & Forum:*\n` +
              `• Bagikan ke komunitas affiliate marketing, dropshipper, SEO, dan kreator konten global.\n` +
              `• Komisi Anda: *Rp 29.700* per lisensi software yang terjual!`,
              { parse_mode: 'Markdown' }
            );
          }

          // A4. Admin Approve Pembelian
          else if (action.startsWith('approve_') || action.startsWith('approve:')) {
            let buyerId, softKey, refCode, hwid;
            if (action.includes(':')) {
              const parts = action.split(':');
              buyerId = parts[1];
              softKey = parts[2];
              refCode = parts[3];
              hwid = parts.slice(4).join(':');
            } else {
              const parts = action.split('_');
              buyerId = parts[1];
              if (parts[2] === 'reddit' && parts[3] === 'pro') {
                softKey = 'reddit_pro';
                refCode = parts[4];
                hwid = parts.slice(5).join('_');
              } else if (parts[2] === 'linkedin' && parts[3] === 'pro') {
                softKey = 'linkedin_pro';
                refCode = parts[4];
                hwid = parts.slice(5).join('_');
              } else if (parts[2] === 'pinterest' && parts[3] === 'pro') {
                softKey = 'pinterest_pro';
                refCode = parts[4];
                hwid = parts.slice(5).join('_');
              } else if (parts[2] === 'tiktok' && parts[3] === 'pro') {
                softKey = 'tiktok_pro';
                refCode = parts[4];
                hwid = parts.slice(5).join('_');
              } else if (parts[2] === 'x' && parts[3] === 'pro') {
                softKey = 'x_pro';
                refCode = parts[4];
                hwid = parts.slice(5).join('_');
              } else if (parts[2] === 'fb' && parts[3] === 'pro') {
                softKey = 'fb_pro';
                refCode = parts[4];
                hwid = parts.slice(5).join('_');
              } else if (parts[2] === 'soft' && parts[3] === 'a') {
                softKey = 'soft_a';
                refCode = parts[4];
                hwid = parts.slice(5).join('_');
              } else {
                softKey = parts[2];
                refCode = parts[3];
                hwid = parts.slice(4).join('_');
              }
            }
            if (hwid && hwid.startsWith('direct_')) {
              hwid = hwid.replace(/^direct_/, '');
            }

            const product = PRODUCTS[softKey] || { name: 'Reddit Manager Pro', priceNumber: 99000, commissionRate: 0.30 };

            // Generate License Key berdasarkan tipe produk
            let licenseKey = '';
            if (hwid.startsWith('RD') || hwid.startsWith('REDDIT') || softKey === 'reddit_pro') {
              licenseKey = 'RD-PRO-' + Math.random().toString(36).substring(2, 6).toUpperCase() + '-' + Math.random().toString(36).substring(2, 6).toUpperCase();
            } else if (hwid.startsWith('IN') || hwid.startsWith('LINKEDIN') || softKey === 'linkedin_pro') {
              licenseKey = 'IN-PRO-' + Math.random().toString(36).substring(2, 6).toUpperCase() + '-' + Math.random().toString(36).substring(2, 6).toUpperCase();
            } else if (hwid.startsWith('PIN') || softKey === 'pinterest_pro') {
              licenseKey = 'PIN-PRO-' + Math.random().toString(36).substring(2, 6).toUpperCase() + '-' + Math.random().toString(36).substring(2, 6).toUpperCase();
            } else if (hwid.startsWith('X') || softKey === 'x_pro') {
              licenseKey = 'X-PRO-' + Math.random().toString(36).substring(2, 6).toUpperCase() + '-' + Math.random().toString(36).substring(2, 6).toUpperCase();
            } else if (hwid.startsWith('FB') || softKey === 'fb_pro') {
              licenseKey = 'FB-PRO-' + Math.random().toString(36).substring(2, 6).toUpperCase() + '-' + Math.random().toString(36).substring(2, 6).toUpperCase();
            } else if (hwid.startsWith('TIKTOK') || hwid.startsWith('HWID')) {
              licenseKey = 'TIKTOK-PRO-' + Math.random().toString(36).substring(2, 6).toUpperCase() + '-' + Math.random().toString(36).substring(2, 6).toUpperCase();
            } else {
              licenseKey = 'LIC-' + Math.random().toString(36).substring(2, 6).toUpperCase() + '-' + Math.random().toString(36).substring(2, 6).toUpperCase();
            }

            // Simpan ke KV
            if (env.LICENSE_KV) {
              await env.LICENSE_KV.put(hwid, JSON.stringify({
                hwid,
                licenseKey,
                product: product.name,
                status: 'active',
                buyerId,
                refCode,
                createdAt: new Date().toISOString()
              }));

              // Hapus dari pending leads
              try {
                const rawLeads = await env.LICENSE_KV.get('recent_leads');
                if (rawLeads) {
                  let list = JSON.parse(rawLeads);
                  list = list.filter(item => String(item.chatId) !== String(buyerId));
                  await env.LICENSE_KV.put('recent_leads', JSON.stringify(list), { expirationTtl: 86400 * 7 });
                }
              } catch (e) {}
            }

            // Catat Komisi Afiliasi (30%)
            let commissionMsg = 'Tanpa afiliasi (direct)';
            if (refCode && refCode !== 'direct' && env.LICENSE_KV) {
              const commissionAmount = Math.round(product.priceNumber * product.commissionRate);
              const affiliateKey = `affiliate:${refCode.toLowerCase()}`;
              const currentDataRaw = await env.LICENSE_KV.get(affiliateKey);

              let affData = currentDataRaw ? JSON.parse(currentDataRaw) : {
                refCode: refCode.toLowerCase(),
                balance: 0,
                totalSales: 0,
                totalCommission: 0,
                telegramId: null
              };

              affData.balance += commissionAmount;
              affData.totalSales += 1;
              affData.totalCommission += commissionAmount;
              await env.LICENSE_KV.put(affiliateKey, JSON.stringify(affData));

              commissionMsg = `Afiliator *${refCode}* dapat komisi (Rp ${commissionAmount.toLocaleString('id-ID')}). Saldo: Rp ${affData.balance.toLocaleString('id-ID')}`;

              if (affData.telegramId) {
                await sendTelegram(BOT_TOKEN, affData.telegramId,
                  `🎉 *KOMISI MASUK (30%)!*\n\n` +
                  `Pesanan dari link Anda disetujui:\n` +
                  `📦 *Produk:* ${product.name}\n` +
                  `💰 *Komisi Anda:* Rp ${commissionAmount.toLocaleString('id-ID')}\n` +
                  `💵 *Total Saldo:* Rp ${affData.balance.toLocaleString('id-ID')}\n\n` +
                  `Ketik /saldo untuk cek detail atau /tarik untuk request pencairan.`,
                  { parse_mode: 'Markdown' }
                );
              }
            }

            // Kirim Lisensi ke Pembeli
            await sendTelegram(BOT_TOKEN, buyerId,
              `✅ *PEMBAYARAN DISETUJUI & LISENSI AKTIF!*\n\n` +
              `🔑 *License Key:* \`${licenseKey}\`\n` +
              `🖥️ *HWID Terdaftar:* \`${hwid}\`\n\n` +
              `📌 *Catatan:* 1 Lisensi = 1 Perangkat Fisik (Laptop/PC).\n` +
              `Silakan buka software di laptop Anda, masukkan key di atas pada form aktivasi, dan klik **Aktivasi Sekarang**!\n\n` +
              `🤝 *Dapatkan Komisi 30%:* Klik menu **[🤝 Link Afiliasi Saya]** untuk mulai hasilkan pasif income!`,
              { parse_mode: 'Markdown' }
            );

            // Konfirmasi ke Admin
            await sendTelegram(BOT_TOKEN, YOUR_ADMIN_TELEGRAM_ID,
              `✅ *Aktivasi Sukses!*\n` +
              `📦 Produk: *${product.name}*\n` +
              `👤 Pembeli: \`${buyerId}\`\n` +
              `🔑 Key: \`${licenseKey}\`\n` +
              `🖥️ HWID: \`${hwid}\`\n` +
              `💰 ${commissionMsg}`,
              { parse_mode: 'Markdown' }
            );
          }

          // A5. Admin Reject
          else if (action.startsWith('reject_')) {
            const targetChatId = action.replace('reject_', '');
            await sendTelegram(BOT_TOKEN, targetChatId, '❌ Maaf, bukti pembayaran Anda belum dapat diverifikasi atau ditolak oleh Admin. Silakan periksa kembali nominal atau hubungi Admin.');
            await sendTelegram(BOT_TOKEN, YOUR_ADMIN_TELEGRAM_ID, '⚠️ Pesanan telah ditolak.');
          }

          return new Response('OK');
        }

        // B. MENANGANI PESAN TEKS & FOTO DARI USER
        if (update.message) {
          const msg = update.message;
          const chatId = msg.chat.id;
          const rawText = (msg.text || '').trim();
          const lowerText = rawText.toLowerCase();
          const words = rawText.split(/\s+/);
          const firstWord = (words[0] || '').toLowerCase();
          const userName = (msg.from && msg.from.first_name) ? msg.from.first_name : 'User';
          const photo = msg.photo;

          // B1. /start BIASA / MENU
          if (lowerText === '/start' || lowerText === 'start' || lowerText === 'halo' || lowerText === 'hi' || lowerText === 'menu') {
            await sendTelegram(BOT_TOKEN, chatId,
              `Halo ${userName}! 👋\n\nSelamat datang di *AppDockHub Official Store*.\n\n` +
              `🚀 *Pusat Software Otomatisasi & Bisnis Digital*\n\n` +
              `🔥 *1. Reddit Manager Pro (Rp 99.000)* [BEST SELLER]\n` +
              `• Multi-Screen Live View Grid 1-12 Layar Akun Reddit Chrome Tertanam\n` +
              `• Post Composer Spintax, Auto CDP Headless Publisher & Subreddit Manager\n` +
              `• AI Creator Studio, Cookie Sync & Unlimited Multi-Account Manager\n\n` +
              `💼 *2. LinkedIn Manager Pro (Rp 99.000)*\n` +
              `• Multi-Screen Live View Grid 1-12 Layar Akun LinkedIn\n` +
              `• Post Composer B2B, AI Copywriting, Spintax & Auto Publisher\n\n` +
              `📌 *3. Pinterest Manager Pro (Rp 99.000)*\n` +
              `• Multi-Screen Live View Grid 1-12 Layar Akun Pinterest\n` +
              `• Pin Composer SEO, Auto Graphic Card 1000x1500, Auto Board Creator\n\n` +
              `🐦 *4. X (Twitter) Manager Pro (Rp 99.000)*\n` +
              `• Multi-Screen Live View 1-12 Layar Akun X\n` +
              `• Auto Tweet, Retweet, Like, DM Massal & AI Copywriting\n\n` +
              `📱 *5. TikTok Multi-Screen Pro (Rp 99.000)*\n` +
              `• Live Streaming Video Sendiri Auto-Looping 24 Jam Tanpa OBS\n\n` +
              `🔵 *6. Facebook Account Manager Pro (Rp 99.000)*\n` +
              `• Multi-Screen Live View Grid 12 Layar Akun Facebook\n\n` +
              `🛒 *7. Jualin Aja (Rp 299.000)*\n` +
              `• Software Riset Produk & Penjualan Toko Online\n\n` +
              `💰 *Komisi Kemitraan Afiliasi 30%* untuk setiap penjualan!\n` +
              `Gunakan menu tombol di bawah untuk memilih opsi:`,
              { parse_mode: 'Markdown' }
            );
            return new Response('OK');
          }

          // B2. MENU BELI SOFTWARE
          if (lowerText.includes('beli software') || lowerText === '/buy' || lowerText === 'buy' || lowerText === '/beli' || lowerText === 'beli') {
            const savedRef = (env.LICENSE_KV ? await env.LICENSE_KV.get(`user_ref:${chatId}`) : null) || 'direct';
            const keyboard = {
              inline_keyboard: [
                [{ text: '🔥 Reddit Manager Pro (Rp 99.000)', callback_data: `buy_reddit_pro_ref_${savedRef}` }],
                [{ text: '💼 LinkedIn Manager Pro (Rp 99.000)', callback_data: `buy_linkedin_pro_ref_${savedRef}` }],
                [{ text: '📌 Pinterest Manager Pro (Rp 99.000)', callback_data: `buy_pinterest_pro_ref_${savedRef}` }],
                [{ text: '🐦 X (Twitter) Manager Pro (Rp 99.000)', callback_data: `buy_x_pro_ref_${savedRef}` }],
                [{ text: '📱 TikTok Multi-Screen Pro (Rp 99.000)', callback_data: `buy_tiktok_pro_ref_${savedRef}` }],
                [{ text: '🔵 Facebook Account Manager Pro (Rp 99.000)', callback_data: `buy_fb_pro_ref_${savedRef}` }],
                [{ text: '🚀 Jualin Aja (Rp 299.000)', callback_data: `buy_soft_a_ref_${savedRef}` }]
              ]
            };
            await sendTelegram(BOT_TOKEN, chatId, '📦 *Katalog Software Resmi:*\nSilakan klik software yang ingin Anda beli:', { parse_mode: 'Markdown', reply_markup: keyboard });
            return new Response('OK');
          }

          // B3. MENU DAFTAR AFILIASI
          const isAffiliateMenuClick = lowerText.includes('link afiliasi') || lowerText.includes('daftar afiliasi');
          const isDaftarCmd = ['/daftar', 'daftar', '/affiliate', 'affiliate', '/afiliasi', 'afiliasi'].includes(firstWord);

          if (isAffiliateMenuClick || isDaftarCmd) {
            let myCodeInput = isDaftarCmd ? words.slice(1).join('').trim() : '';
            let myCode = myCodeInput.toLowerCase().replace(/[^a-z0-9_-]/g, '');

            if (!myCode && env.LICENSE_KV) {
              const existingCode = await env.LICENSE_KV.get(`tg_to_aff:${chatId}`);
              if (existingCode) myCode = existingCode;
            }

            if (myCode && myCode.length >= 3) {
              if (env.LICENSE_KV) {
                const affKey = `affiliate:${myCode}`;
                const existing = await env.LICENSE_KV.get(affKey);
                let data = existing ? JSON.parse(existing) : {
                  refCode: myCode,
                  balance: 0,
                  totalSales: 0,
                  totalCommission: 0,
                  telegramId: chatId
                };
                data.telegramId = chatId;
                await env.LICENSE_KV.put(affKey, JSON.stringify(data));
                await env.LICENSE_KV.put(`tg_to_aff:${chatId}`, myCode);
              }

              const affKeyboard = {
                inline_keyboard: [
                  [{ text: '📱 Panduan & Tips Promosi', callback_data: `aff_tips_${myCode}` }],
                  [{ text: '💳 Cek Saldo Komisi', callback_data: `check_balance_${myCode}` }]
                ]
              };

              const botUser = (env.LICENSE_KV ? await env.LICENSE_KV.get('BOT_USERNAME') : null) || BOT_USERNAME;
              await sendTelegram(BOT_TOKEN, chatId,
                `🎉 *LINK AFILIASI ANDA AKTIF!*\n\n` +
                `Kode Afiliasi: \`${myCode}\`\n\n` +
                `🔗 *Link Bot Reddit Manager Langsung:*\n` +
                `\`https://t.me/${botUser}?start=buy_reddit_pro_ref_${myCode}\`\n\n` +
                `💰 *Komisi Anda: 30% per penjualan* (Rp 29.700 per lisensi)!`,
                { parse_mode: 'Markdown', reply_markup: affKeyboard }
              );
              return new Response('OK');
            } else {
              await sendTelegram(BOT_TOKEN, chatId,
                `🤝 *PROGRAM KEMITRAAN AFILIASI (KOMISI 30%)*\n\n` +
                `Daftar instan dalam 5 detik! Ketik:\n` +
                `\`daftar <nama_pilihan_anda>\`\n\n` +
                `Contoh:\n` +
                `\`daftar cuanonline\`\n` +
                `\`daftar berkahshop\``,
                { parse_mode: 'Markdown' }
              );
              return new Response('OK');
            }
          }

          // B4. CEK SALDO KOMISI
          if (lowerText.includes('cek saldo') || lowerText === '/saldo' || lowerText === 'saldo') {
            if (!env.LICENSE_KV) {
              await sendTelegram(BOT_TOKEN, chatId, 'Database KV belum aktif.');
              return new Response('OK');
            }
            const myCode = await env.LICENSE_KV.get(`tg_to_aff:${chatId}`);
            if (!myCode) {
              await sendTelegram(BOT_TOKEN, chatId, 'Anda belum mendaftar afiliasi. Ketik `daftar <nama>` untuk mulai!');
              return new Response('OK');
            }
            const raw = await env.LICENSE_KV.get(`affiliate:${myCode}`);
            const data = raw ? JSON.parse(raw) : { balance: 0, totalSales: 0, totalCommission: 0 };

            await sendTelegram(BOT_TOKEN, chatId,
              `💳 *DETAIL SALDO KOMISI ANDA*\n\n` +
              `👤 Afiliator: \`${myCode}\`\n` +
              `💵 Saldo Siap Tarik: *Rp ${data.balance.toLocaleString('id-ID')}*\n` +
              `📊 Total Penjualan: *${data.totalSales} lisensi*\n` +
              `💰 Total Komisi Didapat: *Rp ${data.totalCommission.toLocaleString('id-ID')}*\n\n` +
              `Minimal penarikan saldo adalah Rp 50.000. Ketik /tarik untuk mencairkan saldo.`,
              { parse_mode: 'Markdown' }
            );
            return new Response('OK');
          }

          // B5. TARIK SALDO KOMISI
          if (lowerText.includes('tarik saldo') || lowerText === '/tarik' || lowerText === 'tarik') {
            if (!env.LICENSE_KV) return new Response('OK');
            const myCode = await env.LICENSE_KV.get(`tg_to_aff:${chatId}`);
            if (!myCode) {
              await sendTelegram(BOT_TOKEN, chatId, 'Anda belum mendaftar afiliasi. Ketik `daftar <nama>` terlebih dahulu.');
              return new Response('OK');
            }
            const raw = await env.LICENSE_KV.get(`affiliate:${myCode}`);
            const data = raw ? JSON.parse(raw) : { balance: 0 };
            if (data.balance < 50000) {
              await sendTelegram(BOT_TOKEN, chatId, `⚠️ Saldo Anda saat ini *Rp ${data.balance.toLocaleString('id-ID')}*.\nMinimal pencairan saldo adalah Rp 50.000.`);
              return new Response('OK');
            }
            await sendTelegram(BOT_TOKEN, chatId,
              `💵 *PENCAIRAN SALDO KOMISI*\n\n` +
              `Saldo Anda: *Rp ${data.balance.toLocaleString('id-ID')}*\n\n` +
              `Silakan balas chat ini dengan format:\n` +
              `\`tarik <jumlah> <Nama Bank/E-Wallet> <Nomor Rekening> <Nama Pemilik>\`\n\n` +
              `Contoh:\n` +
              `\`tarik ${data.balance} BCA 1234567890 Budi Santoso\`\n` +
              `\`tarik ${data.balance} DANA 08123456789 Budi Santoso\``,
              { parse_mode: 'Markdown' }
            );
            return new Response('OK');
          }

          // B6. EKSEKUSI PENARIKAN SALDO
          if (firstWord === 'tarik' && words.length >= 5) {
            const amount = parseInt(words[1]);
            const bank = words[2];
            const accNo = words[3];
            const accName = words.slice(4).join(' ');

            if (isNaN(amount) || amount < 50000) {
              await sendTelegram(BOT_TOKEN, chatId, '⚠️ Jumlah penarikan minimal Rp 50.000!');
              return new Response('OK');
            }

            const myCode = env.LICENSE_KV ? await env.LICENSE_KV.get(`tg_to_aff:${chatId}`) : null;
            if (myCode && env.LICENSE_KV) {
              const affKey = `affiliate:${myCode}`;
              const raw = await env.LICENSE_KV.get(affKey);
              if (raw) {
                let data = JSON.parse(raw);
                if (data.balance >= amount) {
                  data.balance -= amount;
                  await env.LICENSE_KV.put(affKey, JSON.stringify(data));
                } else {
                  await sendTelegram(BOT_TOKEN, chatId, '⚠️ Saldo tidak mencukupi untuk penarikan ini.');
                  return new Response('OK');
                }
              }
            }

            await sendTelegram(BOT_TOKEN, YOUR_ADMIN_TELEGRAM_ID,
              `📢 *REQUEST PENARIKAN SALDO AFILIASI!*\n\n` +
              `👤 Afiliator: \`${myCode || userName}\` (\`${chatId}\`)\n` +
              `💰 Jumlah: *Rp ${amount.toLocaleString('id-ID')}*\n` +
              `🏦 Bank/E-Wallet: *${bank}*\n` +
              `🔢 No. Rekening: \`${accNo}\`\n` +
              `📝 Atas Nama: *${accName}*\n\n` +
              `Silakan lakukan transfer ke rekening di atas.`,
              { parse_mode: 'Markdown' }
            );

            await sendTelegram(BOT_TOKEN, chatId,
              `✅ Permintaan penarikan Rp ${amount.toLocaleString('id-ID')} telah dikirim ke Admin.\n` +
              `Dana akan ditransfer dalam waktu 1x24 jam kerja.`
            );
            return new Response('OK');
          }

          // B7. MENERIMA BUKTI PEMBAYARAN ATAU HWID
          const isHwidFormat = lowerText.startsWith('rd-hwid-') || lowerText.startsWith('rd-') || lowerText.startsWith('reddit-') || lowerText.startsWith('in-hwid-') || lowerText.startsWith('in-') || lowerText.startsWith('linkedin-') || lowerText.startsWith('pin-hwid-') || lowerText.startsWith('pin-') || lowerText.startsWith('x-hwid-') || lowerText.startsWith('x-') || lowerText.startsWith('hwid-') || lowerText.startsWith('tiktok-hwid-') || lowerText.startsWith('fb-hwid-') || lowerText.startsWith('fb-') || lowerText.startsWith('lic-');
          if (photo || isHwidFormat) {
            const hwid = rawText || 'Pemeriksaan manual';
            let orderInfo = { productKey: 'reddit_pro', refCode: 'direct' };

            if (env.LICENSE_KV) {
              const pendingRaw = await env.LICENSE_KV.get(`user_pending_order:${chatId}`);
              if (pendingRaw) {
                orderInfo = JSON.parse(pendingRaw);
              } else {
                const savedRef = await env.LICENSE_KV.get(`user_ref:${chatId}`);
                if (savedRef) orderInfo.refCode = savedRef;
              }
            }

            if (photo && !rawText) {
              await sendTelegram(BOT_TOKEN, chatId, '📸 Bukti pembayaran diterima! Selanjutnya, kirimkan **Kode HWID** aplikasi Anda (contoh: `RD-HWID-...`).', { parse_mode: 'Markdown' });
              return new Response('OK');
            }

            const product = PRODUCTS[orderInfo.productKey] || { name: 'Reddit Manager Pro', priceFormatted: 'Rp 99.000', priceNumber: 99000 };
            const estCommission = Math.round(product.priceNumber * 0.30);

            const adminKeyboard = {
              inline_keyboard: [
                [
                  { text: '✅ Approve & Beri Komisi 30%', callback_data: `approve:${chatId}:${orderInfo.productKey}:${orderInfo.refCode}:${hwid}` },
                  { text: '❌ Tolak', callback_data: `reject_${chatId}` }
                ]
              ]
            };

            await sendTelegram(BOT_TOKEN, YOUR_ADMIN_TELEGRAM_ID,
              `🔔 *Permintaan Pembelian & Aktivasi Baru!*\n\n` +
              `👤 *User:* ${userName} (\`${chatId}\`)\n` +
              `📦 *Produk:* ${product.name} (${product.priceFormatted})\n` +
              `👥 *Afiliator:* \`${orderInfo.refCode}\` (Komisi 30%: *Rp ${estCommission.toLocaleString('id-ID')}*)\n` +
              `🖥️ *HWID Perangkat:* \`${hwid}\`\n\n` +
              `Silakan verifikasi bukti transfer sebelum klik Approve.`,
              { parse_mode: 'Markdown', reply_markup: adminKeyboard }
            );

            await sendTelegram(BOT_TOKEN, chatId, '⏳ Bukti transfer & HWID Anda sedang diverifikasi Admin. License Key resmi akan dikirim otomatis ke chat ini segera setelah disetujui.');
            return new Response('OK');
          }

          // Respons fallback umum
          await sendTelegram(BOT_TOKEN, chatId,
            `Halo ${userName}! Silakan gunakan menu tombol di bawah untuk memilih opsi:`,
            { parse_mode: 'Markdown' }
          );
          return new Response('OK');
        }

        return new Response('OK');
      }

      // ==========================================================================
      // 🛡️ 4. ENDPOINT VERIFIKASI LISENSI (/verify)
      // ==========================================================================
      if (url.pathname === '/verify') {
        let hwid = url.searchParams.get('hwid');
        if (request.method === 'POST') {
          try {
            const body = await request.json();
            if (body && body.hwid) hwid = body.hwid;
          } catch (e) {}
        }

        if (!hwid) {
          return new Response(JSON.stringify({ valid: false, status: 'error', message: 'HWID diperlukan' }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400
          });
        }

        hwid = hwid.trim();

        if (env.LICENSE_KV) {
          let stored = await env.LICENSE_KV.get(hwid);
          if (!stored) {
            const directStored = await env.LICENSE_KV.get('direct_' + hwid);
            if (directStored) {
              stored = directStored;
              try {
                await env.LICENSE_KV.put(hwid, directStored);
                await env.LICENSE_KV.delete('direct_' + hwid);
              } catch (e) {}
            }
          }
          if (stored) {
            const data = JSON.parse(stored);
            if (data.status === 'active') {
              return new Response(JSON.stringify({
                valid: true,
                status: 'active',
                hwid,
                product: data.product || 'Reddit Manager Pro',
                licenseKey: data.licenseKey,
                message: 'Software Active!'
              }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
              });
            } else {
              return new Response(JSON.stringify({
                valid: false,
                status: 'revoked',
                message: 'Lisensi telah dinonaktifkan oleh Admin'
              }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
              });
            }
          }
        }

        return new Response(JSON.stringify({
          valid: false,
          status: 'unregistered',
          message: 'Perangkat ini belum memiliki lisensi aktif.'
        }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });
      }

      // ==========================================================================
      // 🔑 5. ENDPOINT AKTIVASI LISENSI (/activate)
      // ==========================================================================
      if (url.pathname === '/activate') {
        let hwid = url.searchParams.get('hwid');
        let key = url.searchParams.get('licenseKey') || url.searchParams.get('key');

        if (request.method === 'POST') {
          try {
            const body = await request.json();
            if (body) {
              if (body.hwid) hwid = body.hwid;
              if (body.licenseKey) key = body.licenseKey;
              if (body.key) key = body.key;
            }
          } catch (e) {}
        }

        if (!hwid || !key) {
          return new Response(JSON.stringify({ valid: false, status: 'error', message: 'HWID & License Key diperlukan' }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400
          });
        }

        hwid = hwid.trim();
        key = key.trim().toUpperCase();

        if (env.LICENSE_KV) {
          let stored = await env.LICENSE_KV.get(hwid);
          if (!stored) {
            const directStored = await env.LICENSE_KV.get('direct_' + hwid);
            if (directStored) {
              stored = directStored;
              try {
                await env.LICENSE_KV.put(hwid, directStored);
                await env.LICENSE_KV.delete('direct_' + hwid);
              } catch (e) {}
            }
          }
          if (stored) {
            const data = JSON.parse(stored);
            if (data.licenseKey === key && data.status === 'active') {
              return new Response(JSON.stringify({
                valid: true,
                status: 'success',
                hwid,
                licenseKey: key,
                product: data.product,
                message: 'Aktivasi Berhasil! Software siap digunakan.'
              }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
              });
            } else if (data.licenseKey !== key) {
              return new Response(JSON.stringify({
                valid: false,
                status: 'mismatch',
                message: 'Kunci lisensi tidak cocok dengan HWID perangkat ini (1 device = 1 lisensi).'
              }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
              });
            } else {
              return new Response(JSON.stringify({
                valid: false,
                status: 'revoked',
                message: 'Lisensi telah dinonaktifkan oleh Admin.'
              }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
              });
            }
          }
        }

        return new Response(JSON.stringify({
          valid: false,
          status: 'error',
          message: 'Kunci lisensi belum terdaftar atau belum disetujui Admin.'
        }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });
      }

      // Default: Portal Web Aktivasi Software
      const refQuery = url.searchParams.get('ref');
      const existingRef = getCookie(request, 'aff_ref');
      const activeRef = refQuery || existingRef || 'direct';

      return new Response(renderActivationPageHtml(activeRef), {
        headers: { 'Content-Type': 'text/html; charset=utf-8' }
      });

    } catch (globalErr) {
      return new Response('Worker Error: ' + (globalErr.stack || globalErr.message), {
        status: 200,
        headers: { 'Content-Type': 'text/plain' }
      });
    }
  }
};

const MAIN_KEYBOARD = {
  keyboard: [
    [{ text: '📦 Beli Software' }, { text: '🤝 Link Afiliasi Saya' }],
    [{ text: '💳 Cek Saldo Komisi' }, { text: '💵 Tarik Saldo' }]
  ],
  resize_keyboard: true,
  is_persistent: true
};

async function recordNewLead(kv, leadData) {
  try {
    const raw = await kv.get('recent_leads');
    let list = raw ? JSON.parse(raw) : [];
    list = list.filter(item => String(item.chatId) !== String(leadData.chatId));
    list.unshift(leadData);
    if (list.length > 20) list = list.slice(0, 20);
    await kv.put('recent_leads', JSON.stringify(list), { expirationTtl: 86400 * 7 });
  } catch (err) {}
}

function getCookie(request, name) {
  const cookieString = request.headers.get('Cookie');
  if (!cookieString) return null;
  const match = cookieString.match(new RegExp('(^|;\\s*)(' + name + ')=([^;]*)'));
  return match ? decodeURIComponent(match[3]) : null;
}

function generateQrisCaption(productName, priceFormatted, refCode) {
  const affText = (refCode && refCode !== 'direct') ? `\n• *Kode Referral:* \`${refCode}\`` : '';
  return (
    `🛒 *Anda memilih: ${productName} (${priceFormatted})*${affText}\n\n` +
    `💳 *PEMBAYARAN VIA QRIS (ALL E-WALLET & BANK)*\n` +
    `🏢 *Merchant:* Cuan Digital\n` +
    `📋 *NMID:* ID1026544552890\n\n` +
    `📌 *Cara Pembayaran:*\n` +
    `1. Scan QRIS di atas memakai Aplikasi Bank (BCA, Mandiri, BRI, BNI) atau E-Wallet (DANA, OVO, GoPay, ShopeePay).\n` +
    `2. Transfer sesuai nominal paket (Rp 99.000).\n` +
    `3. Setelah berhasil, kirimkan *Foto Bukti Transfer & Kode HWID* Software Anda ke chat bot ini.\n\n` +
    `🖥️ *Catatan HWID:*\n` +
    `• Buka aplikasi di laptop Anda untuk melihat kode HWID (contoh: \`RD-HWID-...\`).`
  );
}

async function sendTelegram(token, chatId, text, options = {}) {
  const body = {
    chat_id: chatId,
    text,
    reply_markup: options.reply_markup || MAIN_KEYBOARD,
    ...options
  };
  return fetch(`https://api.telegram.org/bot${token}/sendMessage`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
  });
}

async function sendTelegramPhoto(token, chatId, photoUrl, caption, options = {}) {
  const body = {
    chat_id: chatId,
    photo: photoUrl,
    caption,
    parse_mode: 'Markdown',
    reply_markup: options.reply_markup || MAIN_KEYBOARD,
    ...options
  };
  return fetch(`https://api.telegram.org/bot${token}/sendPhoto`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
  });
}

function renderActivationPageHtml(refCode) {
  return `<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Software Activation - Reddit Manager Pro</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');
        body { font-family: 'Inter', sans-serif; background-color: #0b0f19; }
        .glass { background: rgba(17, 24, 39, 0.85); backdrop-filter: blur(16px); border: 1px solid rgba(255, 255, 255, 0.08); }
    </style>
</head>
<body class="flex items-center justify-center min-h-screen p-4 text-white">
    <div class="glass w-full max-w-md p-8 rounded-3xl shadow-2xl text-center">
        <div class="mb-6 relative">
            <div class="bg-gradient-to-tr from-orange-600 to-red-500 w-20 h-20 rounded-2xl flex items-center justify-center mx-auto text-white shadow-lg shadow-orange-500/40">
                <i class="fab fa-reddit-alien text-3xl"></i>
            </div>
        </div>
        <h1 class="text-2xl font-bold mb-1">Reddit Manager Pro</h1>
        <p class="text-xs text-orange-400 font-semibold tracking-wider uppercase mb-3">Multi-Screen & Community Automation Suite</p>
        <p id="statusMessage" class="text-gray-400 text-sm mb-6">Silakan masukkan License Key untuk mengaktifkan software.</p>

        <div id="inputArea" class="space-y-4">
            <div class="text-left">
                <label class="text-[11px] text-gray-400 font-medium ml-1 mb-1 block">Kode HWID Perangkat</label>
                <div class="relative">
                    <i class="fas fa-desktop absolute left-4 top-1/2 -translate-y-1/2 text-gray-500"></i>
                    <input type="text" id="hwidInput" placeholder="RD-HWID-XXXX-XXXX" 
                        class="w-full pl-12 pr-4 py-3 bg-slate-900/90 border border-slate-700/80 rounded-xl text-white font-mono text-sm placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-orange-500">
                </div>
            </div>

            <div class="text-left">
                <label class="text-[11px] text-gray-400 font-medium ml-1 mb-1 block">License Key</label>
                <div class="relative">
                    <i class="fas fa-key absolute left-4 top-1/2 -translate-y-1/2 text-gray-500"></i>
                    <input type="text" id="licenseKey" placeholder="RD-PRO-XXXX-XXXX" 
                        class="w-full pl-12 pr-4 py-3 bg-slate-900/90 border border-slate-700/80 rounded-xl text-white font-mono text-sm placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-orange-500">
                </div>
            </div>
            
            <button onclick="activateLicense()" id="btnActivate" 
                class="w-full py-3.5 bg-orange-600 hover:bg-orange-500 text-white font-semibold rounded-xl transition-all shadow-lg shadow-orange-600/30 flex items-center justify-center gap-2">
                <span>Aktivasi Sekarang</span>
                <i class="fas fa-arrow-right text-sm"></i>
            </button>
            <div class="pt-2">
                <a href="https://t.me/AppDockHub_Bot?start=buy_reddit_pro_ref_${refCode}" target="_blank" class="text-xs text-orange-400 hover:text-orange-300 underline">
                    Belum punya lisensi? Beli via Telegram @AppDockHub_Bot (Rp 99.000)
                </a>
            </div>
        </div>
        <div class="mt-8 pt-4 border-t border-slate-800 flex justify-between items-center text-[10px] text-gray-500">
            <span>AppDockHub Security</span>
            <span class="font-mono">1 Device = 1 License</span>
        </div>
    </div>
    <script>
        const API_URL = window.location.origin;
        async function activateLicense() {
            const hwid = document.getElementById('hwidInput').value.trim();
            const key = document.getElementById('licenseKey').value.trim();
            if (!hwid || !key) return alert('Masukkan HWID dan License Key!');
            try {
                const res = await fetch(API_URL + '/activate', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ hwid, licenseKey: key })
                });
                const data = await res.json();
                if (data.status === 'success') {
                    alert('Aktivasi Berhasil! Silakan buka Reddit Manager Pro.');
                    location.reload();
                } else {
                    alert('Gagal: ' + (data.message || 'Key salah'));
                }
            } catch (e) {
                alert('Gagal menghubungi server aktivasi.');
            }
        }
    </script>
</body>
</html>`;
}
