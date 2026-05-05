import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/punch_provider.dart';
import '../../providers/network_sync_provider.dart';
import '../../services/app_settings.dart';
import 'qr_scan_screen.dart';
import 'nfc_scan_screen.dart';
import 'selfie_screen.dart';
import 'settings_screen.dart';

class PunchTab extends ConsumerStatefulWidget {
  const PunchTab({super.key});

  @override
  ConsumerState<PunchTab> createState() => _PunchTabState();
}

class _PunchTabState extends ConsumerState<PunchTab> with WidgetsBindingObserver {
  String _employeeId = '';
  bool _isConfigured = false;
  List<String> _configGaps = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    _requestPermissionsOnStartup();
    Future.microtask(() => ref.read(networkSyncProvider).start());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadSettings();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Request location permission upfront so Android shows the dialog
  /// immediately on first launch rather than silently failing later.
  Future<void> _requestPermissionsOnStartup() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      await Geolocator.requestPermission();
    }
  }

  Future<void> _loadSettings() async {
    final id = await AppSettings.getEmployeeId();
    final configured = await AppSettings.isConfigured();
    final gaps = await AppSettings.configurationGaps();
    setState(() {
      _employeeId = id;
      _isConfigured = configured;
      _configGaps = gaps;
    });
  }

  Future<void> _openSettings() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    if (saved == true) {
      ref.read(punchStateProvider.notifier).reset();
      await _loadSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final punchState = ref.watch(punchStateProvider);
    final punchNotifier = ref.read(punchStateProvider.notifier);
    final deviceConfig = ref.watch(deviceConfigProvider);

    // ── Selfie required — show selfie capture screen ───────────────────────
    if (punchState.status == PunchStatus.selfieRequired) {
      return SelfieScreen(
        key: const ValueKey('selfie_screen'),
        onConfirm: (base64) {
          punchNotifier.setSelfieBase64(base64);
          // After selfie captured, retry the punch
          punchNotifier.retryWithQR(); // Reuses stored _lastEmployeeId/_lastPunchType
        },
        onCancel: () {
          punchNotifier.reset();
        },
      );
    }

    // ── NFC required — show NFC scan screen ─────────────────────────────────
    if (punchState.status == PunchStatus.nfcRequired &&
        punchState.expectedNfcTagData != null) {
      return NfcScanScreen(
        expectedTagData: punchState.expectedNfcTagData!,
        onSuccess: () {
          punchNotifier.markNfcVerified();
          punchNotifier.retryWithQR();
        },
        onCancel: () {
          punchNotifier.resetNfcState();
        },
      );
    }

    // ── QR required — show QR scan screen ──────────────────────────────────
    if (punchState.status == PunchStatus.qrRequired &&
        punchState.expectedQrData != null) {
      return QRScanScreen(
        expectedQrData: punchState.expectedQrData!,
        onSuccess: () {
          punchNotifier.markQRVerified();
          // After marking QR verified, retry the punch
          // The punch type is stored in the current state context
          // We re-trigger through the provider
          punchNotifier.retryWithQR();
        },
        onCancel: () {
          punchNotifier.resetQRState();
        },
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Punch'),
        actions: [
          // Pending punch count badge
          ref.watch(pendingPunchCountProvider).when(
            data: (count) => count > 0
              ? Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.cloud_off),
                      tooltip: '$count punch(es) pending sync',
                      onPressed: () => ref.read(networkSyncProvider).syncOfflinePunches(),
                    ),
                    Positioned(
                      right: 6, top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Status',
            onPressed: () => ref.invalidate(deviceConfigProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Sync progress bar
          _SyncBar(syncState: ref.watch(syncStateProvider)),
          Expanded(
            child: Container(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            deviceConfig.when(
              data: (config) {
                final branchesList = config['branches'] as List<dynamic>?;
                final firstBranch = branchesList != null && branchesList.isNotEmpty
                    ? branchesList[0] as Map<String, dynamic>
                    : null;
                return _HeaderWidget(
                  employeeId: _employeeId.isEmpty ? 'Not configured' : _employeeId,
                  isConfigured: _isConfigured,
                  onSetupTap: _openSettings,
                  branches: branchesList
                      ?.map((b) => (b as Map<String, dynamic>)['name'] as String)
                      .toList(),
                  branchName: firstBranch?['name'] as String? ?? config['branch_name'] as String?,
                  deviceCount: config['device_count'] as int?,
                  maxDevices: config['max_devices'] as int?,
                );
              },
              loading: () => _HeaderWidget(
                employeeId: _employeeId,
                isConfigured: _isConfigured,
                onSetupTap: _openSettings,
              ),
              error: (err, _) => _HeaderWidget(
                employeeId: _employeeId,
                isConfigured: _isConfigured,
                onSetupTap: _openSettings,
                branchName: 'Connection Error',
              ),
            ),
            const Spacer(),

            // Config / Branch Status logic
            if (!_isConfigured)
              _NotConfiguredCard(onSetupTap: _openSettings, gaps: _configGaps)
            else if (deviceConfig.isLoading && !deviceConfig.hasValue && !deviceConfig.hasError) 
              const Center(child: CircularProgressIndicator(color: Color(0xFF009CA6)))
            else if (deviceConfig.hasValue && deviceConfig.value?['status'] == 'pending_approval')
              _PendingAssignmentCard(message: deviceConfig.value?['message'] ?? 'Waiting for admin approval. Contact HR.')
            else if (deviceConfig.hasValue && deviceConfig.value?['status'] == 'pending_branch')
              _PendingAssignmentCard(message: deviceConfig.value?['message'] ?? 'Approved! Waiting for branch assignment.')
            else if (deviceConfig.hasValue && deviceConfig.value?['status'] == 'max_devices_reached')
              _MaxDevicesReachedCard(
                message: deviceConfig.value?['message'] ?? 'Maximum devices reached.',
                deviceCount: deviceConfig.value?['device_count'] ?? 0,
                maxDevices: deviceConfig.value?['max_devices'] ?? 5,
              )
            else if (punchState.status == PunchStatus.error &&
                (punchState.errorMessage?.toLowerCase().contains('rooted/jailbroken') == true ||
                 punchState.errorMessage?.toLowerCase().contains('compromised') == true))
              _DeviceCompromisedBanner(
                message: punchState.errorMessage ?? 'Device compromised.',
                onDismiss: () => ref.read(punchStateProvider.notifier).reset(),
              )
            else
              Builder(
                builder: (context) {
                  return Column(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: deviceConfig.hasError
                          ? Container(
                              key: const ValueKey('offline_banner'),
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange.shade300),
                                boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: Colors.orange.shade100, shape: BoxShape.circle),
                                    child: const Icon(Icons.wifi_off, color: Colors.orange, size: 20),
                                  ),
                                  const SizedBox(width: 16),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Offline Mode', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16)),
                                        Text('Punches will be saved locally and synced later.', style: TextStyle(color: Colors.orange, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(key: ValueKey('online_banner')),
                      ),
                      ref.watch(punchTypesProvider).when(
                        data: (punchTypes) {
                          if (punchTypes.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text('No punch types available. Please sync.', style: TextStyle(color: Colors.grey)),
                            );
                          }
                          return Column(
                            children: punchTypes.map((pt) {
                              final isOut = pt.code.toLowerCase().contains('out');
                              final color = isOut ? Colors.red.shade600 : Theme.of(context).colorScheme.primary;
                              final icon = isOut ? Icons.logout_rounded : Icons.login_rounded;
                              final isLoading = punchState.status == PunchStatus.loading;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _PunchButton(
                                  label: pt.label.toUpperCase(),
                                  icon: icon,
                                  color: color,
                                  enabled: !isLoading,
                                  loading: isLoading,
                                  onPressed: () => punchNotifier.performPunch(_employeeId, pt.code),
                                ),
                              );
                            }).toList(),
                          );
                        },
                        loading: () => const CircularProgressIndicator(color: Color(0xFF009CA6)),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Attempting to sync offline data...')),
                          );
                          ref.read(networkSyncProvider).syncOfflinePunches();
                        },
                        icon: const Icon(Icons.sync),
                        label: const Text('Sync Offline Data'),
                        style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary),
                      ),
                    ],
                  );
                },
              ),

            const Spacer(),
            _StatusFeedback(
              state: punchState,
              onDismiss: () => ref.read(punchStateProvider.notifier).reset(),
            ),
          ],
        ),
      ),
          ), // Expanded
        ], // Column children
      ), // Column
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SyncBar extends StatelessWidget {
  final SyncState syncState;
  const _SyncBar({required this.syncState});

  @override
  Widget build(BuildContext context) {
    if (syncState.status == SyncStatus.idle && syncState.pendingCount == 0) {
      return const SizedBox.shrink();
    }

    final String text;
    final Color color;
    final bool showProgress;

    switch (syncState.status) {
      case SyncStatus.syncing:
        text = 'Syncing... ${syncState.pendingCount} remaining';
        color = Colors.blue;
        showProgress = true;
      case SyncStatus.allSynced:
        text = 'All punches synced';
        color = Colors.green;
        showProgress = false;
      case SyncStatus.error:
        text = syncState.lastError ?? 'Sync error';
        color = Colors.red;
        showProgress = false;
      default:
        text = '${syncState.pendingCount} punch(es) waiting to sync';
        color = Colors.orange;
        showProgress = false;
    }

    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border(bottom: BorderSide(color: color.withOpacity(0.3))),
      ),
      child: Row(
        children: [
          if (showProgress)
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: SizedBox(
                width: 12, height: 12,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              ),
            ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _HeaderWidget extends StatelessWidget {
  final String employeeId;
  final bool isConfigured;
  final VoidCallback onSetupTap;
  final List<String>? branches;
  final String? branchName;
  final int? deviceCount;
  final int? maxDevices;

  const _HeaderWidget({
    required this.employeeId,
    required this.isConfigured,
    required this.onSetupTap,
    this.branches,
    this.branchName,
    this.deviceCount,
    this.maxDevices,
  });

  String get _branchDisplay {
    if (branches != null && branches!.length > 1) {
      return '${branches!.first} +${branches!.length - 1} more';
    }
    return branchName ?? (isConfigured ? 'Syncing branch...' : 'Tap \u2699\uFE0F to configure');
  }

  bool get _hasValidBranch => branchName != null && branchName != 'Connection Error';

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, const Color(0xFFE0F2F1)],
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _hasValidBranch ? const Color(0xFF009CA6).withOpacity(0.2) : Colors.black12,
                    blurRadius: 10, spreadRadius: 2,
                  )
                ]
              ),
              child: CircleAvatar(
                radius: 40,
                backgroundColor: isConfigured ? const Color(0xFF009CA6) : Colors.grey.shade300,
                child: Icon(
                  isConfigured ? Icons.person : Icons.person_off,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isConfigured ? employeeId : 'Setup Required',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _hasValidBranch ? Icons.location_on : Icons.location_off,
                  size: 14,
                  color: _hasValidBranch ? const Color(0xFF009CA6) : Colors.grey,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    _branchDisplay,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: branchName == 'Connection Error' ? Colors.red : Colors.grey.shade700,
                      fontWeight: _hasValidBranch ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
            if (deviceCount != null && maxDevices != null) ...[
              const SizedBox(height: 4),
              Text(
                'Devices: $deviceCount/$maxDevices',
                style: TextStyle(
                  fontSize: 11,
                  color: deviceCount! >= maxDevices! ? Colors.red : Colors.grey.shade500,
                  fontWeight: deviceCount! >= maxDevices! ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PendingAssignmentCard extends StatelessWidget {
  final String message;
  const _PendingAssignmentCard({this.message = 'Your device is registered but not yet set up.'});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200, width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.amber.shade100, shape: BoxShape.circle),
            child: const Icon(Icons.app_registration_rounded, size: 40, color: Colors.amber),
          ),
          const SizedBox(height: 16),
          const Text('Device Not Ready', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.brown)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.brown, height: 1.4)),
        ],
      ),
    );
  }
}


