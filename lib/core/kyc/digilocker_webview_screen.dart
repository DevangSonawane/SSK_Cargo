import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'digilocker_return.dart';

/// Result of the in-app DigiLocker page.
class DigilockerWebViewResult {
  const DigilockerWebViewResult({
    required this.reachedRedirect,
    this.verificationId,
  });

  /// True when DigiLocker redirected to [kDigilockerRedirectUrl], i.e. the
  /// user finished (Allow or Deny) on DigiLocker's side.
  final bool reachedRedirect;

  /// `verification_id` from the redirect URL, when present.
  final String? verificationId;
}

/// Opens the DigiLocker consent URL inside the app and closes itself the
/// moment DigiLocker redirects to [kDigilockerRedirectUrl].
///
/// Why a WebView rather than a Chrome tab: a Chrome tab can only hand the
/// redirect back to the app through a verified Android App Link, which needs
/// the backend to serve `/.well-known/assetlinks.json`. Without it, Play
/// installs were left on the redirect page and never came back. Here the app
/// sees the redirect itself, so it works with no backend setup at all.
class DigilockerWebViewScreen extends StatefulWidget {
  const DigilockerWebViewScreen({super.key, required this.url});

  final String url;

  static Future<DigilockerWebViewResult> open(
    BuildContext context,
    String url,
  ) async {
    final result = await Navigator.of(context, rootNavigator: true)
        .push<DigilockerWebViewResult>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => DigilockerWebViewScreen(url: url),
          ),
        );
    return result ?? const DigilockerWebViewResult(reachedRedirect: false);
  }

  @override
  State<DigilockerWebViewScreen> createState() =>
      _DigilockerWebViewScreenState();
}

class _DigilockerWebViewScreenState extends State<DigilockerWebViewScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (value) {
            if (mounted) setState(() => _progress = value);
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.navigate;
            if (_isRedirect(uri)) {
              _finish(uri);
              return NavigationDecision.prevent;
            }
            // DigiLocker / bank pages sometimes hand off to an app
            // (intent://, upi://, tel:…). A WebView can't load those.
            if (uri.scheme != 'http' && uri.scheme != 'https') {
              launchUrl(uri, mode: LaunchMode.externalApplication)
                  .catchError((_) => false);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          // Backups for redirects that skip onNavigationRequest (e.g. some
          // server-side 302s on older WebViews).
          onPageStarted: (url) {
            final uri = Uri.tryParse(url);
            if (uri != null && _isRedirect(uri)) _finish(uri);
          },
          onUrlChange: (change) {
            final uri = Uri.tryParse(change.url ?? '');
            if (uri != null && _isRedirect(uri)) _finish(uri);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  bool _isRedirect(Uri uri) =>
      uri.host == kDigilockerReturnHost &&
      uri.path.startsWith(kDigilockerReturnPath);

  void _finish(Uri uri) {
    if (_finished || !mounted) return;
    _finished = true;
    final id = uri.queryParameters['verification_id'];
    Navigator.of(context).pop(
      DigilockerWebViewResult(reachedRedirect: true, verificationId: id),
    );
  }

  Future<void> _handleBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return;
    }
    if (mounted && !_finished) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('DigiLocker'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () {
              if (!_finished) Navigator.of(context).pop();
            },
          ),
          bottom: _progress < 100
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(2),
                  child: LinearProgressIndicator(value: _progress / 100),
                )
              : null,
        ),
        body: SafeArea(child: WebViewWidget(controller: _controller)),
      ),
    );
  }
}
