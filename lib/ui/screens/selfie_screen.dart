import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _SelfieScreenState extends State<SelfieScreen> with SingleTickerProviderStateMixin {
  File? _imageFile;
  String? _base64Image;
  bool _isLoading = false;

  // Quality validation state
  double? _luminance;
  double? _variance;
  String? _validationError;
  bool _isQualityPassed = false;

  // Animation controller for the looping neon scan line
  late AnimationController _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _scannerController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  /// Extremely performant on-device image analysis using Dart's native image codecs.
  /// Downscales to 160x120 to calculate mean luminance and Laplacian pixel variance.
  Future<Map<String, dynamic>> _analyzeImageQuality(Uint8List bytes) async {
    try {
      final ui.Codec codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 160,
        targetHeight: 120,
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) {
        throw Exception("Failed to extract raw RGBA byte buffer.");
      }

      final Uint8List rgbaBytes = byteData.buffer.asUint8List();
      final int totalPixels = image.width * image.height;
      final int width = image.width;
      final int height = image.height;

      double sumLuminance = 0;
      final List<double> luminances = List<double>.filled(totalPixels, 0.0);

      // 1. Calculate luminance for each pixel
      for (int i = 0; i < totalPixels; i++) {
        final int r = rgbaBytes[i * 4];
        final int g = rgbaBytes[i * 4 + 1];
        final int b = rgbaBytes[i * 4 + 2];
        // ITU BT.601 standard weights for luminance calculation
        final double y = 0.299 * r + 0.587 * g + 0.114 * b;
        luminances[i] = y;
        sumLuminance += y;
      }

      final double meanLuminance = sumLuminance / totalPixels;

      // 2. Calculate spatial variance of adjacent pixel differences (horizontal & vertical)
      double sumDiffSq = 0;
      int diffCount = 0;

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int idx = y * width + x;
          final double current = luminances[idx];

          if (x < width - 1) {
            final double right = luminances[idx + 1];
            final double diff = current - right;
            sumDiffSq += diff * diff;
            diffCount++;
          }
          if (y < height - 1) {
            final double down = luminances[idx + width];
            final double diff = current - down;
            sumDiffSq += diff * diff;
            diffCount++;
          }
        }
      }

      final double variance = diffCount > 0 ? (sumDiffSq / diffCount) : 0.0;

      return {
        'success': true,
        'luminance': meanLuminance,
        'variance': variance,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<void> _captureSelfie() async {
    final picker = ImagePicker();
    setState(() => _isLoading = true);

    try {
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 640,
        maxHeight: 480,
        imageQuality: 75,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();

        if (!mounted) return;
        setState(() {
          _isLoading = true;
        });

        // Haptic feedback to indicate capture success and starting processing
        HapticFeedback.mediumImpact();

        final analysis = await _analyzeImageQuality(bytes);

        if (!mounted) return;

        final double luminance = analysis['luminance'] ?? 0.0;
        final double variance = analysis['variance'] ?? 0.0;

        String? validationError;
        bool isPassed = true;

        if (!analysis['success']) {
          validationError = "Failed to analyze image quality: ${analysis['error']}";
          isPassed = false;
        } else if (luminance < 40) {
          validationError = "Photo is too dark (${luminance.toStringAsFixed(1)} < 40.0). Please move to a brighter spot.";
          isPassed = false;
        } else if (luminance > 240) {
          validationError = "Photo is too bright (${luminance.toStringAsFixed(1)} > 240.0). Avoid direct strong light sources.";
          isPassed = false;
        } else if (variance < 50.0) {
          validationError = "Photo is blurry or lacks detail (Detail Index: ${variance.toStringAsFixed(1)} < 50.0). Hold the camera steady and retake.";
          isPassed = false;
        }

        final base64 = base64Encode(bytes);

        // Tactile vibration alert if the verification checks fail
        if (!isPassed) {
          HapticFeedback.heavyImpact();
        } else {
          HapticFeedback.lightImpact();
        }

        setState(() {
          _imageFile = File(photo.path);
          _base64Image = base64;
          _luminance = luminance;
          _variance = variance;
          _validationError = validationError;
          _isQualityPassed = isPassed;
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
            backgroundColor: const Color(0xFFFF3D00),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _confirmSelfie() {
    if (_base64Image != null && _isQualityPassed) {
      HapticFeedback.mediumImpact();
      widget.onConfirm(_base64Image!);
    }
  }

  void _retake() {
    HapticFeedback.lightImpact();
    setState(() {
      _imageFile = null;
      _base64Image = null;
      _luminance = null;
      _variance = null;
      _validationError = null;
      _isQualityPassed = false;
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
        backgroundColor: const Color(0xFF0F131E), // Deep luxury dark mode
        appBar: AppBar(
          title: const Text(
            'Facial Verification',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              fontSize: 20,
            ),
          ),
          backgroundColor: const Color(0xFF161C2C),
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, size: 26),
            onPressed: widget.onCancel,
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // ── Instructions Banner ───────────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _imageFile != null
                        ? (_isQualityPassed
                            ? const Color(0xFF00C853).withOpacity(0.1)
                            : const Color(0xFFFF3D00).withOpacity(0.1))
                        : const Color(0xFF00B0FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _imageFile != null
                          ? (_isQualityPassed
                              ? const Color(0xFF00C853).withOpacity(0.4)
                              : const Color(0xFFFF3D00).withOpacity(0.4))
                          : const Color(0xFF00B0FF).withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _imageFile != null
                            ? (_isQualityPassed
                                ? Icons.verified_user_rounded
                                : Icons.warning_amber_rounded)
                            : Icons.face_retouching_natural_rounded,
                        color: _imageFile != null
                            ? (_isQualityPassed ? const Color(0xFF00E676) : const Color(0xFFFF8A80))
                            : const Color(0xFF40C4FF),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _imageFile != null
                              ? (_isQualityPassed
                                  ? 'Selfie quality checks verified successfully!'
                                  : 'Biometric scan failed. Check requirement details.')
                              : 'Keep your face clearly lit, looking straight, and hold steady.',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: _imageFile != null
                                ? (_isQualityPassed ? const Color(0xFFCCFF90) : const Color(0xFFFFD180))
                                : const Color(0xFF80D8FF),
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Interactive Preview & Silhouette Overlay ──────────────────
                Expanded(
                  child: Center(
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: AspectRatio(
                              aspectRatio: 3 / 4,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Raw image preview
                                  Image.file(
                                    _imageFile!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(
                                        Icons.broken_image_rounded,
                                        size: 80,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),

                                  // Glowing futuristic scanning silhouette overlay
                                  AnimatedBuilder(
                                    animation: _scannerController,
                                    builder: (context, child) {
                                      return CustomPaint(
                                        painter: SilhouettePainter(
                                          scanProgress: _scannerController.value,
                                          isSuccess: _isQualityPassed,
                                        ),
                                      );
                                    },
                                  ),

                                  // Status tag in preview
                                  Positioned(
                                    top: 16,
                                    right: 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: (_isQualityPassed
                                                ? const Color(0xFF00C853)
                                                : const Color(0xFFFF3D00))
                                            .withOpacity(0.85),
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: _isQualityPassed
                                              ? const Color(0xFF00FF66)
                                              : const Color(0xFFFF8A80),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _isQualityPassed
                                                ? Icons.check_circle_outline_rounded
                                                : Icons.error_outline_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _isQualityPassed ? 'PASSED' : 'REJECTED',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF161C2C),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFF26324D),
                                width: 2,
                                strokeAlign: BorderSide.strokeAlignInside,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Glowing camera icon wrapper
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00B0FF).withOpacity(0.08),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF00B0FF).withOpacity(0.2),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.photo_camera_front_rounded,
                                    size: 64,
                                    color: Color(0xFF40C4FF),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Ready to capture selfie',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Align your face inside the verification overlay',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF6B7A99),
                                    fontSize: 13.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Detailed Diagnostic Indicators ────────────────────────────
                if (_imageFile != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161C2C),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF26324D)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Diagnostic title
                        Row(
                          children: [
                            const Text(
                              'Verification Diagnostic Metrics',
                              style: TextStyle(
                                color: Color(0xFF90A4AE),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _isQualityPassed ? 'Approved' : 'Failed',
                              style: TextStyle(
                                color: _isQualityPassed ? const Color(0xFF00E676) : const Color(0xFFFF5252),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Metric 1: Luminance
                        _buildMetricRow(
                          label: 'Brightness/Luminance',
                          value: _luminance != null ? '${_luminance!.toStringAsFixed(1)} / 255' : 'Pending',
                          isPassed: _luminance != null && _luminance! >= 40 && _luminance! <= 240,
                          progress: _luminance != null ? (_luminance! / 255.0).clamp(0.0, 1.0) : 0,
                          accentColor: const Color(0xFFFFD740),
                        ),
                        const SizedBox(height: 14),

                        // Metric 2: Variance
                        _buildMetricRow(
                          label: 'Detail/Edge Variance',
                          value: _variance != null ? _variance!.toStringAsFixed(1) : 'Pending',
                          isPassed: _variance != null && _variance! >= 50.0,
                          progress: _variance != null ? (_variance! / 150.0).clamp(0.0, 1.0) : 0,
                          accentColor: const Color(0xFF29B6F6),
                        ),

                        if (_validationError != null) ...[
                          const SizedBox(height: 12),
                          const Divider(color: Color(0xFF26324D), height: 1),
                          const SizedBox(height: 12),
                          Text(
                            _validationError!,
                            style: const TextStyle(
                              color: Color(0xFFFF5252),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Beautiful Premium Control Buttons ─────────────────────────
                Row(
                  children: [
                    if (_imageFile != null) ...[
                      // Retake button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _retake,
                          icon: const Icon(Icons.refresh_rounded, size: 20),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Color(0xFF26324D), width: 1.5),
                            backgroundColor: const Color(0xFF161C2C),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            foregroundColor: const Color(0xFF90A4AE),
                          ),
                          label: const Text(
                            'Retake',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Confirm button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isQualityPassed ? _confirmSelfie : null,
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C853),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFF1A382B),
                            disabledForegroundColor: Colors.white.withOpacity(0.2),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: _isQualityPassed ? 8 : 0,
                            shadowColor: const Color(0xFF00C853).withOpacity(0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          label: const Text(
                            'Confirm',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ] else
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00B0FF).withOpacity(0.2),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _captureSelfie,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                : const Icon(Icons.camera_alt_rounded, size: 22),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00B0FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            label: Text(
                              _isLoading ? 'Starting camera stream...' : '📸 Open Selfie Camera',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
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
      ),
    );
  }

  Widget _buildMetricRow({
    required String label,
    required String value,
    required bool isPassed,
    required double progress,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                color: isPassed ? const Color(0xFF00E676) : const Color(0xFFFF5252),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              isPassed ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isPassed ? const Color(0xFF00E676) : const Color(0xFFFF5252),
              size: 16,
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFF26324D),
            valueColor: AlwaysStoppedAnimation<Color>(
              isPassed ? accentColor : const Color(0xFFFF5252),
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class SilhouettePainter extends CustomPainter {
  final double scanProgress;
  final bool isSuccess;

  SilhouettePainter({
    required this.scanProgress,
    required this.isSuccess,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Semi-translucent dark background overlay
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // 2. Head silhouette oval
    final center = Offset(size.width / 2, size.height / 2);
    final ovalWidth = size.width * 0.72;
    final ovalHeight = size.height * 0.65;
    final ovalRect = Rect.fromCenter(
      center: center,
      width: ovalWidth,
      height: ovalHeight,
    );

    // Subtract the oval from the dark background
    final path = Path()..addRect(rect);
    final ovalPath = Path()..addOval(ovalRect);

    final maskPath = Path.combine(
      PathOperation.difference,
      path,
      ovalPath,
    );

    canvas.drawPath(maskPath, backgroundPaint);

    // 3. Oval border (glowing color depending on quality)
    final borderPaint = Paint()
      ..color = isSuccess ? const Color(0xFF00C853) : const Color(0xFFFF3D00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawOval(ovalRect, borderPaint);

    // Glowing shadow for the oval
    final shadowPaint = Paint()
      ..color = (isSuccess ? const Color(0xFF00C853) : const Color(0xFFFF3D00)).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(ovalRect, shadowPaint);

    // 4. Scanning laser line (vertical loop inside the oval bounds)
    final scanY = ovalRect.top + (ovalRect.height * scanProgress);

    // We only draw the scanning line inside the oval. So we clip to the oval path.
    canvas.save();
    canvas.clipPath(ovalPath);

    final laserPaint = Paint()
      ..color = isSuccess ? const Color(0xFF00FF66) : const Color(0xFFFF5252)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Glowing laser line shadow
    final laserShadowPaint = Paint()
      ..color = (isSuccess ? const Color(0xFF00FF66) : const Color(0xFFFF5252)).withOpacity(0.4)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Draw scanning laser bar
    canvas.drawLine(
      Offset(ovalRect.left, scanY),
      Offset(ovalRect.right, scanY),
      laserPaint,
    );

    canvas.drawRect(
      Rect.fromLTRB(ovalRect.left, scanY - 3, ovalRect.right, scanY + 3),
      laserShadowPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SilhouettePainter oldDelegate) {
    return oldDelegate.scanProgress != scanProgress || oldDelegate.isSuccess != isSuccess;
  }
}
