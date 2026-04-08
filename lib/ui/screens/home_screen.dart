import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/punch_provider.dart';
import '../../providers/network_sync_provider.dart';
import '../../services/app_settings.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _employeeId = '';
  bool _isConfigured = false;

  @override
  void initState() {
    super.initState();
    _loadEmployeeId();
    _requestPermissionsOnStartup();
    
    // Start background sync listener
    Future.microtask(() {
      ref.read(networkSyncProvider).listenToNetworkChanges();
      ref.read(networkSyncProvider).syncOfflinePunches(); // Sync on startup in case offline punches exist
    });
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Virtual Attendance'),
        elevation: 0,
        backgroundColor: const Color(0xFF009CA6),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Status',
            onPressed: () => ref.invalidate(deviceConfigProvider),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configure',
            onPressed: _openSettings,
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
                branchName: config['status'] == 'assigned' ? config['branch_name'] : null,
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
            else
              deviceConfig.when(
                data: (config) {
                  if (config['status'] == 'pending') {
                    return _PendingAssignmentCard();
                  }
                  
                  if (punchState.status == PunchStatus.loading) {
                    return const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: Colors.indigo),
                          SizedBox(height: 16),
                          Text('Verifying biometrics & location...', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      _PunchButton(
                        label: 'CLOCK IN',
                        icon: Icons.login_rounded,
                        color: Colors.green.shade600,
                        onPressed: () => punchNotifier.performPunch(_employeeId, 'In'),
                      ),
                      const SizedBox(height: 16),
                      _PunchButton(
                        label: 'CLOCK OUT',
                        icon: Icons.logout_rounded,
                        color: Colors.red.shade600,
                        onPressed: () => punchNotifier.performPunch(_employeeId, 'Out'),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Attempting to sync offline offline punches...')),
                          );
                          ref.read(networkSyncProvider).syncOfflinePunches();
                        },
                        icon: const Icon(Icons.sync),
                        label: const Text('Sync Offline Data (If Any)'),
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFF009CA6)),
                      )
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Column(
                    children: [
                      const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text('Sync Failed: $err', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                      TextButton(onPressed: () => ref.invalidate(deviceConfigProvider), child: const Text('Try Again')),
                    ],
                  ),
                ),
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
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.app_registration_rounded, size: 40, color: Colors.amber),
          ),
          const SizedBox(height: 16),
          const Text(
            'Device Not Assigned',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.brown),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your device is registered, but hasn\'t been assigned to a branch yet.\n\nPlease contact your HR Administrator.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.brown, height: 1.4),
          ),
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSuccess ? Colors.green : Colors.red),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: isSuccess ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSuccess ? 'Attendance Recorded ✅' : 'Error: ${state.errorMessage}',
                  style: TextStyle(
                    color: isSuccess ? Colors.green.shade900 : Colors.red.shade900,
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
