import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Slim banner that automatically appears at the top of the screen when the
/// device has no internet connection. Auto-dismisses 3 seconds after coming back online.
class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({super.key});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner>
    with SingleTickerProviderStateMixin {
  _BannerState _state = _BannerState.hidden;
  late final AnimationController _controller;
  late final Animation<double> _heightAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _heightAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _listenToConnectivity();
  }

  void _listenToConnectivity() {
    // Check initial state
    Connectivity().checkConnectivity().then(_handleResult);
    // Listen to changes
    Connectivity().onConnectivityChanged.listen(_handleResult);
  }

  void _handleResult(ConnectivityResult result) {
    final isOnline = result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet;

    if (!mounted) return;

    if (!isOnline && _state != _BannerState.offline) {
      setState(() => _state = _BannerState.offline);
      _controller.forward();
    } else if (isOnline && _state == _BannerState.offline) {
      // Flash "Back Online" for 3 seconds then hide
      setState(() => _state = _BannerState.backOnline);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _state = _BannerState.hidden);
          _controller.reverse();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_state == _BannerState.hidden) return const SizedBox.shrink();

    final Color bgColor;
    final Color textColor;
    final IconData icon;
    final String message;

    switch (_state) {
      case _BannerState.offline:
        bgColor = const Color(0xFFEF4444);
        textColor = Colors.white;
        icon = Icons.wifi_off_rounded;
        message = 'No Internet — punches will be queued';
      case _BannerState.backOnline:
        bgColor = const Color(0xFF10B981);
        textColor = Colors.white;
        icon = Icons.wifi_rounded;
        message = 'Back Online!';
      case _BannerState.hidden:
        return const SizedBox.shrink();
    }

    return SizeTransition(
      sizeFactor: _heightAnim,
      axisAlignment: -1,
      child: Container(
        width: double.infinity,
        color: bgColor,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 8),
            Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _BannerState { hidden, offline, backOnline }
