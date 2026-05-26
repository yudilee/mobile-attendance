import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/app_settings.dart';
import '../../services/api_service.dart';
import '../../services/security_service.dart';

/// Self-contained onboarding QR scanner that handles scan + API call + save
/// all within itself, then closes the app. Never navigates back to Settings.
class OnboardingScanner extends StatefulWidget {
  final String deviceUuid;
  final String fallbackServerUrl;

  const OnboardingScanner({
    super.key,
    required this.deviceUuid,
    required this.fallbackServerUrl,
  });

  @override
  State<OnboardingScanner> createState() => _OnboardingScannerState();
}

class _OnboardingScannerState extends State<OnboardingScanner> {
  MobileScannerController? _controller;
  bool _processing = false;
  bool _success = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing || _success || _error != null) return;

    for (final barcode in capture.barcodes) {
      if (barcode.rawValue != null && !_processing) {
        setState(() => _processing = true);
        HapticFeedback.heavyImpact();
        await _handleQrData(barcode.rawValue!);
        return;
      }
    }
  }

  Future<void> _handleQrData(String rawValue) async {
    try {
      final data = jsonDecode(rawValue) as Map<String, dynamic>;
      var url = data['url'] as String;
      final token = data['token'] as String;

      // Localhost fallback
      if (url.contains('localhost') || url.contains('127.0.0.1')) {
        if (widget.fallbackServerUrl.isNotEmpty && widget.fallbackServerUrl.startsWith('http')) {
          try {
            final parsedCustom = Uri.parse(widget.fallbackServerUrl);
            final parsedQr = Uri.parse(url);
            url = url.replaceAll(
              '${parsedQr.host}:${parsedQr.port}',
              '${parsedCustom.host}:${parsedCustom.port}',
            ).replaceAll(parsedQr.host, parsedCustom.host);
          } catch (_) {}
        }
      }

      await AppSettings.setServerUrl(url);

      final api = ApiService();
      final response = await api.onboardDevice(
        token: token,
        deviceUuid: widget.deviceUuid,
        deviceLabel: null,
      );

      if (response['status'] == 'active') {
        final apiKey = response['api_key'] as String?;
        if (apiKey != null && apiKey.isNotEmpty) {
          await AppSettings.setApiKey(apiKey);
        }
        final empId = response['employee_id'] as String?;
        if (empId != null && empId.isNotEmpty) {
          await AppSettings.setEmployeeId(empId);
        }
        final empName = response['employee_name'] as String?;
        if (empName != null && empName.isNotEmpty) {
          await AppSettings.setEmployeeName(empName);
        }

        setState(() => _success = true);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) SystemNavigator.pop();
      } else {
        setState(() => _error = 'Status: ${response['status']}');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Onboarding QR'),
        leading: _processing || _success
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Scan target area
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          // Processing overlay
          if (_processing && !_success && _error == null)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Registering device...',
                        style: TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                ),
              ),
            ),
          // Success overlay
          if (_success)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 80),
                    SizedBox(height: 16),
                    Text('Device Registered!',
                        style: TextStyle(color: Colors.green, fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Restarting...',
                        style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
              ),
            ),
          // Error overlay
          if (_error != null)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 64),
                    const SizedBox(height: 16),
                    Text('Registration Failed',
                        style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(_error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
