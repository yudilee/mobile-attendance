import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/punch_provider.dart';
import '../../providers/network_sync_provider.dart';
import '../../services/app_settings.dart';
import 'settings_screen.dart';

class PunchTab extends ConsumerStatefulWidget {
  const PunchTab({super.key});

  @override
  ConsumerState<PunchTab> createState() => _PunchTabState();
}

class _PunchTabState extends ConsumerState<PunchTab> {
  String _employeeId = '';
  bool _isConfigured = false;

  @override
  void initState() {
    super.initState();
    _loadEmployeeId();
    _requestPermissionsOnStartup();
    // Start background sync manager (periodic timer + connectivity listener)
    Future.microtask(() => ref.read(networkSyncProvider).start());
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

  Future<void> _loadEmployeeId() async {

    final id = await AppSettings.getEmployeeId();
    final configured = await AppSettings.isConfigured();
    setState(() {
      _employeeId = id;
      _isConfigured = configured;
    });
  }

  Future<void> _openSettings() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    if (saved == true) {
      // Reset state and reload employee ID after saving
      ref.read(punchStateProvider.notifier).reset();
      await _loadEmployeeId();
    }
  }

  @override
  Widget build(BuildContext context) {
    final punchState = ref.watch(punchStateProvider);
    final punchNotifier = ref.read(punchStateProvider.notifier);
    final deviceConfig = ref.watch(deviceConfigProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
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
      body: Container(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            deviceConfig.when(
              data: (config) => _HeaderWidget(
                employeeId: _employeeId.isEmpty ? 'Not configured' : _employeeId,
                isConfigured: _isConfigured,
                onSetupTap: _openSettings,
                branchName: config['status'] == 'active' ? config['branch_name'] : null,
              ),
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
              _NotConfiguredCard(onSetupTap: _openSettings)
            else if (deviceConfig.isLoading && !deviceConfig.hasValue && !deviceConfig.hasError) 
              const Center(child: CircularProgressIndicator(color: Color(0xFF009CA6)))
            else if (deviceConfig.hasValue && deviceConfig.value?['status'] == 'pending_approval')
              _PendingAssignmentCard(message: deviceConfig.value?['message'] ?? 'Waiting for admin approval. Contact HR.')
            else if (deviceConfig.hasValue && deviceConfig.value?['status'] == 'pending_branch')
              _PendingAssignmentCard(message: deviceConfig.value?['message'] ?? 'Approved! Waiting for branch assignment.')
            else
              Builder(
                builder: (context) {
                  if (punchState.status == PunchStatus.loading) {
                    return const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: Color(0xFF009CA6)),
                          SizedBox(height: 16),
                          Text('Verifying biometrics & location...', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }

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
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _PunchButton(
                                  label: pt.label.toUpperCase(),
                                  icon: icon,
                                  color: color,
                                  onPressed: () => punchNotifier.performPunch(_employeeId, pt.code),
                                ),
                              );
                            }).toList(),
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
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
                      )
                    ],
                  );
                },
              ),

            const Spacer(),
            _StatusFeedback(state: punchState),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _HeaderWidget extends StatelessWidget {
  final String employeeId;
  final bool isConfigured;
  final VoidCallback onSetupTap;
  final String? branchName;

  const _HeaderWidget({
    required this.employeeId,
    required this.isConfigured,
    required this.onSetupTap,
    this.branchName,
  });

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
            colors: [Colors.white, const Color(0xFFE0F2F1)], // Light teal match
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: (branchName != null && branchName != 'Connection Error') ? const Color(0xFF009CA6).withOpacity(0.2) : Colors.black12, blurRadius: 10, spreadRadius: 2)
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
                  branchName != null ? Icons.location_on : Icons.location_off,
                  size: 14,
                  color: branchName != null ? const Color(0xFF009CA6) : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  branchName ?? (isConfigured ? 'Syncing branch...' : 'Tap ⚙️ to configure'),
                  style: TextStyle(
                    color: branchName == 'Connection Error' ? Colors.red : Colors.grey.shade700,
                    fontWeight: branchName != null ? FontWeight.w600 : FontWeight.normal,
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

class _NotConfiguredCard extends StatelessWidget {
  final VoidCallback onSetupTap;
  const _NotConfiguredCard({required this.onSetupTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 40, color: Colors.orange),
          const SizedBox(height: 12),
          const Text(
            'App Not Configured',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please set your Employee ID, server URL, and API key before clocking in.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onSetupTap,
            icon: const Icon(Icons.settings),
            label: const Text('Open Settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _PunchButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _PunchButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Create a gradient based on the base color
    final gradient = LinearGradient(
      colors: [color, color.withBlue((color.blue + 30).clamp(0, 255))],
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
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
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
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusFeedback extends StatelessWidget {
  final PunchState state;
  const _StatusFeedback({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.status == PunchStatus.idle) return const SizedBox.shrink();

    final isSuccess = state.status == PunchStatus.success;
    final isOffline = state.status == PunchStatus.offline;
    final isError = state.status == PunchStatus.error;
    
    String displayTime = '';
    if (isSuccess && state.result?['server_time'] != null) {
      try {
        String rawTime = state.result!['server_time'].toString();
        // Ensure the parser knows it's UTC if 'Z' is missing
        if (!rawTime.endsWith('Z') && !rawTime.contains('+')) {
          rawTime += 'Z';
        }
        final local = DateTime.parse(rawTime).toLocal();
        displayTime = "${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} "
            "${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}:${local.second.toString().padLeft(2, '0')}";
      } catch (e) {
        // Fallback to basic cleaning if parsing fails
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
      mainText = 'Attendance Recorded ✅';
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
      child: Row(
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
        ],
      ),
    );
  }
}
