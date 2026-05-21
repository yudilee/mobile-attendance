import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/punch_provider.dart';
import '../../providers/network_sync_provider.dart';
import '../../services/app_settings.dart';
import '../theme.dart';
import 'qr_scan_screen.dart';
import 'nfc_scan_screen.dart';
import 'selfie_screen.dart';
import 'settings_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/biometric_session_timer.dart';

class PunchTab extends ConsumerStatefulWidget {
  const PunchTab({super.key});

  @override
  ConsumerState<PunchTab> createState() => _PunchTabState();
}

class _PunchTabState extends ConsumerState<PunchTab> with WidgetsBindingObserver {
  String _employeeId = '';
  bool _isConfigured = false;
  List<String> _configGaps = [];
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    _requestPermissionsOnStartup().then((_) {
      _startLocationUpdates();
    });
    Future.microtask(() => ref.read(networkSyncProvider).start());
  }

  void _startLocationUpdates() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // update every 5m for more responsive geofence badge
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadSettings();
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
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

  /// Haversine distance in meters between two GPS coordinates.
  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0; // Earth radius in meters
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) * math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _toRad(double deg) => deg * math.pi / 180.0;

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
          // Header Widget (Moved to the very top, out of map)
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
                branches: branchesList?.map((b) => (b as Map<String, dynamic>)['name'] as String).toList(),
                branchName: firstBranch?['name'] as String? ?? config['branch_name'] as String?,
                deviceCount: config['device_count'] as int?,
                maxDevices: config['max_devices'] as int?,
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Sync progress bar
          _SyncBar(syncState: ref.watch(syncStateProvider)),
          
          // Map View (Glassmorphism Container)
          deviceConfig.when(
            data: (config) {
              final branchesList = config['branches'] as List<dynamic>?;
              final firstBranch = branchesList != null && branchesList.isNotEmpty
                  ? branchesList[0] as Map<String, dynamic>
                  : null;
              
              double? branchLat = firstBranch?['lat'] as double? ?? config['lat'] as double?;
              double? branchLng = firstBranch?['lng'] as double? ?? config['lng'] as double?;
              double? radius = firstBranch?['radius'] as double? ?? config['radius'] as double?;
              
              return Container(
                height: 350,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0x331E293B),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, spreadRadius: -5),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      FlutterMap(
                        options: MapOptions(
                          initialCenter: branchLat != null && branchLng != null
                              ? LatLng(branchLat, branchLng)
                              : (_currentPosition != null ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude) : const LatLng(0, 0)),
                          initialZoom: 16.0,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.all, // ← fully interactive
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: Theme.of(context).brightness == Brightness.dark
                                ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                                : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                            subdomains: const ['a', 'b', 'c'],
                            userAgentPackageName: 'com.example.app',
                          ),
                          if (branchLat != null && branchLng != null)
                            CircleLayer(
                              circles: [
                                CircleMarker(
                                  point: LatLng(branchLat, branchLng),
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderStrokeWidth: 1,
                                  borderColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                  useRadiusInMeter: true,
                                  radius: radius ?? 50.0,
                                ),
                              ],
                            ),
                          if (_currentPosition != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                  width: 40,
                                  height: 40,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
                                      boxShadow: [
                                        BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.5), blurRadius: 10, spreadRadius: 4),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      // Gradient overlay at the bottom for text
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('GPS Accuracy', style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
                                  Text(
                                    _currentPosition != null
                                        ? '± ${_currentPosition!.accuracy.toStringAsFixed(0)} m'
                                        : 'Acquiring...',
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Timezone', style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
                                  Text(
                                    DateTime.now().timeZoneName,
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                      // Top Badge — live geofence status
                      Positioned(
                        top: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Builder(builder: (ctx) {
                            // Calculate live distance from current position to branch
                            String badgeText = 'Locating...';
                            Color badgeColor = Colors.grey;
                            IconData badgeIcon = Icons.location_searching;

                            if (_currentPosition != null && branchLat != null && branchLng != null) {
                              final distanceM = _haversineDistance(
                                _currentPosition!.latitude, _currentPosition!.longitude,
                                branchLat, branchLng,
                              );
                              final r = radius ?? 50.0;
                              if (distanceM <= r) {
                                badgeText = '✓ Inside Geofence (${distanceM.toStringAsFixed(0)}m from center)';
                                badgeColor = AppTheme.successGreen;
                                badgeIcon = Icons.check_circle_outline;
                              } else if (distanceM <= r * 1.3) {
                                badgeText = '⚠ Near boundary (${distanceM.toStringAsFixed(0)}m / ${r.toStringAsFixed(0)}m)';
                                badgeColor = Colors.orange;
                                badgeIcon = Icons.warning_amber_outlined;
                              } else {
                                badgeText = '✗ Outside Geofence (${distanceM.toStringAsFixed(0)}m away)';
                                badgeColor = AppTheme.errorRed;
                                badgeIcon = Icons.location_off_outlined;
                              }
                            }

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: badgeColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: badgeColor.withOpacity(0.6)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(badgeIcon, size: 14, color: badgeColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    badgeText,
                                    style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SizedBox(height: 350, child: Center(child: CircularProgressIndicator())),
            error: (err, _) => SizedBox(
              height: 350,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_off, size: 40, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text('Could not load map config', style: TextStyle(color: Colors.grey.shade400)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(deviceConfigProvider),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          Expanded(
            child: Container(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                      if (punchState.lastBiometricAuthTime != null && punchState.biometricSessionSeconds > 0)
                        BiometricSessionTimer(
                          lastAuthTime: punchState.lastBiometricAuthTime!,
                          sessionSeconds: punchState.biometricSessionSeconds,
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
                      const SizedBox(height: 16),
                      // GPS and Sync Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.circle, size: 8, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text('GPS Signal Strong', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_off, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 8),
                          Text('Offline Mode Active (Pending Sync)', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text('\u00A9 2024 IT Dept HRM Group', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),

            const Spacer(),
            _StatusFeedback(
              state: punchState,
              onDismiss: () => ref.read(punchStateProvider.notifier).reset(),
              onRetry: () {
                ref.read(punchStateProvider.notifier).reset();
                ref.read(punchStateProvider.notifier).retryWithQR();
              },
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
              image: const DecorationImage(
                image: AssetImage('assets/images/avatar_placeholder.png'), // Add a placeholder image or icon
                fit: BoxFit.cover,
              ),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: isConfigured ? null : const Icon(Icons.person_off, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConfigured ? employeeId : 'Setup Required',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      _hasValidBranch ? Icons.location_on : Icons.location_off,
                      size: 14,
                      color: _hasValidBranch ? Theme.of(context).colorScheme.primary : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _branchDisplay,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: branchName == 'Connection Error' ? Colors.red : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          )
        ],
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
      decoration: AppTheme.glassDecoration(borderRadius: 16).copyWith(
        color: Colors.orange.withOpacity(0.08),
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.app_registration_rounded, size: 40, color: Colors.orange),
          ),
          const SizedBox(height: 16),
          const Text('Device Pending Setup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade300, height: 1.4, fontSize: 14)),
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
      decoration: AppTheme.glassDecoration(borderRadius: 16).copyWith(
        color: AppTheme.errorRed.withOpacity(0.08),
        border: Border.all(color: AppTheme.errorRed.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.errorRed.withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.devices, size: 40, color: AppTheme.errorRed),
          ),
          const SizedBox(height: 16),
          const Text('Device Limit Reached', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade300, height: 1.4, fontSize: 14)),
          const SizedBox(height: 12),
          Text(
            'Active Devices: $deviceCount / $maxDevices',
            style: const TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold, fontSize: 15),
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
      decoration: AppTheme.glassDecoration(borderRadius: 20).copyWith(
        color: Colors.orange.withOpacity(0.08),
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), shape: BoxShape.circle),
                child: const Icon(Icons.warning_amber_rounded, size: 28, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Setup Required', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
                    SizedBox(height: 2),
                    Text('Complete these steps to start clocking in', style: TextStyle(fontSize: 13, color: Colors.white70)),
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
                Icon(s.done ? Icons.check_circle : Icons.radio_button_unchecked, size: 18, color: s.done ? AppTheme.successGreen : Colors.white38),
                const SizedBox(width: 8),
                Icon(s.icon, size: 16, color: s.done ? AppTheme.successGreen : Colors.white38),
                const SizedBox(width: 8),
                Text(s.label, style: TextStyle(fontSize: 14, color: s.done ? AppTheme.successGreen : Colors.white70, fontWeight: s.done ? FontWeight.w600 : FontWeight.normal)),
                const Spacer(),
                if (s.done)
                  const Text('Done', style: TextStyle(fontSize: 11, color: AppTheme.successGreen, fontWeight: FontWeight.bold)),
              ],
            ),
          )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSetupTap,
              icon: const Icon(Icons.settings, size: 18),
              label: const Text('Complete Setup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

class _PunchButton extends StatefulWidget {
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
  State<_PunchButton> createState() => _PunchButtonState();
}

class _PunchButtonState extends State<_PunchButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enabled && !widget.loading) {
      _controller.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enabled && !widget.loading) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.enabled && !widget.loading) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOut = widget.label.toLowerCase().contains('out');
    final primary = Theme.of(context).colorScheme.primary;
    
    // Glassmorphism styling based on button type
    final border = isOut ? Border.all(color: Colors.transparent) : Border.all(color: primary.withOpacity(0.5), width: 1.5);
    final bgColor = isOut ? Colors.white.withOpacity(0.05) : primary.withOpacity(0.15);
    final shadow = isOut ? const BoxShadow(color: Colors.transparent) : BoxShadow(
      color: primary.withOpacity(0.2),
      blurRadius: 16,
      offset: const Offset(0, 4),
    );

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: border,
          boxShadow: [shadow],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: () {
              if (widget.enabled && !widget.loading) {
                HapticFeedback.mediumImpact();
                widget.onPressed();
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: widget.loading
                        ? const SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(widget.icon, color: isOut ? Colors.red.shade400 : primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.loading ? 'Processing...' : widget.label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (!widget.loading)
                    const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 20),
                ],
              ),
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
  final VoidCallback? onRetry;

  const _StatusFeedback({
    required this.state,
    required this.onDismiss,
    this.onRetry,
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
      // ✅ Tactile success confirmation
      HapticFeedback.heavyImpact();
      _autoDismissTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) widget.onDismiss();
      });
    } else if (status == PunchStatus.error) {
      // ❌ Tactile error feedback
      HapticFeedback.vibrate();
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


    Color tintColor = AppTheme.errorRed;
    IconData icon = Icons.error;
    String mainText = state.errorMessage?.replaceAll('Exception: ', '') ?? 'Unknown error';

    final isGeofenceError = isError && (mainText.contains('Outside assigned branches') || mainText.toLowerCase().contains('geofence'));

    if (isSuccess) {
      tintColor = AppTheme.successGreen;
      icon = Icons.check_circle;
      mainText = state.result?['message'] ?? 'Punch Successful';
    } else if (isOffline) {
      tintColor = AppTheme.primaryCyan;
      icon = Icons.cloud_off;
      mainText = 'Saved Offline (Will sync when online)';
    } else if (isGeofenceError) {
      tintColor = Colors.orange;
      icon = Icons.location_off;
    } else if (isError) {
      mainText = 'Error: $mainText';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration(borderRadius: 16).copyWith(
        color: tintColor.withOpacity(0.08),
        border: Border.all(color: tintColor.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: tintColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mainText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (isSuccess && displayTime.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Local time: $displayTime',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: widget.onDismiss,
                icon: const Icon(Icons.close, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: Colors.white70,
              ),
            ],
          ),
          if (isError && widget.onRetry != null && !isGeofenceError) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tintColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ] else if (isError) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onDismiss,
                icon: Icon(Icons.refresh, size: 16, color: tintColor),
                label: Text('Try Again', style: TextStyle(fontSize: 13, color: tintColor, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: tintColor.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
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
      decoration: AppTheme.glassDecoration(borderRadius: 16).copyWith(
        color: AppTheme.errorRed.withOpacity(0.08),
        border: Border.all(color: AppTheme.errorRed.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.errorRed.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.gpp_bad,
              size: 48,
              color: AppTheme.errorRed,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'DEVICE COMPROMISED',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.errorRed,
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onDismiss,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
