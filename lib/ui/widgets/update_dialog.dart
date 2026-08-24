import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/update_service.dart';
import '../theme.dart';

class UpdateDialog extends StatelessWidget {
  final AppUpdateInfo update;

  const UpdateDialog({super.key, required this.update});

  static Future<void> show(BuildContext context, AppUpdateInfo update) async {
    return showDialog(
      context: context,
      barrierDismissible: !update.isForced,
      builder: (ctx) => PopScope(
        canPop: !update.isForced,
        child: UpdateDialog(update: update),
      ),
    );
  }

  Future<void> _launchDownload(BuildContext context) async {
    final urlStr = update.downloadUrl.trim();
    if (urlStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download URL is not configured on the server.')),
      );
      return;
    }

    try {
      final uri = Uri.parse(urlStr);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      try {
        final uri = Uri.parse(urlStr);
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (err) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open download link: $err')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.glassDecoration(context: context, borderRadius: 24).copyWith(
          border: Border.all(
            color: update.isForced
                ? AppTheme.accentOrange.withOpacity(0.5)
                : AppTheme.primaryCyan.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon & Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (update.isForced ? AppTheme.accentOrange : AppTheme.primaryCyan).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (update.isForced ? AppTheme.accentOrange : AppTheme.primaryCyan).withOpacity(0.3),
                    ),
                  ),
                  child: Icon(
                    update.isForced ? Icons.system_security_update_warning_rounded : Icons.system_update_rounded,
                    color: update.isForced ? AppTheme.accentOrange : AppTheme.primaryCyan,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        update.title,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'v${update.currentVersion}',
                              style: TextStyle(
                                color: isDark ? Colors.white60 : Colors.black54,
                                fontSize: 11,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.grey),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.successGreen.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.successGreen.withOpacity(0.4)),
                            ),
                            child: Text(
                              'v${update.latestVersion}',
                              style: const TextStyle(
                                color: AppTheme.successGreen,
                                fontSize: 11,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Enforced warning banner if mandatory
            if (update.isForced) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accentOrange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.accentOrange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This update is required to ensure compatibility with server attendance policies.',
                        style: TextStyle(
                          color: isDark ? Colors.orange.shade200 : Colors.orange.shade900,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Changelog Box
            Text(
              "What's New in this Version:",
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withOpacity(0.4) : Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                ),
              ),
              child: SingleChildScrollView(
                child: Text(
                  update.changelog.isNotEmpty
                      ? update.changelog
                      : '• Performance improvements and stability enhancements.',
                  style: TextStyle(
                    color: isDark ? Colors.white.withOpacity(0.85) : Colors.black87,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            if (update.isForced)
              ElevatedButton.icon(
                onPressed: () => _launchDownload(context),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Update Now (Required)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        await UpdateService.skipVersion(update.latestVersion);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? Colors.white60 : Colors.black54,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Later', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _launchDownload(context),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Update Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryCyan,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
