import 'package:flutter/material.dart';
import 'package:flutter_pump_check/theme/app_dimensions.dart';
import 'package:flutter_pump_check/theme/claude_palette.dart';
import 'package:flutter_pump_check/theme/text_sizes.dart';
import 'package:webview_flutter/webview_flutter.dart';

class DashboardWebDrawer extends StatefulWidget {
  const DashboardWebDrawer({required this.title, required this.url, super.key});

  final String title;
  final String url;

  @override
  State<DashboardWebDrawer> createState() => _DashboardWebDrawerState();
}

class _DashboardWebDrawerState extends State<DashboardWebDrawer> {
  late final WebViewController _controller;
  var _loading = true;
  var _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _loading = true;
                _hasError = false;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            if (mounted) {
              setState(() {
                _loading = false;
                _hasError = true;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final background = isLight ? ClaudePalette.cream : ClaudePalette.charcoal;
    final foreground = isLight ? ClaudePalette.charcoal : ClaudePalette.cream;
    final muted = isLight
        ? ClaudePalette.lightMutedText
        : ClaudePalette.mutedText;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(context.dimensions.values.s24),
      ),
      child: ColoredBox(
        color: background,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  context.dimensions.values.s20,
                  context.dimensions.values.s14,
                  context.dimensions.values.s8,
                  context.dimensions.values.s8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          color: foreground,
                          fontSize: context.textSizes.s20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: foreground),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    if (_hasError)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(
                            context.dimensions.values.s24,
                          ),
                          child: Text(
                            'Could not load ${widget.title.toLowerCase()}. Please check your connection and try again.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: muted,
                              fontSize: context.textSizes.s16,
                              height: 1.35,
                            ),
                          ),
                        ),
                      )
                    else
                      WebViewWidget(controller: _controller),
                    if (_loading)
                      const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
