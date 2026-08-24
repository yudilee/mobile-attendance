import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/app_settings.dart';

const Color kEmerald = Color(0xFF10B981);
const Color kEmeraldLight = Color(0xFF34D399);

class LeavePermitHubScreen extends StatefulWidget {
  const LeavePermitHubScreen({super.key});

  @override
  State<LeavePermitHubScreen> createState() => _LeavePermitHubScreenState();
}

class _LeavePermitHubScreenState extends State<LeavePermitHubScreen> {
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();

  String? _employeeId;
  bool _loading = true;
  Map<String, dynamic>? _balance;
  List<Map<String, dynamic>> _requests = [];
  String _selectedFilter = 'all'; // 'all', 'leave', 'permit'

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _loading = true);
    _employeeId = await AppSettings.getEmployeeId();
    await _refreshData();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refreshData() async {
    if (_employeeId == null) return;
    try {
      final bal = await _api.getLeaveBalance(_employeeId!);
      final reqs = await _api.getLeaveHistory(_employeeId!);
      if (mounted) {
        setState(() {
          _balance = bal;
          _requests = reqs;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load leave data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredRequests {
    if (_selectedFilter == 'all') return _requests;
    return _requests.where((r) => r['category'] == _selectedFilter).toList();
  }

  // --------------------------------------------------------------------------
  // LEAVE REQUEST MODAL
  // --------------------------------------------------------------------------
  void _openLeaveRequestModal() {
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now();
    String leaveType = 'annual';
    final reasonController = TextEditingController();
    File? attachmentFile;
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: Color(0xFF1E293B))),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Text('🌴 ', style: TextStyle(fontSize: 22)),
                        Text(
                          'Request Leave (Cuti)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Leave Type
                const Text('Leave Type', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: leaveType,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      items: const [
                        DropdownMenuItem(value: 'annual', child: Text('🌴 Annual Leave (Cuti Tahunan)')),
                        DropdownMenuItem(value: 'sick', child: Text('🏥 Sick Leave (Sakit)')),
                        DropdownMenuItem(value: 'unpaid', child: Text('🛑 Unpaid Leave (Cuti Diluar Tanggungan)')),
                        DropdownMenuItem(value: 'maternity', child: Text('👶 Maternity / Paternity Leave')),
                        DropdownMenuItem(value: 'special', child: Text('⭐ Special Leave')),
                      ],
                      onChanged: (v) {
                        if (v != null) setModalState(() => leaveType = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Dates Selection
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Start Date', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: startDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  startDate = picked;
                                  if (endDate.isBefore(startDate)) endDate = startDate;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 14, color: Colors.blueAccent),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('dd MMM yyyy').format(startDate),
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('End Date', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: endDate,
                                firstDate: startDate,
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setModalState(() => endDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 14, color: Colors.blueAccent),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('dd MMM yyyy').format(endDate),
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Reason
                const Text('Reason / Purpose', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'e.g. Family vacation, doctor appointment...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),

                // Attachment (Medical cert / doc)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Medical Note / Proof', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                    if (attachmentFile != null)
                      TextButton.icon(
                        onPressed: () => setModalState(() => attachmentFile = null),
                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 16),
                        label: const Text('Remove', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                    if (img != null) {
                      setModalState(() => attachmentFile = File(img.path));
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: attachmentFile != null ? kEmerald : Colors.white12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(attachmentFile != null ? Icons.check_circle : Icons.attach_file, color: attachmentFile != null ? kEmerald : Colors.blueAccent, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          attachmentFile != null ? 'Attachment selected' : 'Upload Medical Certificate / Photo',
                          style: TextStyle(color: attachmentFile != null ? kEmerald : Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: submitting
                        ? null
                        : () async {
                            if (reasonController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a reason for leave.')),
                              );
                              return;
                            }
                            setModalState(() => submitting = true);
                            try {
                              await _api.submitLeaveOrPermitRequest(
                                employeeId: _employeeId!,
                                category: 'leave',
                                leaveType: leaveType,
                                startDate: startDate,
                                endDate: endDate,
                                reason: reasonController.text.trim(),
                                attachmentFilePath: attachmentFile?.path,
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              _showSuccessFeedback('Leave application submitted for approval!');
                            } catch (e) {
                              setModalState(() => submitting = false);
                              _showErrorFeedback('Submission failed: $e');
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kEmerald,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: submitting
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : const Text('Submit Leave Application', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // PERMIT / LATE ARRIVAL MODAL
  // --------------------------------------------------------------------------
  void _openPermitRequestModal() {
    DateTime date = DateTime.now();
    TimeOfDay expectedTime = const TimeOfDay(hour: 9, minute: 30);
    String permitType = 'late_arrival';
    final reasonController = TextEditingController();
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: Color(0xFF1E293B))),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Text('⏰ ', style: TextStyle(fontSize: 22)),
                        Text(
                          'Permit / Late Arrival (Izin)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Permit Type
                const Text('Permission Type', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: permitType,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      items: const [
                        DropdownMenuItem(value: 'late_arrival', child: Text('⏰ Late Arrival Permit (Izin Datang Terlambat)')),
                        DropdownMenuItem(value: 'early_departure', child: Text('🚪 Early Departure (Izin Pulang Cepat)')),
                        DropdownMenuItem(value: 'official_duty', child: Text('🏢 Official External Duty (Izin Dinas Luar)')),
                        DropdownMenuItem(value: 'other', child: Text('📝 Other Permission (Izin Keluar Kantor)')),
                      ],
                      onChanged: (v) {
                        if (v != null) setModalState(() => permitType = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Date & Time
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Date', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: date,
                                firstDate: DateTime.now().subtract(const Duration(days: 7)),
                                lastDate: DateTime.now().add(const Duration(days: 30)),
                              );
                              if (picked != null) setModalState(() => date = picked);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 14, color: Colors.purpleAccent),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('dd MMM yyyy').format(date),
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Estimated Time', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: expectedTime,
                              );
                              if (picked != null) setModalState(() => expectedTime = picked);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time, size: 14, color: Colors.purpleAccent),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${expectedTime.hour.toString().padLeft(2, '0')}:${expectedTime.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Reason
                const Text('Reason / Explanation', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'e.g. Vehicle breakdown, urgent family matter, road flood...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: submitting
                        ? null
                        : () async {
                            if (reasonController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please state the reason for your permit.')),
                              );
                              return;
                            }
                            setModalState(() => submitting = true);
                            try {
                              final formattedTime = '${expectedTime.hour.toString().padLeft(2, '0')}:${expectedTime.minute.toString().padLeft(2, '0')}';
                              await _api.submitLeaveOrPermitRequest(
                                employeeId: _employeeId!,
                                category: 'permit',
                                permitType: permitType,
                                startDate: date,
                                expectedTime: formattedTime,
                                reason: reasonController.text.trim(),
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              _showSuccessFeedback('Permission request submitted for supervisor approval!');
                            } catch (e) {
                              setModalState(() => submitting = false);
                              _showErrorFeedback('Submission failed: $e');
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: submitting
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : const Text('Submit Permit Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessFeedback(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
      _refreshData();
    }
  }

  void _showErrorFeedback(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _balance?['remaining_days'] ?? 12;
    final used = _balance?['used_days'] ?? 0;
    final total = _balance?['annual_quota'] ?? 12;

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text('Leave & Permits Hub', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Annual Quota Summary Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'ANNUAL LEAVE QUOTA',
                                style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blueAccent.withOpacity(0.4)),
                                ),
                                child: Text(
                                  'Year ${_balance?['year'] ?? DateTime.now().year}',
                                  style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$remaining',
                                style: const TextStyle(color: kEmerald, fontSize: 36, fontWeight: FontWeight.w900, height: 1),
                              ),
                              const SizedBox(width: 8),
                              const Padding(
                                padding: EdgeInsets.only(bottom: 4),
                                child: Text('Days Remaining', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: total > 0 ? (remaining / total).clamp(0.0, 1.0) : 0.0,
                              backgroundColor: Colors.white12,
                              valueColor: const AlwaysStoppedAnimation<Color>(kEmerald),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Used: $used days', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                              Text('Total Quota: $total days', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Two Big Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _openLeaveRequestModal,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: kEmerald.withOpacity(0.4)),
                                boxShadow: [
                                  BoxShadow(color: kEmerald.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3)),
                                ],
                              ),
                              child: const Column(
                                children: [
                                  Text('🌴', style: TextStyle(fontSize: 28)),
                                  SizedBox(height: 8),
                                  Text('Request Leave', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                  SizedBox(height: 2),
                                  Text('Annual / Sick / Unpaid', style: TextStyle(color: Colors.white54, fontSize: 10)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: _openPermitRequestModal,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.purple.withOpacity(0.4)),
                                boxShadow: [
                                  BoxShadow(color: Colors.purple.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3)),
                                ],
                              ),
                              child: const Column(
                                children: [
                                  Text('⏰', style: TextStyle(fontSize: 28)),
                                  SizedBox(height: 8),
                                  Text('Late / Permit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                  SizedBox(height: 2),
                                  Text('Late Arrival / Early Out', style: TextStyle(color: Colors.white54, fontSize: 10)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // History Section Header & Filter Tabs
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My Applications',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF1E293B)),
                          ),
                          child: Row(
                            children: [
                              _buildFilterChip('all', 'All'),
                              _buildFilterChip('leave', 'Leaves'),
                              _buildFilterChip('permit', 'Permits'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Applications List
                    if (_filteredRequests.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF1E293B)),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.history, size: 36, color: Colors.white24),
                            SizedBox(height: 8),
                            Text('No applications recorded yet', style: TextStyle(color: Colors.white54, fontSize: 13)),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredRequests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, idx) {
                          final r = _filteredRequests[idx];
                          final isPermit = r['category'] == 'permit';
                          final status = r['status'] ?? 'pending';

                          Color statusColor = Colors.amber;
                          String statusText = 'Pending';
                          IconData statusIcon = Icons.hourglass_empty;

                          if (status == 'approved') {
                            statusColor = kEmerald;
                            statusText = 'Approved';
                            statusIcon = Icons.check_circle;
                          } else if (status == 'rejected') {
                            statusColor = Colors.redAccent;
                            statusText = 'Rejected';
                            statusIcon = Icons.cancel;
                          }

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: status == 'pending'
                                    ? Colors.amber.withOpacity(0.3)
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(isPermit ? '⏰' : '🌴', style: const TextStyle(fontSize: 16)),
                                        const SizedBox(width: 6),
                                        Text(
                                          isPermit
                                              ? _formatPermitType(r['permit_type'])
                                              : _formatLeaveType(r['leave_type']),
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: statusColor.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(statusIcon, size: 12, color: statusColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            statusText,
                                            style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Dates / Expected Time
                                Row(
                                  children: [
                                    const Icon(Icons.date_range, size: 13, color: Colors.white38),
                                    const SizedBox(width: 4),
                                    Text(
                                      r['start_date'] ?? '-',
                                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                    if (r['end_date'] != null && r['end_date'] != r['start_date']) ...[
                                      const Text(' → ', style: TextStyle(color: Colors.white38, fontSize: 12)),
                                      Text(
                                        r['end_date'],
                                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                    if (isPermit && r['expected_time'] != null) ...[
                                      const SizedBox(width: 10),
                                      const Icon(Icons.access_time, size: 13, color: Colors.purpleAccent),
                                      const SizedBox(width: 3),
                                      Text(
                                        '@ ${r['expected_time']}',
                                        style: const TextStyle(color: Colors.purpleAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // Reason
                                Text(
                                  '"${r['reason'] ?? 'No reason provided'}"',
                                  style: const TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic),
                                ),

                                // Admin feedback if present
                                if (r['admin_notes'] != null && (r['admin_notes'] as String).isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF020617),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.comment, size: 13, color: Colors.blueAccent),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'HR Remark: ${r['admin_notes']}',
                                            style: const TextStyle(color: Colors.blueAccent, fontSize: 11),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFilterChip(String filter, String label) {
    final active = _selectedFilter == filter;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = filter),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.white60,
            fontSize: 11,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _formatLeaveType(String? t) {
    if (t == 'annual') return 'Annual Leave';
    if (t == 'sick') return 'Sick Leave';
    if (t == 'unpaid') return 'Unpaid Leave';
    if (t == 'maternity') return 'Maternity/Paternity';
    return t ?? 'Leave';
  }

  String _formatPermitType(String? t) {
    if (t == 'late_arrival') return 'Late Arrival Permit';
    if (t == 'early_departure') return 'Early Departure';
    if (t == 'official_duty') return 'Official External Duty';
    return t ?? 'Permit';
  }
}
