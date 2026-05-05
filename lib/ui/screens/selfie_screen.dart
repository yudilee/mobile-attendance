import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SelfieScreen extends StatefulWidget {
  final void Function(String base64) onConfirm;
  final VoidCallback onCancel;

  const SelfieScreen({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<SelfieScreen> createState() => _SelfieScreenState();
}

class _SelfieScreenState extends State<SelfieScreen> {
  File? _imageFile;
  String? _base64Image;
  bool _isLoading = false;

  Future<void> _captureSelfie() async {
    final picker = ImagePicker();
    setState(() => _isLoading = true);

    try {
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 640,
        maxHeight: 480,
        imageQuality: 70,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        final base64 = base64Encode(bytes);

        setState(() {
          _imageFile = File(photo.path);
          _base64Image = base64;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture selfie: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmSelfie() {
    if (_base64Image != null) {
      widget.onConfirm(_base64Image!);
    }
  }

  void _retake() {
    setState(() {
      _imageFile = null;
      _base64Image = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          widget.onCancel();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text('Take Selfie'),
          backgroundColor: const Color(0xFF009CA6),
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: widget.onCancel,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ── Instructions ───────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Please take a clear selfie to verify your identity before punching.',
                        style: TextStyle(fontSize: 13, color: Colors.blue, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Selfie Preview ─────────────────────────────────────────────
              Expanded(
                child: Center(
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            _imageFile!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image,
                              size: 80,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300, width: 2, strokeAlign: BorderSide.strokeAlignInside),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                'No selfie captured yet',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Action Buttons ─────────────────────────────────────────────
              Row(
                children: [
                  if (_imageFile != null) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _retake,
                        icon: const Icon(Icons.refresh),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFF009CA6)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        label: const Text('Retake', style: TextStyle(color: Color(0xFF009CA6))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _confirmSelfie,
                        icon: const Icon(Icons.check_circle),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF009CA6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        label: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ] else
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _captureSelfie,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.camera_alt),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF009CA6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        label: Text(
                          _isLoading ? 'Opening Camera...' : '📸 Capture Selfie',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
