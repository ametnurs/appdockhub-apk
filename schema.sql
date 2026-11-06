-- ============================================================================
-- APPDOCK HUB ECOSYSTEM - CLOUDFLARE D1 DATABASE SCHEMA (schema.sql)
-- SQLite dialect for Cloudflare D1
-- ============================================================================

-- 1. TABEL USERS (Pengguna Telegram & APK Pairing)
CREATE TABLE IF NOT EXISTS users (
    telegram_id TEXT PRIMARY KEY,
    app_pair_token TEXT UNIQUE,
    referrer_id TEXT,                    -- Upline / Tier 2 sponsor telegram_id
    balance_direct REAL DEFAULT 0.0,     -- Saldo Komisi Penjualan Langsung 30%
    balance_team REAL DEFAULT 0.0,       -- Saldo Komisi Pasif Tim 5% (Tier 2)
    balance_ads REAL DEFAULT 0.0,        -- Saldo Akumulasi Nonton Iklan Rewarded
    ads_watched_today INTEGER DEFAULT 0, -- Counter nonton iklan harian (Maks 10)
    last_ad_watch_date TEXT,             -- Format: YYYY-MM-DD untuk auto-reset harian
    max_level INTEGER DEFAULT 1,         -- Level tertinggi game yang diselesaikan
    last_milestone_awarded INTEGER DEFAULT 0, -- Milestone kelipatan 10 terakhir yang sudah dikirim ke sponsor
    last_ip TEXT,                        -- IP Publik terakhir yang mengakses game/iklan
    ip_warnings INTEGER DEFAULT 0,       -- Jumlah peringatan pelanggaran multi-device / proxy / IP ganda
    is_banned INTEGER DEFAULT 0,         -- Status Banned (1 = Banned karena curang / multi-IP / VPN)
    ban_reason TEXT,                     -- Alasan akun/perangkat di-banned
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Indexing users untuk query cepat saat pairing APK, referral tracking & deteksi IP ganda
CREATE INDEX IF NOT EXISTS idx_users_pair_token ON users(app_pair_token);
CREATE INDEX IF NOT EXISTS idx_users_referrer ON users(referrer_id);
CREATE INDEX IF NOT EXISTS idx_users_last_ip ON users(last_ip);
CREATE INDEX IF NOT EXISTS idx_users_ip_date ON users(last_ip, last_ad_watch_date);

-- 1B. TABEL GAME_WALLETS (Dompet Terpisah per Game - Opsi A Multi-Game Ecosystem)
-- Mencegah penggabungan saldo antar-game sehingga setiap game wajib mencapai Min. WD Rp 50.000 sendiri-sendiri
CREATE TABLE IF NOT EXISTS game_wallets (
    pair_token TEXT NOT NULL,
    game_id TEXT NOT NULL,               -- e.g. 'cyber_orbit', 'neon_strike', dll
    game_name TEXT NOT NULL,             -- e.g. 'Cyber Orbit'
    telegram_id TEXT,                    -- Terhubung otomatis saat user pairing ke Bot
    balance REAL DEFAULT 0.0,            -- Saldo khusus game ini (tidak digabung dengan game lain)
    ads_watched_today INTEGER DEFAULT 0, -- Kuota harian khusus game ini (Maks 60)
    last_ad_watch_date TEXT,             -- Format YYYY-MM-DD
    last_ip TEXT,                        -- IP Publik terakhir untuk cegah double initial boost lintas game
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (pair_token, game_id)
);

CREATE INDEX IF NOT EXISTS idx_game_wallets_tg ON game_wallets(telegram_id);
CREATE INDEX IF NOT EXISTS idx_game_wallets_ip_date ON game_wallets(last_ip, last_ad_watch_date);

-- 2. TABEL LICENSES (Pengelolaan Lisensi Multi-Software Terikat HWID)
CREATE TABLE IF NOT EXISTS licenses (
    license_key TEXT PRIMARY KEY,
    product_name TEXT NOT NULL,          -- e.g. 'Reddit Manager Pro', 'Facebook Account Manager Pro'
    hwid TEXT,                           -- Hardware ID Perangkat (1 Device = 1 License)
    status TEXT DEFAULT 'AVAILABLE',     -- 'AVAILABLE', 'ACTIVE', 'REVOKED'
    activated_at DATETIME
);

-- Indexing licenses untuk validasi cepat saat startup software / aktivasi
CREATE INDEX IF NOT EXISTS idx_licenses_hwid ON licenses(hwid);
CREATE INDEX IF NOT EXISTS idx_licenses_status ON licenses(status);

-- 3. TABEL TRANSACTIONS (Pencatatan Penjualan & Komisi Afiliasi 2-Tier)
CREATE TABLE IF NOT EXISTS transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    buyer_telegram_id TEXT NOT NULL,
    product_name TEXT NOT NULL,
    amount REAL NOT NULL,                -- Harga beli (misal Rp 99.000)
    tier1_seller_id TEXT,                -- Afiliator langsung (Menerima 30%)
    tier1_commission REAL DEFAULT 0.0,   -- Nilai komisi 30% (Rp 29.700)
    tier2_seller_id TEXT,                -- Sponsor upline dari tier1 (Menerima 5%)
    tier2_commission REAL DEFAULT 0.0,   -- Nilai komisi 5% (Rp 4.950)
    status TEXT DEFAULT 'PENDING',       -- 'PENDING', 'PAID', 'REJECTED'
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Indexing transactions
CREATE INDEX IF NOT EXISTS idx_transactions_buyer ON transactions(buyer_telegram_id);
CREATE INDEX IF NOT EXISTS idx_transactions_t1 ON transactions(tier1_seller_id);
CREATE INDEX IF NOT EXISTS idx_transactions_t2 ON transactions(tier2_seller_id);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);

-- ============================================================================
-- SEED SAMPLE LICENSES (Opsional untuk pengujian awal)
-- ============================================================================
INSERT OR IGNORE INTO licenses (license_key, product_name, status) 
VALUES 
    ('RD-PRO-DEMO-0001', 'Reddit Manager Pro', 'AVAILABLE'),
    ('FB-PRO-DEMO-0002', 'Facebook Account Manager Pro', 'AVAILABLE'),
    ('TK-PRO-DEMO-0003', 'TikTok Multi-Screen Pro', 'AVAILABLE');
