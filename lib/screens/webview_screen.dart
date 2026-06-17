import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../config/app_config.dart';
import '../services/connectivity_service.dart';
import '../services/download_service.dart';
import '../services/external_url_service.dart';
import '../services/file_selection_service.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_progress_bar.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  final ConnectivityService _connectivityService = ConnectivityService();
  final ExternalUrlService _externalUrlService = const ExternalUrlService();
  final FileSelectionService _fileSelectionService =
      const FileSelectionService();

  late final DownloadService _downloadService = DownloadService(
    _externalUrlService,
  );
  WebViewController? _controller;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  DateTime? _lastBackPress;
  String? _currentMainFrameUrl;

  int _loadingProgress = 0;
  bool _isLoading = true;
  bool _isOffline = false;
  bool _hasPageError = false;
  bool _isRetrying = false;
  String _errorTitle = 'Unable to load the page';
  String _errorMessage =
      'Please check your internet connection or try again later.';

  double? _pullStartY;
  bool _pullStartedAtTop = false;
  bool _isPullRefreshing = false;

  @override
  void initState() {
    super.initState();

    if (_supportsEmbeddedWebView) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..enableZoom(false)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: _handleNavigationRequest,
            onPageStarted: _handlePageStarted,
            onPageFinished: _handlePageFinished,
            onProgress: _handleProgress,
            onWebResourceError: _handleWebResourceError,
            onHttpError: _handleHttpError,
            onSslAuthError: _handleSslError,
          ),
        );

      unawaited(_configurePlatformWebView());
      unawaited(_loadInitialPage());
    }

    _connectivitySubscription = _connectivityService.onConnectivityChanged
        .listen(_handleConnectivityChanged);
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _configurePlatformWebView() async {
    final WebViewController? controller = _controller;
    if (controller == null) {
      return;
    }

    if (controller.platform is AndroidWebViewController) {
      final AndroidWebViewController androidController =
          controller.platform as AndroidWebViewController;

      await androidController.setMediaPlaybackRequiresUserGesture(false);
      await androidController.setOnShowFileSelector(
        _fileSelectionService.pickFiles,
      );
    }
  }

  Future<void> _loadInitialPage() async {
    final bool hasConnection = await _connectivityService.hasConnection();

    if (!mounted) {
      return;
    }

    if (!hasConnection) {
      _showOfflineState();
      return;
    }

    await _loadWebsite();
  }

  Future<void> _loadWebsite() async {
    final WebViewController? controller = _controller;
    if (controller == null) {
      return;
    }

    setState(() {
      _isOffline = false;
      _hasPageError = false;
      _isLoading = true;
      _loadingProgress = 0;
      _errorTitle = 'Unable to load the page';
      _errorMessage =
          'Please check your internet connection or try again later.';
    });

    try {
      await controller.loadRequest(AppConfig.websiteUri);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showPageError();
    }
  }

  Future<void> _retryLoad() async {
    final WebViewController? controller = _controller;
    if (controller == null) {
      return;
    }

    if (_isRetrying) {
      return;
    }

    setState(() {
      _isRetrying = true;
    });

    final bool hasConnection = await _connectivityService.hasConnection();

    if (!mounted) {
      return;
    }

    if (!hasConnection) {
      setState(() {
        _isRetrying = false;
      });
      _showOfflineState();
      return;
    }

    setState(() {
      _isOffline = false;
      _hasPageError = false;
      _isLoading = true;
      _loadingProgress = 0;
    });

    try {
      final String? currentUrl = await controller.currentUrl();

      if (currentUrl == null || currentUrl.isEmpty) {
        await controller.loadRequest(AppConfig.websiteUri);
      } else {
        await controller.reload();
      }
    } catch (_) {
      if (mounted) {
        _showPageError();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  Future<NavigationDecision> _handleNavigationRequest(
    NavigationRequest request,
  ) async {
    final Uri? uri = Uri.tryParse(request.url);

    if (uri == null) {
      return NavigationDecision.prevent;
    }

    if (!request.isMainFrame) {
      return NavigationDecision.navigate;
    }

    if (_externalUrlService.isDownloadableUrl(uri)) {
      unawaited(_openDownload(uri));
      return NavigationDecision.prevent;
    }

    if (_externalUrlService.shouldOpenExternally(uri) ||
        _externalUrlService.isExternalWebUrl(uri)) {
      unawaited(_openExternal(uri));
      return NavigationDecision.prevent;
    }

    if (!_externalUrlService.isAllowedWebViewUrl(uri)) {
      _showSnackBar('This link cannot be opened in the app.');
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  void _handlePageStarted(String url) {
    _currentMainFrameUrl = url;

    if (!mounted) {
      return;
    }

    setState(() {
      _hasPageError = false;
      _isLoading = true;
      _loadingProgress = 0;
    });
  }

  void _handlePageFinished(String url) {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _isPullRefreshing = false;
      _loadingProgress = 100;
    });
  }

  void _handleProgress(int progress) {
    if (!mounted) {
      return;
    }

    setState(() {
      _loadingProgress = progress;
      _isLoading = progress < 100;
    });
  }

  void _handleWebResourceError(WebResourceError error) {
    if (error.isForMainFrame == false || !mounted) {
      return;
    }

    _showPageError(
      message: error.description.isEmpty
          ? 'Please check your internet connection or try again later.'
          : error.description,
    );
  }

  void _handleHttpError(HttpResponseError error) {
    final String? requestUrl = error.request?.uri.toString();

    if (requestUrl != null && requestUrl != _currentMainFrameUrl) {
      return;
    }

    final int? statusCode = error.response?.statusCode;
    _showPageError(
      title: 'Page unavailable',
      message: statusCode == null
          ? 'The server could not load this page.'
          : 'The server returned error $statusCode.',
    );
  }

  Future<void> _handleSslError(SslAuthError error) async {
    await error.cancel();

    if (!mounted) {
      return;
    }

    _showPageError(
      title: 'Secure connection failed',
      message:
          'The website security certificate could not be verified. Please try again later.',
    );
  }

  void _handleConnectivityChanged(List<ConnectivityResult> results) {
    if (!_connectivityService.hasUsableConnection(results)) {
      _showOfflineState();
      return;
    }

    if (_isOffline) {
      unawaited(_retryLoad());
    }
  }

  Future<void> _handleBackPressed() async {
    final WebViewController? controller = _controller;
    if (controller == null) {
      return;
    }

    if (await controller.canGoBack()) {
      await controller.goBack();
      return;
    }

    final DateTime now = DateTime.now();
    final bool shouldExit =
        _lastBackPress != null &&
        now.difference(_lastBackPress!) < const Duration(seconds: 2);

    if (shouldExit) {
      await SystemNavigator.pop();
      return;
    }

    _lastBackPress = now;
    _showSnackBar('Press back again to exit');
  }

  void _showOfflineState() {
    if (!mounted) {
      return;
    }

    setState(() {
      _isOffline = true;
      _hasPageError = false;
      _isLoading = false;
      _isPullRefreshing = false;
      _errorTitle = 'No Internet Connection';
      _errorMessage = 'Please check your connection and try again.';
    });
  }

  void _showPageError({String? title, String? message}) {
    if (!mounted) {
      return;
    }

    setState(() {
      _isOffline = false;
      _hasPageError = true;
      _isLoading = false;
      _isPullRefreshing = false;
      _errorTitle = title ?? 'Unable to load the page';
      _errorMessage =
          message ??
          'Please check your internet connection or try again later.';
    });
  }

  Future<void> _openExternal(Uri uri) async {
    final bool didLaunch = await _externalUrlService.launchExternal(uri);

    if (!didLaunch && mounted) {
      _showSnackBar('Unable to open this link.');
    }
  }

  Future<void> _openDownload(Uri uri) async {
    final bool didLaunch = await _downloadService.openDownload(uri);

    if (!didLaunch && mounted) {
      _showSnackBar('Unable to start the download.');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _handlePointerDown(PointerDownEvent event) {
    _pullStartY = event.position.dy;
    _pullStartedAtTop = false;

    unawaited(
      _readWebScrollOffset().then((double scrollOffset) {
        if (mounted && _pullStartY != null) {
          _pullStartedAtTop = scrollOffset <= 2;
        }
      }),
    );
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_pullStartY == null ||
        !_pullStartedAtTop ||
        _isLoading ||
        _isOffline ||
        _hasPageError ||
        _isPullRefreshing) {
      return;
    }

    final double distance = event.position.dy - _pullStartY!;
    if (distance < 110) {
      return;
    }

    setState(() {
      _isPullRefreshing = true;
    });
    unawaited(_controller?.reload());
  }

  void _handlePointerEnd(PointerEvent event) {
    _pullStartY = null;
    _pullStartedAtTop = false;
  }

  Future<double> _readWebScrollOffset() async {
    final WebViewController? controller = _controller;
    if (controller == null) {
      return 0;
    }

    try {
      final Object result = await controller.runJavaScriptReturningResult(
        'Math.max(window.scrollY || 0, document.documentElement.scrollTop || 0).toString()',
      );
      return double.tryParse(result.toString().replaceAll('"', '')) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_supportsEmbeddedWebView) {
      return _buildWebFallback(context);
    }

    final bool showError = _isOffline || _hasPageError;
    final WebViewController? controller = _controller;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          unawaited(_handleBackPressed());
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              if (!showError)
                Listener(
                  onPointerDown: _handlePointerDown,
                  onPointerMove: _handlePointerMove,
                  onPointerUp: _handlePointerEnd,
                  onPointerCancel: _handlePointerEnd,
                  child: controller == null
                      ? const SizedBox.shrink()
                      : WebViewWidget(controller: controller),
                ),
              if (showError)
                ErrorView(
                  title: _errorTitle,
                  message: _errorMessage,
                  isRetrying: _isRetrying,
                  onRetry: _retryLoad,
                ),
              Align(
                alignment: Alignment.topCenter,
                child: LoadingProgressBar(
                  progress: _loadingProgress,
                  visible: _isLoading && !showError,
                ),
              ),
              if (_isPullRefreshing)
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            blurRadius: 10,
                            color: Color(0x22000000),
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _supportsEmbeddedWebView => !kIsWeb;

  Widget _buildWebFallback(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.open_in_browser_rounded,
                    size: 56,
                    color: Color(0xFF145C9E),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'This app shell is designed for Android WebView.',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'When running on Chrome, open the hosted site directly in the browser instead of embedding it with webview_flutter.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      unawaited(
                        _externalUrlService.launchExternal(AppConfig.websiteUri),
                      );
                    },
                    icon: const Icon(Icons.launch_rounded),
                    label: const Text('Open Website'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
