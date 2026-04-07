import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/punch_provider.dart';
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Secure Attendance'),
        elevation: 0,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
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
            _HeaderWidget(
              employeeId: _employeeId.isEmpty ? 'Not configured' : _employeeId,
              isConfigured: _isConfigured,
              onSetupTap: _openSettings,
            ),
            const Spacer(),

            // Not configured warning
            if (!_isConfigured)
              _NotConfiguredCard(onSetupTap: _openSettings)
            else if (punchState.status == PunchStatus.loading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: Colors.indigo),
                    SizedBox(height: 16),
                    Text('Verifying biometrics & location...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            else ...[
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
            ],

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

  const _HeaderWidget({
    required this.employeeId,
    required this.isConfigured,
    required this.onSetupTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: isConfigured ? Colors.indigoAccent : Colors.grey.shade300,
              child: Icon(
                isConfigured ? Icons.person : Icons.person_off,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isConfigured ? employeeId : 'Setup Required',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              isConfigured ? 'Remote Site' : 'Tap ⚙️ to configure',
              style: TextStyle(color: isConfigured ? Colors.grey : Colors.orange),
            ),
          ],
        ),
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
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 28),
      label: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    // Extract server_time from result map if available
    final serverTime = state.result?['server_time']?.toString().replaceAll('T', ' ').split('.').first ?? '';

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
                if (isSuccess && serverTime.isNotEmpty)
                  Text(
                    'Server time: $serverTime UTC',
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
