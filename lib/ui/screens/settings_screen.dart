import 'package:flutter/material.dart';
import '../../services/app_settings.dart';
import '../../services/api_service.dart';
import '../../services/security_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverUrlCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();
  final _deviceLabelCtrl = TextEditingController();
  bool _saving = false;
  bool _registering = false;
  bool _obscureKey = true;
  String _registrationStatus = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _serverUrlCtrl.text = await AppSettings.getServerUrl();
    _apiKeyCtrl.text = await AppSettings.getApiKey();
    _deviceLabelCtrl.text = await AppSettings.getDeviceLabel();
    setState(() {});
  }

  Future<void> _save({bool silent = false}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await AppSettings.setServerUrl(_serverUrlCtrl.text);
    await AppSettings.setApiKey(_apiKeyCtrl.text);
    await AppSettings.setDeviceLabel(_deviceLabelCtrl.text);
    setState(() => _saving = false);
    if (!silent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved!'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _registerDevice() async {
    if (!_formKey.currentState!.validate()) return;
    await _save(silent: true);
    setState(() { _registering = true; _registrationStatus = ''; });
    try {
      final api = ApiService();
      final security = SecurityService();
      final uuid = await security.getDeviceUniqueId();
      final result = await api.getDeviceConfig(
        deviceUuid: uuid,
        deviceLabel: _deviceLabelCtrl.text.isNotEmpty ? _deviceLabelCtrl.text : null,
      );
      final status = result['status'] as String? ?? '';
      setState(() => _registrationStatus = status);
      if (mounted) {
        String msg;
        Color color;
        if (status == 'pending_approval') {
          msg = '⏳ Device registered! Waiting for admin approval.';
          color = Colors.orange;
        } else if (status == 'active') {
          msg = '✅ Device active and assigned to branch!';
          color = Colors.green;
        } else if (status == 'pending_branch') {
          msg = '✅ Approved! Waiting for branch assignment.';
          color = Colors.blue;
        } else {
          msg = 'Status: $status';
          color = Colors.grey;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: color, duration: const Duration(seconds: 5)),
        );
      }
    } catch (e) {
      setState(() => _registrationStatus = 'error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _registering = false);
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('App Configuration'),
        backgroundColor: const Color(0xFF009CA6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: '👤 Identity', subtitle: 'Identify your phone for registration'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _deviceLabelCtrl,
                decoration: _inputDecoration('Device Label (optional)', Icons.smartphone_outlined)
                    .copyWith(hintText: 'e.g. John\'s Samsung A55'),
              ),
              if (_registrationStatus == 'pending_approval') ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.hourglass_top, color: Colors.orange, size: 16),
                      SizedBox(width: 8),
                      Expanded(child: Text('Pending admin approval. Contact your HR administrator.', style: TextStyle(fontSize: 12, color: Colors.orange))),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),
              _SectionHeader(title: '🌐 Server', subtitle: 'Middleware aggregator address'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _serverUrlCtrl,
                decoration: _inputDecoration('Server URL', Icons.dns_outlined),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (!v.startsWith('http')) return 'Must start with http:// or https://';
                  return null;
                },
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 28),
              _SectionHeader(title: '🔑 API Key', subtitle: 'From the dashboard Security tab'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _apiKeyCtrl,
                obscureText: _obscureKey,
                decoration: _inputDecoration('API Key', Icons.key_outlined).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscureKey ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureKey = !_obscureKey),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009CA6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Configuration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _registering || _saving ? null : _registerDevice,
                  icon: const Icon(Icons.app_registration),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  label: _registering
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Register to Middleware', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final api = ApiService();
                      final status = await api.checkAppStatus();
                      if (mounted) {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('App Status'),
                            content: Text(status['message'] ?? 'Status: ${status['status']}\nMin Version: ${status['min_version']}'),
                            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to check updates'), backgroundColor: Colors.red));
                      }
                    }
                  },
                  icon: const Icon(Icons.system_update_alt),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFF009CA6)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  label: const Text('Check for Updates', style: TextStyle(color: Color(0xFF009CA6))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF009CA6)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF009CA6), width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF009CA6))),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
