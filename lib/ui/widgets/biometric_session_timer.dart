import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';

class BiometricSessionTimer extends StatefulWidget {
  final DateTime lastAuthTime;
  final int sessionSeconds;

  const BiometricSessionTimer({
    super.key,
    required this.lastAuthTime,
    required this.sessionSeconds,
  });

  @override
  State<BiometricSessionTimer> createState() => _BiometricSessionTimerState();
}

class _BiometricSessionTimerState extends State<BiometricSessionTimer> {
  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  @override
  void didUpdateWidget(covariant BiometricSessionTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lastAuthTime != widget.lastAuthTime ||
        oldWidget.sessionSeconds != widget.sessionSeconds) {
      _updateRemaining();
    }
  }

  void _updateRemaining() {
    final elapsed = DateTime.now().difference(widget.lastAuthTime).inSeconds;
    final remaining = widget.sessionSeconds - elapsed;
    if (remaining != _remainingSeconds) {
      if (mounted) {
        setState(() {
          _remainingSeconds = remaining > 0 ? remaining : 0;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remainingSeconds <= 0) return const SizedBox.shrink();

    final progress = _remainingSeconds / widget.sessionSeconds;
    Color color = AppTheme.successGreen;
    if (progress < 0.25) {
      color = AppTheme.errorRed;
    } else if (progress < 0.5) {
      color = Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Biometric Session Active',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
              ),
              Text(
                '${_remainingSeconds}s',
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
