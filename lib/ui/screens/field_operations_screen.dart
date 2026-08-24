import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../services/app_settings.dart';
import '../../services/security_service.dart';

class FieldOperationsScreen extends ConsumerStatefulWidget {
  const FieldOperationsScreen({super.key});

  @override
  ConsumerState<FieldOperationsScreen> createState() => _FieldOperationsScreenState();
}

class _FieldOperationsScreenState extends ConsumerState<FieldOperationsScreen> {
  final ApiService _api = ApiService();
  final SecurityService _security = SecurityService();
  final ImagePicker _picker = ImagePicker();

  String _employeeId = '';

  // Active visit state (persisted across app restarts)
  int? _activeVisitId;
  String? _activeCustomerName;
  String? _activeVisitType;
  DateTime? _activeCheckInTime;
  Timer? _stopwatchTimer;
  String _elapsedDuration = '00:00:00';

  // Form states for new check-in
  String _selectedVisitType = 'storing'; // 'storing', 'canvassing', 'delivery', 'service'
  int? _selectedCustomerId;
  String? _selectedCustomerName;
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  List<dynamic> _customers = [];
  List<dynamic> _assignedTasks = [];
  Map<String, dynamic>? _todayCanvassPlan;

  bool _loading = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadStateAndData();
  }

  @override
  void dispose() {
    _stopwatchTimer?.cancel();
    _breadcrumbTimer?.cancel();
    _purposeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadStateAndData() async {
    setState(() => _loading = true);
    _employeeId = await AppSettings.getEmployeeId();

    // Check if there's an active visit stored locally
    final prefs = await SharedPreferences.getInstance();
    final savedVisitId = prefs.getInt('active_field_visit_id');
    if (savedVisitId != null) {
      _activeVisitId = savedVisitId;
      _activeCustomerName = prefs.getString('active_field_customer_name');
      _activeVisitType = prefs.getString('active_field_visit_type');
      final timeStr = prefs.getString('active_field_check_in_time');
      if (timeStr != null) {
        _activeCheckInTime = DateTime.tryParse(timeStr);
        _startTimer();
      }
    }

    await _fetchData();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _fetchData() async {
    try {
      final custs = await _api.getCustomers();
      final tasks = await _api.getFieldTasks(employeeId: _employeeId, status: 'pending');
      final planRes = await _api.getTodayCanvassPlan(_employeeId);

      if (mounted) {
        setState(() {
          _customers = custs;
          _assignedTasks = tasks;
          _todayCanvassPlan = planRes['has_plan'] == true ? planRes['plan'] : null;
        });
      }
    } catch (e) {
      // Ignore network errors in background fetch
    }
  }

  Timer? _breadcrumbTimer;

  void _startTimer() {
    _stopwatchTimer?.cancel();
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_activeCheckInTime == null || !mounted) return;
      final diff = DateTime.now().difference(_activeCheckInTime!);
      final h = diff.inHours.toString().padLeft(2, '0');
      final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
      final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
      setState(() => _elapsedDuration = '$h:$m:$s');
    });

    // Start background GPS breadcrumb recorder (every 2 minutes)
    _startBreadcrumbRecorder();
  }

  void _startBreadcrumbRecorder() {
    _breadcrumbTimer?.cancel();
    _breadcrumbTimer = Timer.periodic(const Duration(minutes: 2), (_) async {
      if (_activeVisitId == null) {
        _breadcrumbTimer?.cancel();
        return;
      }
      try {
        final pos = await _getCurrentLocation();
        if (pos != null && !pos.isMocked) {
          await _api.sendBreadcrumb(
            visitId: _activeVisitId!,
            latitude: pos.latitude,
            longitude: pos.longitude,
            speed: pos.speed * 3.6, // m/s to km/h
            accuracy: pos.accuracy,
            heading: pos.heading,
            recordedAt: DateTime.now(),
          );
        }
      } catch (e) {
        // Silently skip if network or GPS error during background ping
      }
    });
  }

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable GPS / Location services.')),
        );
      }
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    return await Geolocator.getCurrentPosition();
  }

  Future<void> _handleCheckIn() async {
    setState(() => _submitting = true);
    try {
      final pos = await _getCurrentLocation();
      if (pos == null) {
        setState(() => _submitting = false);
        return;
      }

      final deviceUuid = await _security.getDeviceUniqueId();

      final res = await _api.checkInFieldVisit(
        employeeId: _employeeId,
        customerId: _selectedCustomerId,
        visitType: _selectedVisitType,
        purpose: _purposeController.text.trim(),
        latitude: pos.latitude,
        longitude: pos.longitude,
        deviceUuid: deviceUuid,
      );

      final visitId = res['visit_id'] as int;
      final now = DateTime.now();

      // Persist active visit locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('active_field_visit_id', visitId);
      await prefs.setString('active_field_customer_name', _selectedCustomerName ?? 'External Location');
      await prefs.setString('active_field_visit_type', _selectedVisitType);
      await prefs.setString('active_field_check_in_time', now.toIso8601String());

      if (mounted) {
        setState(() {
          _activeVisitId = visitId;
          _activeCustomerName = _selectedCustomerName ?? 'External Location';
          _activeVisitType = _selectedVisitType;
          _activeCheckInTime = now;
        });
        _startTimer();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checked in at $_activeCustomerName!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Check-in failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _handleCheckOut() async {
    if (_activeVisitId == null) return;
    setState(() => _submitting = true);
    try {
      final pos = await _getCurrentLocation();
      if (pos == null) {
        setState(() => _submitting = false);
        return;
      }

      await _api.checkOutFieldVisit(
        visitId: _activeVisitId!,
        latitude: pos.latitude,
        longitude: pos.longitude,
        notes: _notesController.text.trim(),
        result: _notesController.text.trim(),
      );

      // Clear local persistence
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_field_visit_id');
      await prefs.remove('active_field_customer_name');
      await prefs.remove('active_field_visit_type');
      await prefs.remove('active_field_check_in_time');

      _stopwatchTimer?.cancel();
      _breadcrumbTimer?.cancel();
      if (mounted) {
        setState(() {
          _activeVisitId = null;
          _activeCustomerName = null;
          _activeVisitType = null;
          _activeCheckInTime = null;
          _notesController.clear();
          _purposeController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Field visit completed & recorded successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        _fetchData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Check-out failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _takePhoto() async {
    if (_activeVisitId == null) return;
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (photo == null) return;

      final pos = await _getCurrentLocation();

      await _api.uploadVisitPhoto(
        visitId: _activeVisitId!,
        filePath: photo.path,
        caption: 'Field Visit Evidence',
        latitude: pos?.latitude,
        longitude: pos?.longitude,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo uploaded to visit report.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload photo: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Operations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStateAndData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. ACTIVE VISIT STATUS (IF CHECKED IN)
                  if (_activeVisitId != null) ...[
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade900, Colors.indigo.shade900],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _activeVisitType?.toUpperCase() ?? 'FIELD VISIT',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.timer, color: Colors.cyanAccent, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    _elapsedDuration,
                                    style: const TextStyle(
                                      color: Colors.cyanAccent,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _activeCustomerName ?? 'External Location',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Quick actions for active visit
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _takePhoto,
                                  icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                                  label: const Text('Add Photo', style: TextStyle(color: Colors.white)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.white30),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _submitting ? null : _handleCheckOut,
                                  icon: const Icon(Icons.check_circle, size: 18),
                                  label: const Text('Check Out'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade600,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    // 2. CHECK-IN CARD (WHEN IDLE)
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.location_on, color: Colors.blueAccent),
                                SizedBox(width: 8),
                                Text(
                                  'Start Field Visit',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Visit Type Toggle
                            const Text('Visit Purpose Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              children: [
                                ChoiceChip(
                                  label: const Text('🔧 Mechanic Storing'),
                                  selected: _selectedVisitType == 'storing',
                                  onSelected: (v) => setState(() => _selectedVisitType = 'storing'),
                                ),
                                ChoiceChip(
                                  label: const Text('💼 Sales Canvass'),
                                  selected: _selectedVisitType == 'canvassing',
                                  onSelected: (v) => setState(() => _selectedVisitType = 'canvassing'),
                                ),
                                ChoiceChip(
                                  label: const Text('🚚 Delivery'),
                                  selected: _selectedVisitType == 'delivery',
                                  onSelected: (v) => setState(() => _selectedVisitType = 'delivery'),
                                ),
                                ChoiceChip(
                                  label: const Text('🛠 Service'),
                                  selected: _selectedVisitType == 'service',
                                  onSelected: (v) => setState(() => _selectedVisitType = 'service'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Destination / Customer Selector
                            const Text('Destination / Customer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<int>(
                              value: _selectedCustomerId,
                              hint: const Text('Select or search customer/dealer'),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: [
                                const DropdownMenuItem<int>(
                                  value: null,
                                  child: Text('-- Other / External Location --'),
                                ),
                                ..._customers.map((c) => DropdownMenuItem<int>(
                                      value: c['id'] as int,
                                      child: Text('${c['name']} (${c['city'] ?? c['customer_type']})'),
                                    )),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _selectedCustomerId = val;
                                  if (val != null) {
                                    final found = _customers.firstWhere((e) => e['id'] == val, orElse: () => null);
                                    _selectedCustomerName = found != null ? found['name'] : null;
                                  } else {
                                    _selectedCustomerName = 'External Location';
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 14),

                            // Notes / Purpose
                            TextField(
                              controller: _purposeController,
                              decoration: InputDecoration(
                                labelText: 'Job Notes / Instructions',
                                hintText: 'e.g. Storing 3 truck units at Dealer X',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 18),

                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: _submitting ? null : _handleCheckIn,
                                icon: _submitting
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.play_arrow),
                                label: const Text('Check In to Location', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 3. TODAY'S SALES CANVASS PLAN (IF ANY)
                  if (_todayCanvassPlan != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Today's Canvass Route",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_todayCanvassPlan!['actual_visits']} / ${_todayCanvassPlan!['target_visits']} visits',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purpleAccent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            ...((_todayCanvassPlan!['customers'] as List<dynamic>?) ?? []).map((c) => ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Colors.purple,
                                    child: Icon(Icons.store, color: Colors.white, size: 18),
                                  ),
                                  title: Text(c['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  subtitle: Text('${c['city'] ?? ''} • ${c['customer_type'] ?? ''}', style: const TextStyle(fontSize: 12)),
                                  trailing: OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedCustomerId = c['id'] as int;
                                        _selectedCustomerName = c['name'] as String;
                                        _selectedVisitType = 'canvassing';
                                      });
                                    },
                                    child: const Text('Select'),
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 4. ASSIGNED TASKS (MECHANIC DISPATCHES)
                  if (_assignedTasks.isNotEmpty) ...[
                    const Text(
                      'Assigned Field Tasks',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ..._assignedTasks.map((t) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: t['priority'] == 'urgent' ? Colors.red : Colors.blue,
                              child: const Icon(Icons.build, color: Colors.white, size: 18),
                            ),
                            title: Text(t['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text('Due: ${t['due_date'] ?? 'ASAP'} • ${t['task_type']}', style: const TextStyle(fontSize: 12)),
                            trailing: ElevatedButton(
                              onPressed: () async {
                                await _api.startFieldTask(t['id'] as int);
                                _fetchData();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Start'),
                            ),
                          ),
                        )),
                  ],
                ],
              ),
            ),
    );
  }
}
