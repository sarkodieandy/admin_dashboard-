import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/app_spacing.dart';

class PaystackCheckoutArgs {
  const PaystackCheckoutArgs({
    required this.authorizationUrl,
    required this.reference,
    required this.callbackUrl,
  });

  final String authorizationUrl;
  final String reference;
  final String callbackUrl;
}

class PaystackCheckoutScreen extends StatefulWidget {
  const PaystackCheckoutScreen({super.key, required this.args});

  static const routePath = '/payment/paystack';

  final PaystackCheckoutArgs args;

  @override
  State<PaystackCheckoutScreen> createState() => _PaystackCheckoutScreenState();
}

class _PaystackCheckoutScreenState extends State<PaystackCheckoutScreen> {
  late final WebViewController _controller;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    final args = widget.args;
    final callbackUrl = args.callbackUrl.trim();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) {
            if (!mounted) return;
            setState(() => _progress = p.clamp(0, 100));
          },
          onNavigationRequest: (request) {
            final url = request.url;
            if (callbackUrl.isNotEmpty && url.startsWith(callbackUrl)) {
              Navigator.of(context).pop(true);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(args.authorizationUrl));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = _progress < 90;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pay with Paystack'),
          actions: [
            if (isLoading)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.x16),
                child: Center(
                  child: SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            IconButton(
              tooltip: 'Close',
              onPressed: () => Navigator.of(context).pop(false),
              icon: const Icon(Icons.close_rounded),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Column(
          children: [
            if (isLoading)
              LinearProgressIndicator(
                value: _progress <= 0 ? null : (_progress / 100.0),
                minHeight: 2,
              ),
            Expanded(child: WebViewWidget(controller: _controller)),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.x16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text("I've completed payment"),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
