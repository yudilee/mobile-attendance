import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

class NfcScanScreen extends StatefulWidget {
  final String expectedTagData; // The NFC tag data to match
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const NfcScanScreen({
    super.key,
    required this.expectedTagData,
    required this.onSuccess,
    required this.onCancel,
  });

  @override
  State<NfcScanScreen> createState() => _NfcScanScreenState();
}

class _NfcScanScreenState extends State<NfcScanScreen> {
  bool _matched = false;
  String _statusText = 'Hold your phone near the NFC tag...';

  @override
  void initState() {
    super.initState();
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      if (_matched) {
        return;
      }

      final data = _extractNfcData(tag);
      if (data == widget.expectedTagData) {
        setState(() {
          _matched = true;
          _statusText = 'NFC Matched!';
        });
        widget.onSuccess();
      } else {
        setState(() {
          _statusText = 'Tag mismatch. Try again...';
        });
      }
    });
  }

  /// Extract textual data from an NFC tag, trying NDEF payload first.
  String? _extractNfcData(NfcTag tag) {
    // Try NDEF format first (most common for programmable NFC tags)
    final ndef = tag.data['ndef'];
    if (ndef is Map) {
      final message = ndef['cachedMessage'];
      if (message is Map) {
        final records = message['records'] as List?;
        if (records != null && records.isNotEmpty) {
          for (final record in records) {
            if (record is Map) {
              final payload = record['payload'];
              // nfc_manager returns Uint8List from method channel for binary data
              if (payload is Uint8List) {
                try {
                  return String.fromCharCodes(payload);
                } catch (_) {}
              }
            }
          }
        }
      }
    }

    // Fallback: try extracting identifier from any available technology
    for (final key in tag.data.keys) {
      final techData = tag.data[key];
      if (techData is Map) {
        final id = techData['identifier'];
        // nfc_manager returns Uint8List from method channel for identifier fields
        if (id is Uint8List) {
          try {
            return String.fromCharCodes(id);
          } catch (_) {}
        }
      }
    }

    return null;
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan NFC Tag'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onCancel,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _matched ? Icons.check_circle : Icons.nfc,
              color: _matched ? Colors.green : Colors.blue,
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              _statusText,
              style: TextStyle(
                fontSize: 18,
                color: _matched ? Colors.green : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            if (!_matched) ...[
              const SizedBox(height: 32),
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.nfc, size: 64, color: Colors.blue),
                      SizedBox(height: 8),
                      Text(
                        'Tap NFC Tag\nHere',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
