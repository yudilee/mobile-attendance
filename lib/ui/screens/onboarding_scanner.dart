import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/app_settings.dart';
import '../../services/api_service.dart';
import 'home_screen.dart';

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
      Map<String, dynamic> data = {};
      try {
        final decoded = jsonDecode(rawValue);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        } else if (decoded is Map) {
          data = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        // Fallback: If plain text token or string was scanned
        data = {'token': rawValue.trim()};
      }

      // Extract Server URL with fallback
      var url = (data['server_url'] ?? data['url'] ?? data['server'] ?? widget.fallbackServerUrl).toString().trim();
      if (url.isEmpty || !url.startsWith('http')) {
        url = 'https://attendance.hartonomotor-group.com';
      }

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

      if (url.endsWith('/')) {
        url = url.substring(0, url.length - 1);
      }

      await AppSettings.setServerUrl(url);

      // Extract API Key and Employee ID
      final apiKey = (data['api_key'] ?? data['token'] ?? data['key'] ?? '').toString().trim();
      final empId = (data['employee_id'] ?? data['pin'] ?? data['emp_id'] ?? '').toString().trim();
      final empName = (data['employee_name'] ?? data['name'] ?? '').toString().trim();

      if (apiKey.isNotEmpty) {
        await AppSettings.setApiKey(apiKey);
      }
      if (empId.isNotEmpty) {
        await AppSettings.setEmployeeId(empId);
      }
      if (empName.isNotEmpty) {
        await AppSettings.setEmployeeName(empName);
      }

      final api = ApiService();

      // Perform onboarding call to register device
      final response = await api.onboardDevice(
        token: apiKey.isNotEmpty ? apiKey : null,
        employeeId: empId.isNotEmpty ? empId : null,
        deviceUuid: widget.deviceUuid,
        deviceLabel: null,
      );

      final status = response['status'] ?? response['device_status'] ?? 'active';

      if (status == 'active' || status == 'approved' || status == 'ok') {
        final returnedApiKey = (response['api_key'] ?? '').toString().trim();
        if (returnedApiKey.isNotEmpty) {
          await AppSettings.setApiKey(returnedApiKey);
        }
        final returnedEmpId = (response['employee_id'] ?? '').toString().trim();
        if (returnedEmpId.isNotEmpty) {
          await AppSettings.setEmployeeId(returnedEmpId);
        }
        final returnedEmpName = (response['employee_name'] ?? '').toString().trim();
        if (returnedEmpName.isNotEmpty) {
          await AppSettings.setEmployeeName(returnedEmpName);
        }

        setState(() => _success = true);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      } else {
        setState(() => _error = response['detail'] ?? response['message'] ?? 'Status: $status');
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
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
