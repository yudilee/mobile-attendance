import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScanScreen extends StatefulWidget {
  final String expectedQrData; // The branch QR code data to match
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const QRScanScreen({
    super.key,
    required this.expectedQrData,
    required this.onSuccess,
    required this.onCancel,
  });

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  MobileScannerController? _controller;
  bool _matched = false;

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

  void _onDetect(BarcodeCapture capture) {
    if (_matched) return;

    for (final barcode in capture.barcodes) {
      if (barcode.rawValue == widget.expectedQrData) {
        HapticFeedback.heavyImpact();
        setState(() => _matched = true);
        widget.onSuccess();
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onCancel,
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Overlay with scan target area
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
          if (_matched)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle,
                      color: Colors.green, size: 64),
                  SizedBox(height: 16),
                  Text('QR Matched!',
                      style:
                          TextStyle(fontSize: 24, color: Colors.green)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
