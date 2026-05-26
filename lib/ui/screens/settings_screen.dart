import 'dart:convert';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/app_settings.dart';
import '../../services/api_service.dart';
import '../../services/security_service.dart';
import '../../providers/network_sync_provider.dart';
import '../../providers/theme_provider.dart';
import '../theme.dart';
import 'help_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverUrlCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();
  final _deviceLabelCtrl = TextEditingController();

  bool _registering = false;
  bool _obscureKey = true;
  bool _testingConnection = false;
  bool? _connectionOk;
  String _connectionError = '';

  // Registration result (persistent card, not snackbar)
  String _regStatus = '';
  String _regMessage = '';
  bool _regSuccess = false;

  // Security settings
  bool _certificatePinEnabled = false;
  int _biometricSessionSeconds = 30;
  bool _qrEnabled = false;
  bool _nfcEnabled = false;
  bool _selfieEnabled = false;

  // Notification settings
  bool _notificationsEnabled = true;
  bool _reminderNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _serverUrlCtrl.text = await AppSettings.getServerUrl();
    _apiKeyCtrl.text = await AppSettings.getApiKey();
    _deviceLabelCtrl.text = await AppSettings.getDeviceLabel();
    _certificatePinEnabled = await AppSettings.isCertificatePinEnabled();
    _biometricSessionSeconds = await AppSettings.getBiometricSessionSeconds();
    _qrEnabled = await AppSettings.getQREnabled();
    _nfcEnabled = await AppSettings.getNFCEnabled();
    _selfieEnabled = await AppSettings.getSelfieEnabled();
    _notificationsEnabled = await AppSettings.getNotificationsEnabled();
    _reminderNotifications = await AppSettings.getReminderNotifications();
    setState(() {});
  }

  Future<void> _testConnection() async {
    final url = _serverUrlCtrl.text.trim();
    if (url.isEmpty) {
      setState(() { _connectionOk = false; _connectionError = 'Enter a server URL first'; });
      return;
    }
    setState(() { _testingConnection = true; _connectionOk = null; _connectionError = ''; });
    try {
      final api = ApiService();
      await AppSettings.setServerUrl(url); // Temporarily save for the test
      final status = await api.checkAppStatus();
      if (status['status'] == 'ok' || status['status'] == 'error') {
        // Both responses mean the server is reachable
        setState(() => _connectionOk = true);
      } else {
        setState(() { _connectionOk = false; _connectionError = 'Unexpected response'; });
      }
    } catch (e) {
      setState(() { _connectionOk = false; _connectionError = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      if (mounted) setState(() => _testingConnection = false);
    }
  }


  Future<void> _scanOnboardQr(BuildContext context) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Scan Onboarding QR')),
          body: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  Navigator.of(context).pop(barcode.rawValue);
                  break;
                }
              }
            },
          ),
        ),
      ),
    );

    if (result != null) {
      try {
        setState(() { _registering = true; _regStatus = ''; _regMessage = ''; });
        
        final data = jsonDecode(result) as Map<String, dynamic>;
        var url = data['url'] as String;
        final token = data['token'] as String;
        
        // Intelligent Localhost Fallback:
        if (url.contains('localhost') || url.contains('127.0.0.1')) {
          final customUrl = _serverUrlCtrl.text.trim();
          if (customUrl.isNotEmpty && customUrl.startsWith('http')) {
            try {
              final parsedCustom = Uri.parse(customUrl);
              final parsedQr = Uri.parse(url);
              url = url.replaceAll(
                '${parsedQr.host}:${parsedQr.port}',
                '${parsedCustom.host}:${parsedCustom.port}',
              ).replaceAll(parsedQr.host, parsedCustom.host);
            } catch (_) {}
          }
        }
        
        await AppSettings.setServerUrl(url);
        _serverUrlCtrl.text = url;
        
        final api = ApiService();
        final security = SecurityService();
        final uuid = await security.getDeviceUniqueId();
        
        debugPrint('🔄 Calling onboardDevice with token: ${token.substring(0, 20)}...');
        final response = await api.onboardDevice(
          token: token,
          deviceUuid: uuid,
          deviceLabel: _deviceLabelCtrl.text.isNotEmpty ? _deviceLabelCtrl.text : null,
        );
        debugPrint('✅ onboardDevice response: $response');
        
        if (response['status'] == 'active') {
          final apiKey = response['api_key'] as String?;
          if (apiKey != null && apiKey.isNotEmpty) {
            await AppSettings.setApiKey(apiKey);
            _apiKeyCtrl.text = apiKey;
          }

          final empId = response['employee_id'] as String?;
          if (empId != null && empId.isNotEmpty) {
            await AppSettings.setEmployeeId(empId);
          }
          
          final empName = response['employee_name'] as String?;
          if (empName != null && empName.isNotEmpty) {
            await AppSettings.setEmployeeName(empName);
          }
          
          // Show success message and close the app so it restarts cleanly
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Device registered! Restarting...'),
                backgroundColor: Color(0xFF009CA6),
              ),
            );
          }
          await Future.delayed(const Duration(seconds: 1));
          if (context.mounted) {
            SystemNavigator.pop();
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Registration status: ${response['status']}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
        
      } catch (e) {
        debugPrint('❌ QR onboarding error: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _registering = false;
            _regStatus = '';
            _regMessage = '';
          });
        }
      }
    }
  }

  Future<void> _registerDevice() async {

    if (!_formKey.currentState!.validate()) return;

    setState(() { _registering = true; _regStatus = ''; _regMessage = ''; });

    // Save all settings first
    await AppSettings.setServerUrl(_serverUrlCtrl.text);
    await AppSettings.setApiKey(_apiKeyCtrl.text);
    await AppSettings.setDeviceLabel(_deviceLabelCtrl.text);

    try {
      final api = ApiService();
      final security = SecurityService();
      final uuid = await security.getDeviceUniqueId();
      final result = await api.getDeviceConfig(
        deviceUuid: uuid,
        deviceLabel: _deviceLabelCtrl.text.isNotEmpty ? _deviceLabelCtrl.text : null,
      );
      final status = result['status'] as String? ?? '';
      final branches = result['branches'] as List<dynamic>? ?? [];
      final deviceCount = result['device_count'] as int? ?? 1;
      final maxDevices = result['max_devices'] as int? ?? 5;
      final empName = result['employee_name'] as String?;
      if (empName != null && empName.isNotEmpty) {
        await AppSettings.setEmployeeName(empName);
      }

      final empId = result['employee_id'] as String?;
      if (empId != null && empId.isNotEmpty) {
        await AppSettings.setEmployeeId(empId);
      }

      String message;
      bool success;
      if (status == 'active') {
        message = 'Your device is active and assigned to ${branches.length} branch(es). You can now clock in.';
        success = true;
      } else if (status == 'pending_approval') {
        message = 'Device registered! Waiting for admin approval.\nContact your HR administrator to approve this device.';
        success = true;
      } else if (status == 'pending_branch') {
        message = 'Device approved! Waiting for admin to assign your branch location.';
        success = true;
      } else if (status == 'max_devices_reached') {
        message = 'You have reached the maximum of $deviceCount/$maxDevices devices.\nPlease ask admin to remove an old device.';
        success = false;
      } else {
        message = 'Status: $status';
        success = true;
      }

      setState(() {
        _regStatus = status;
        _regMessage = message;
        _regSuccess = success;
      });
    } catch (e) {
      setState(() {
        _regStatus = 'error';
        _regMessage = 'Connection failed: ${e.toString().replaceAll('Exception: ', '')}';
        _regSuccess = false;
      });
    } finally {
      if (mounted) setState(() => _registering = false);
    }
  }

  String get _biometricSessionLabel {
    switch (_biometricSessionSeconds) {
      case 0:
        return 'Every Punch';
      case 30:
        return '30 seconds';
      case 60:
        return '1 minute';
      case 300:
        return '5 minutes';
      default:
        return '$_biometricSessionSeconds seconds';
    }
  }

  @override
  void dispose() {
    _serverUrlCtrl.dispose();
    _apiKeyCtrl.dispose();
    _deviceLabelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Device Setup & Settings'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ═══════════════════════════════════════════════════════════════
              // METHOD 1: QR CODE ONBOARDING (Recommended)
              // ═══════════════════════════════════════════════════════════════
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: AppTheme.glassDecoration(context: context).copyWith(
                  color: AppTheme.successGreen.withOpacity(0.05),
                  border: Border.all(color: AppTheme.successGreen.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.successGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.qr_code_scanner, color: AppTheme.successGreen, size: 24),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('⚡ Quick Setup (Recommended)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.successGreen)),
                              Text('Scan admin QR to auto-fill details', style: TextStyle(fontSize: 12, color: AppTheme.successGreen)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _scanOnboardQr(context),
                        icon: const Icon(Icons.qr_code_scanner),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryCyan,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        label: const Text('Scan QR to Auto-Setup', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Divider with "OR" ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'OR MANUAL SETUP',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade500,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
              ),

              // ═══════════════════════════════════════════════════════════════
              // METHOD 2: MANUAL SETUP (Step by Step — Requires Admin Approval)
              // ═══════════════════════════════════════════════════════════════
              Text(
                'MANUAL SETUP',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade400,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Enter details manually — requires admin approval after registration',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 16),

              // ── Step 1: Identity ─────────────────────────────────────────
              _StepIndicator(step: 1, title: 'Device Identity', isActive: true),
              const SizedBox(height: 12),
              _Card(
                children: [
                  TextFormField(
                    controller: _deviceLabelCtrl,
                    decoration: _inputDecoration('Device Label (optional)', Icons.smartphone_outlined)
                        .copyWith(hintText: 'e.g. John\'s Samsung A55'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Step 2: Server ───────────────────────────────────────────
              _StepIndicator(step: 2, title: 'Server Connection', isActive: true),
              const SizedBox(height: 12),
              _Card(
                children: [
                  TextFormField(
                    controller: _serverUrlCtrl,
                    decoration: _inputDecoration('Server URL', Icons.dns_outlined).copyWith(
                      hintText: 'https://your-server.com',
                      suffixIcon: _testingConnection
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : _connectionOk == null
                              ? IconButton(
                                  icon: const Icon(Icons.wifi_find, size: 20),
                                  tooltip: 'Test Connection',
                                  onPressed: _testConnection,
                                )
                              : IconButton(
                                  icon: Icon(_connectionOk! ? Icons.check_circle : Icons.error, size: 20),
                                  color: _connectionOk! ? Colors.green : Colors.red,
                                  tooltip: _connectionOk! ? 'Connected' : _connectionError,
                                  onPressed: _testConnection,
                                ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (!v.startsWith('http')) return 'Must start with http:// or https://';
                      return null;
                    },
                    keyboardType: TextInputType.url,
                  ),
                  if (_connectionOk == false && _connectionError.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(_connectionError, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ],
                ],
              ),

              const SizedBox(height: 24),

              // ── Step 3: API Key ──────────────────────────────────────────
              _StepIndicator(step: 3, title: 'API Key', isActive: true),
              const SizedBox(height: 12),
              _Card(
                children: [
                  TextFormField(
                    controller: _apiKeyCtrl,
                    obscureText: _obscureKey,
                    decoration: _inputDecoration('API Key', Icons.key_outlined).copyWith(
                      hintText: 'Paste key from admin dashboard',
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(_obscureKey ? Icons.visibility_off : Icons.visibility, size: 20),
                            onPressed: () => setState(() => _obscureKey = !_obscureKey),
                            tooltip: _obscureKey ? 'Show key' : 'Hide key',
                          ),
                          IconButton(
                            icon: const Icon(Icons.content_paste, size: 18),
                            onPressed: () async {
                              // No-op: paste is native via long-press
                            },
                            tooltip: 'Long-press to paste',
                          ),
                        ],
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Step 4: Register ─────────────────────────────────────────
              _StepIndicator(step: 4, title: 'Register Device', isActive: true, subtitle: 'Sends device info to server for admin approval'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _registering ? null : _registerDevice,
                  icon: _registering
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.app_registration),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  label: Text(_registering ? 'Registering...' : 'Register to Server', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),

              // ── Registration Result Card ─────────────────────────────────
              if (_regStatus.isNotEmpty) ...[
                const SizedBox(height: 16),
                _RegistrationResultCard(
                  status: _regStatus,
                  message: _regMessage,
                  success: _regSuccess,
                  onDismiss: () => setState(() { _regStatus = ''; _regMessage = ''; }),
                  onDone: () {
                    // Use post-frame callback to ensure safe navigation
                    // After this frame completes, switch to Dashboard tab (index 0)
                    // Do NOT pop Navigator - Settings is a tab inside HomeScreen's IndexedStack
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        ref.read(homeTabIndexProvider.notifier).state = 0;
                      }
                    });
                  },
                ),
              ],

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              // ── Appearance ────────────────────────────────────────────────
              _StepIndicator(step: 0, title: 'Appearance', isActive: false),
              const SizedBox(height: 12),
              _Card(
                children: [
                  Consumer(
                    builder: (context, ref, child) {
                      final themeMode = ref.watch(themeProvider);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('App Theme',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Choose light, dark, or system default',
                            style: TextStyle(fontSize: 12)),
                        trailing: DropdownButton<ThemeMode>(
                          value: themeMode,
                          underline: const SizedBox.shrink(),
                          items: const [
                            DropdownMenuItem(value: ThemeMode.system, child: Text('System Default')),
                            DropdownMenuItem(value: ThemeMode.light, child: Text('Light Mode')),
                            DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark Mode')),
                          ],
                          onChanged: (mode) {
                            if (mode != null) {
                              ref.read(themeProvider.notifier).setTheme(mode);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // ── Security ──────────────────────────────────────────────────
              _StepIndicator(step: 0, title: 'Security', isActive: false),
              const SizedBox(height: 12),
              _Card(
                children: [
                  // Certificate Pinning toggle
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable Certificate Pinning',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Reject untrusted server certificates',
                        style: TextStyle(fontSize: 12)),
                    value: _certificatePinEnabled,
                    activeColor: const Color(0xFF009CA6),
                    onChanged: (value) async {
                      await AppSettings.setCertificatePinEnabled(value);
                      setState(() => _certificatePinEnabled = value);
                    },
                  ),
                  const Divider(height: 1),
                  // Biometric Session Timeout
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Biometric Session Timeout',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    subtitle: Text(_biometricSessionLabel, style: const TextStyle(fontSize: 12)),
                    trailing: DropdownButton<int>(
                      value: _biometricSessionSeconds,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Every Punch')),
                        DropdownMenuItem(value: 30, child: Text('30 seconds')),
                        DropdownMenuItem(value: 60, child: Text('1 minute')),
                        DropdownMenuItem(value: 300, child: Text('5 minutes')),
                      ],
                      onChanged: (value) async {
                        if (value != null) {
                          await AppSettings.setBiometricSessionSeconds(value);
                          setState(() => _biometricSessionSeconds = value);
                        }
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  // QR Code Verification toggle
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('QR Code Verification',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Require QR scan before punch',
                        style: TextStyle(fontSize: 12)),
                    value: _qrEnabled,
                    activeColor: const Color(0xFF009CA6),
                    onChanged: (value) async {
                      await AppSettings.setQREnabled(value);
                      setState(() => _qrEnabled = value);
                    },
                  ),
                  const Divider(height: 1),
                  // NFC Verification toggle
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('NFC Verification',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Require NFC tag scan before punch',
                        style: TextStyle(fontSize: 12)),
                    value: _nfcEnabled,
                    activeColor: const Color(0xFF009CA6),
                    onChanged: (value) async {
                      await AppSettings.setNFCEnabled(value);
                      setState(() => _nfcEnabled = value);
                    },
                  ),
                  const Divider(height: 1),
                  // Selfie / Face Verification toggle
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Selfie Verification',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Require a selfie photo before punching',
                        style: TextStyle(fontSize: 12)),
                    value: _selfieEnabled,
                    activeColor: const Color(0xFF009CA6),
                    onChanged: (value) async {
                      await AppSettings.setSelfieEnabled(value);
                      setState(() => _selfieEnabled = value);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // ── Notifications ──────────────────────────────────────────────
              _StepIndicator(step: 0, title: 'Notifications', isActive: false),
              const SizedBox(height: 12),
              _Card(
                children: [
                  // Push Notifications master toggle
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Push Notifications',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Receive attendance alerts and reminders',
                        style: TextStyle(fontSize: 12)),
                    value: _notificationsEnabled,
                    activeColor: const Color(0xFF009CA6),
                    onChanged: (value) async {
                      await AppSettings.setNotificationsEnabled(value);
                      setState(() => _notificationsEnabled = value);
                    },
                  ),
                  const Divider(height: 1),
                  // Clock-in Reminder toggle
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Clock-in Reminders',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Get reminded to clock in on weekday mornings',
                        style: TextStyle(fontSize: 12)),
                    value: _reminderNotifications,
                    activeColor: const Color(0xFF009CA6),
                    onChanged: (value) async {
                      await AppSettings.setReminderNotifications(value);
                      setState(() => _reminderNotifications = value);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // ── Sync Status ──────────────────────────────────────────────
              Consumer(builder: (context, ref, _) {
                final syncState = ref.watch(syncStateProvider);
                final pendingCount = syncState.pendingCount;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StepIndicator(step: 0, title: 'Offline Sync', isActive: false),
                    const SizedBox(height: 12),
                    _Card(
                      children: [
                        Row(
                          children: [
                            Icon(
                              pendingCount > 0
                                  ? (syncState.status == SyncStatus.syncing ? Icons.sync : Icons.cloud_upload)
                                  : Icons.cloud_done,
                              color: pendingCount > 0
                                  ? (syncState.status == SyncStatus.syncing ? Colors.blue : Colors.orange)
                                  : Colors.green,
                              size: 28,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    syncState.status == SyncStatus.syncing
                                        ? 'Syncing...'
                                        : pendingCount > 0
                                            ? '$pendingCount Punch(es) Pending Sync'
                                            : 'All Punches Synced',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                  ),
                                  if (syncState.lastSyncAt != null)
                                    Text(
                                      'Last sync: ${_formatTime(syncState.lastSyncAt!)}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  if (syncState.status == SyncStatus.error && syncState.lastError != null)
                                    Text(
                                      syncState.lastError!,
                                      style: const TextStyle(fontSize: 11, color: Colors.red),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            if (syncState.status == SyncStatus.syncing)
                              const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                              )
                            else
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: IconButton(
                                  onPressed: () => ref.read(networkSyncProvider).syncOfflinePunches(),
                                  icon: const Icon(Icons.sync),
                                  tooltip: 'Force sync now',
                                  color: const Color(0xFF009CA6),
                                ),
                              ),
                          ],
                        ),
                        if (pendingCount > 0) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => ref.read(networkSyncProvider).syncOfflinePunches(),
                              icon: const Icon(Icons.cloud_upload, size: 18),
                              label: Text('Sync $pendingCount Punch(es) Now'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange.shade700,
                                side: BorderSide(color: Colors.orange.shade300),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                );
              }),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // ── Tools ────────────────────────────────────────────────────
              _StepIndicator(step: 0, title: 'Tools', isActive: false),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final api = ApiService();
                      final status = await api.checkAppStatus();
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Server Status'),
                            content: Text(status['message'] ?? 'Status: ${status['status']}\nMin Version: ${status['min_version']}'),
                            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Server unreachable'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.system_update_alt),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFF009CA6)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  label: const Text('Check Server Status & Updates', style: TextStyle(color: Color(0xFF009CA6))),
                ),
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HelpScreen()),
                    );
                  },
                  icon: const Icon(Icons.help_outline),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFF009CA6)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  label: const Text('Help & Documentation', style: TextStyle(color: Color(0xFF009CA6))),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade400),
      prefixIcon: Icon(icon, color: AppTheme.primaryCyan),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.primaryCyan, width: 2),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

// ─── Helper ──────────────────────────────────────────────────────────────────

String _formatTime(DateTime dt) {
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

// ─────────────────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration(context: context),
      child: Column(children: children),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int step;
  final String title;
  final String? subtitle;
  final bool isActive;

  const _StepIndicator({
    required this.step,
    required this.title,
    this.subtitle,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryCyan.withOpacity(0.2) : Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
            border: Border.all(color: isActive ? AppTheme.primaryCyan : Colors.white.withOpacity(0.1)),
          ),
          child: Center(
            child: step > 0
                ? Text('$step', style: TextStyle(color: isActive ? AppTheme.primaryCyan : Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 14))
                : Icon(Icons.build, size: 14, color: isActive ? AppTheme.primaryCyan : Colors.grey.shade500),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isActive ? Colors.white : Colors.grey.shade400)),
            if (subtitle != null)
              Text(subtitle!, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
      ],
    );
  }
}

class _RegistrationResultCard extends StatelessWidget {
  final String status;
  final String message;
  final bool success;
  final VoidCallback onDismiss;
  final VoidCallback? onDone;

  const _RegistrationResultCard({
    required this.status,
    required this.message,
    required this.success,
    required this.onDismiss,
    this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final Color tintColor;
    final IconData icon;

    if (status == 'active') {
      tintColor = AppTheme.successGreen;
      icon = Icons.check_circle;
    } else if (status == 'pending_approval') {
      tintColor = Colors.orange;
      icon = Icons.hourglass_top;
    } else if (status == 'pending_branch') {
      tintColor = AppTheme.primaryCyan;
      icon = Icons.location_on;
    } else if (status == 'max_devices_reached') {
      tintColor = AppTheme.errorRed;
      icon = Icons.devices;
    } else {
      tintColor = AppTheme.errorRed;
      icon = Icons.error;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration(context: context, borderRadius: 16).copyWith(
        color: tintColor.withOpacity(0.08),
        border: Border.all(color: tintColor.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: tintColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close, size: 16, color: Colors.white70),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          if (success) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: tintColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Done — Go to Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
