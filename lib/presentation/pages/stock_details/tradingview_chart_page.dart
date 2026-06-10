import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/constants/constants.dart';

class TradingViewChartPage extends StatefulWidget {
  final String securityId;
  final String exchangeSegment;
  final String displayName;

  const TradingViewChartPage({
    super.key,
    required this.securityId,
    required this.exchangeSegment,
    required this.displayName,
  });

  @override
  State<TradingViewChartPage> createState() => _TradingViewChartPageState();
}

class _TradingViewChartPageState extends State<TradingViewChartPage> {
  static const String _baseUrl = 'https://dev.investapas.api.redoq.host';

  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isChartReady = false;

  @override
  void initState() {
    super.initState();

    // Go full-screen landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _initWebView();
  }

  void _initWebView() {
    final symbol = '${widget.exchangeSegment}:${widget.securityId}';
    final uri = Uri.parse(
      '$_baseUrl/chart/?symbol=${Uri.encodeComponent(symbol)}&theme=dark',
    );

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF131722))
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: _onJsMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            // Loading overlay is removed once JS fires chartReady.
            // But set a 5s fallback in case library is missing.
            Future.delayed(const Duration(seconds: 5), () {
              if (mounted && _isLoading) {
                setState(() => _isLoading = false);
              }
            });
          },
          onWebResourceError: (err) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(uri);
  }

  void _onJsMessage(JavaScriptMessage msg) {
    try {
      // Chart fires: { "event": "chartReady" }
      if (msg.message.contains('chartReady')) {
        setState(() {
          _isLoading  = false;
          _isChartReady = true;
        });
      }
    } catch (_) {}
  }

  /// Change the symbol shown in the chart from Flutter side.
  Future<void> changeSymbol(String symbol, {String resolution = 'D'}) async {
    if (!_isChartReady) return;
    await _controller.runJavaScript(
      "window.changeSymbol('${symbol.replaceAll("'", "\\'")}', '$resolution');",
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131722),
      body: Stack(
        children: [
          // ── WebView ────────────────────────────────────────────────────
          WebViewWidget(controller: _controller),

          // ── Loading overlay ────────────────────────────────────────────
          if (_isLoading)
            Container(
              color: const Color(0xFF131722),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 40, height: 40,
                    child: CircularProgressIndicator(
                      color: Colorz.primary,
                      strokeWidth: 2.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading chart…',
                    style: AppTextStyles.small.copyWith(
                      color: Colors.white54,
                      fontSize: SizeConfig.smallFont,
                    ),
                  ),
                ],
              ),
            ),

          // ── Top bar overlay ────────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Container(
                color: const Color(0xFF1E222D).withValues(alpha: 0.9),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Stock name
                    Expanded(
                      child: Text(
                        widget.displayName,
                        style: AppTextStyles.semiBold.copyWith(
                          color: Colors.white,
                          fontSize: SizeConfig.mediumFont,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // TradingView badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2962FF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: const Color(0xFF2962FF).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        'TradingView',
                        style: AppTextStyles.small.copyWith(
                          color: const Color(0xFF2962FF),
                          fontSize: 10,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Reload button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isLoading    = true;
                          _isChartReady = false;
                        });
                        _controller.reload();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