class _MaxDevicesReachedCard extends StatelessWidget {
  final String message;
  final int deviceCount;
  final int maxDevices;
  const _MaxDevicesReachedCard({
    required this.message,
    required this.deviceCount,
    required this.maxDevices,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade300, width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.red.shade100, shape: BoxShape.circle),
            child: const Icon(Icons.devices, size: 40, color: Colors.red),
          ),
          const SizedBox(height: 16),
          const Text('Device Limit Reached', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, height: 1.4)),
          const SizedBox(height: 8),
          Text(
            'You have $deviceCount of $maxDevices allowed devices.',
            style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _NotConfiguredCard extends StatelessWidget {
  final VoidCallback onSetupTap;
  final List<String> gaps;
  const _NotConfiguredCard({required this.onSetupTap, this.gaps = const []});

  @override
  Widget build(BuildContext context) {
    final steps = <_SetupStep>[
      _SetupStep(
        icon: Icons.badge,
        label: 'Employee ID',
        done: !gaps.contains('Employee ID'),
      ),
      _SetupStep(
        icon: Icons.dns,
        label: 'Server URL',
        done: !gaps.contains('Server URL'),
      ),
      _SetupStep(
        icon: Icons.key,
        label: 'API Key',
        done: !gaps.contains('API Key'),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade300, width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.orange.shade100, shape: BoxShape.circle),
                child: const Icon(Icons.warning_amber_rounded, size: 28, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Setup Required', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    Text('Complete these steps to start clocking in', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...steps.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(s.done ? Icons.check_circle : Icons.radio_button_unchecked, size: 18, color: s.done ? Colors.green : Colors.grey),
                const SizedBox(width: 8),
                Icon(s.icon, size: 16, color: s.done ? Colors.green : Colors.grey),
                const SizedBox(width: 8),
                Text(s.label, style: TextStyle(fontSize: 14, color: s.done ? Colors.green.shade700 : Colors.grey.shade700, fontWeight: s.done ? FontWeight.w600 : FontWeight.normal)),
                const Spacer(),
                if (s.done)
                  const Text('Done', style: TextStyle(fontSize: 11, color: Colors.green)),
              ],
            ),
          )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSetupTap,
              icon: const Icon(Icons.settings, size: 18),
              label: const Text('Complete Setup'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupStep {
  final IconData icon;
  final String label;
  final bool done;
  const _SetupStep({required this.icon, required this.label, required this.done});
}

class _PunchButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool enabled;
  final bool loading;

  const _PunchButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.enabled = true,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled ? color : Colors.grey;
    final gradient = LinearGradient(
      colors: [effectiveColor, effectiveColor.withBlue((effectiveColor.blue + 30).clamp(0, 255))],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      width: double.infinity,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: effectiveColor.withOpacity(enabled ? 0.3 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled && !loading ? onPressed : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 28, height: 28,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    loading ? 'Processing...' : label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                if (!loading)
                  const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusFeedback extends StatefulWidget {
  final PunchState state;
  final VoidCallback onDismiss;

  const _StatusFeedback({
    required this.state,
    required this.onDismiss,
  });

  @override
  State<_StatusFeedback> createState() => _StatusFeedbackState();
}

class _StatusFeedbackState extends State<_StatusFeedback> {
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _maybeStartTimer();
  }

  @override
  void didUpdateWidget(covariant _StatusFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state != oldWidget.state) {
      _maybeStartTimer();
    }
  }

  void _maybeStartTimer() {
    _autoDismissTimer?.cancel();
    final status = widget.state.status;
    if (status == PunchStatus.success || status == PunchStatus.offline) {
      _autoDismissTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) widget.onDismiss();
      });
    }
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    if (state.status == PunchStatus.idle || state.status == PunchStatus.loading) {
      return const SizedBox.shrink();
    }

    final isSuccess = state.status == PunchStatus.success;
    final isOffline = state.status == PunchStatus.offline;
    final isError = state.status == PunchStatus.error;

    String displayTime = '';
    if (isSuccess && state.result?['server_time'] != null) {
      try {
        String rawTime = state.result!['server_time'].toString();
        if (!rawTime.endsWith('Z') && !rawTime.contains('+')) {
          rawTime += 'Z';
        }
        final local = DateTime.parse(rawTime).toLocal();
        displayTime = "${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} "
            "${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}:${local.second.toString().padLeft(2, '0')}";
      } catch (e) {
        displayTime = state.result!['server_time'].toString().replaceAll('T', ' ').split('.').first;
      }
    }

    Color bgColor = Colors.red.shade50;
    Color borderColor = Colors.red;
    Color textColor = Colors.red.shade900;
    IconData icon = Icons.error;
    String mainText = 'Error: ${state.errorMessage}';

    if (isSuccess) {
      bgColor = Colors.green.shade50;
      borderColor = Colors.green;
      textColor = Colors.green.shade900;
      icon = Icons.check_circle;
      mainText = 'Attendance Recorded';
    } else if (isOffline) {
      bgColor = Colors.orange.shade50;
      borderColor = Colors.orange;
      textColor = Colors.orange.shade900;
      icon = Icons.cloud_done;
      mainText = state.result?['message'] ?? 'Saved offline. Will sync later.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: borderColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mainText,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isSuccess && displayTime.isNotEmpty)
                      Text(
                        'Local time: $displayTime',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.onDismiss,
                icon: const Icon(Icons.close, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: borderColor,
              ),
            ],
          ),
          if (isError) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: widget.onDismiss,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Try Again', style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: borderColor,
                side: BorderSide(color: borderColor),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DeviceCompromisedBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _DeviceCompromisedBanner({
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade400, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.gpp_bad,
              size: 48,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'DEVICE COMPROMISED',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.red,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onDismiss,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Dismiss'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
