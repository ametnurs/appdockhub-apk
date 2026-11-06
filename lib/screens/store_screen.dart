import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/deep_link_service.dart';

/// StoreScreen: Halaman Katalog & Jualan Aplikasi / Software berbasis Live URL View
/// (https://appdockhub.com) sehingga admin dapat menambah/mengupdate produk & promosi
/// kapan saja dari web tanpa perlu update atau upload ulang APK ke Play Store!
class StoreScreen extends StatefulWidget {
  final String pairToken;

  const StoreScreen({Key? key, required this.pairToken}) : super(key: key);

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  static const String storeBaseUrl = 'https://appdockhub.com';

  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  String get _targetStoreUrl {
    final token = widget.pairToken.isNotEmpty ? widget.pairToken : 'direct';
    return '$storeBaseUrl/?ref=${Uri.encodeComponent(token)}';
  }

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF070B14))
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            // Jika pengguna klik link Telegram (t.me / tg://) atau WhatsApp di dalam katalog web,
            // otomatis buka aplikasi Telegram / WA langsung!
            if (url.startsWith('tg://') ||
                url.contains('t.me/') ||
                url.startsWith('whatsapp://') ||
                url.contains('wa.me/')) {
              DeepLinkService.openExternalUrl(url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (error) {
            // Abaikan error sub-resource kecil, hanya tandai jika main frame gagal
            if (error.isForMainFrame == true && mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(_targetStoreUrl));
  }

  void _reloadStore() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    _controller.loadRequest(Uri.parse(_targetStoreUrl));
  }

  @override
  Widget build(BuildContext context) {
    const bgDark = Color(0xFF070B14);

    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // 1. HEADER BAR KATALOG SOFTWARE (APPDOCKHUB.COM)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1120),
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF5E00), Color(0xFFFF9900)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Katalog Software & App',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15.5,
                            ),
                          ),
                          Text(
                            'appdockhub.com • Official Store',
                            style: TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Kembali',
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 17),
                        onPressed: () async {
                          if (await _controller.canGoBack()) {
                            await _controller.goBack();
                          }
                        },
                      ),
                      IconButton(
                        tooltip: 'Refresh Produk',
                        icon: const Icon(Icons.refresh_rounded, color: Color(0xFF00F0FF), size: 20),
                        onPressed: _reloadStore,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. LIVE WEBVIEW AREA (https://appdockhub.com)
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: _controller),

                  if (_isLoading)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          CircularProgressIndicator(color: Color(0xFFFF9900)),
                          SizedBox(height: 12),
                          Text(
                            'Memuat Katalog Produk AppDockHub...',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_hasError && !_isLoading)
                    Container(
                      color: bgDark,
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5E00).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.storefront_rounded, color: Color(0xFFFF9900), size: 34),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Katalog Produk Sedang Diperbarui',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Pastikan koneksi internet aktif untuk mengakses katalog software terbaru di appdockhub.com.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5, height: 1.4),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF5E00),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _reloadStore,
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text(
                                  'Muat Ulang',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF38BDF8),
                                  side: const BorderSide(color: Color(0xFF38BDF8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => DeepLinkService.openBotPairing(widget.pairToken),
                                icon: const Icon(Icons.telegram, size: 18),
                                label: const Text(
                                  'Order via Bot',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
