import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/punch_provider.dart';
import '../../providers/network_sync_provider.dart';
import '../../services/app_settings.dart';
import '../../services/notification_service.dart';
import '../theme.dart';
import '../../database/app_database.dart';
import 'qr_scan_screen.dart';
import 'nfc_scan_screen.dart';
import 'selfie_screen.dart';
import 'settings_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/biometric_session_timer.dart';

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

Map<String, dynamic>? _parseMap(dynamic value) {
  if (value == null) return null;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

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
  final MapController _mapController = MapController();
  String _lastGeofenceState = 'unknown';
  String? _locationError;
  // Track whether the map has been centered at least once so we stop
  // forcefully re-centering on every GPS update (fixes "kept locating" bug).
  bool _mapCenteredOnce = false;

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
    Geolocator.isLocationServiceEnabled().then((enabled) {
      if (!enabled && mounted) {
        setState(() {
          _locationError = "Location Services (GPS) Disabled. Enable GPS.";
        });
      }
    });

    // ── Grab one position immediately so the UI doesn't sit on "Acquiring…" ──
    Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    ).then((position) {
      if (mounted && _currentPosition == null) {
        setState(() {
          _currentPosition = position;
          _locationError = null;
        });
        if (!_mapCenteredOnce) {
          _mapCenteredOnce = true;
          try {
            _mapController.move(LatLng(position.latitude, position.longitude), 16.0);
          } catch (_) {}
        }
      }
    }).catchError((_) {}); // non-fatal — the stream below will deliver positions too

    // ── Continuous stream ─────────────────────────────────────────────────────
    _startPositionStream(withForegroundService: Platform.isAndroid);
  }

  /// Starts the GPS position stream. If [withForegroundService] is true and the
  /// foreground-service stream fails (missing permissions on some OEM ROMs),
  /// it automatically retries with a plain [LocationSettings] stream.
  void _startPositionStream({bool withForegroundService = false}) {
    LocationSettings locationSettings;
    if (withForegroundService) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        intervalDuration: const Duration(seconds: 10),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "Tracking geofence for clock-in reminders",
          notificationTitle: "Attendance Tracker Active",
          enableWakeLock: true,
        ),
      );
    } else if (Platform.isIOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );
    }

    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _locationError = null;
        });
        _processGeofenceNotifications(position);
        if (!_mapCenteredOnce) {
          _mapCenteredOnce = true;
          try {
            _mapController.move(LatLng(position.latitude, position.longitude), 16.0);
          } catch (_) {}
        }
      }
    }, onError: (error) {
      if (mounted) {
        // If the foreground-service variant failed, fall back to a plain stream
        if (withForegroundService) {
          debugPrint('[GeolocatorFallback] Foreground service stream failed ($error), retrying without it.');
          _startPositionStream(withForegroundService: false);
          return;
        }
        setState(() {
          _locationError = "GPS Error: $error";
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
    _mapController.dispose();
    super.dispose();
  }

  /// Request location permission upfront so Android shows the dialog
  /// immediately on first launch rather than silently failing later.
  Future<void> _requestPermissionsOnStartup() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationError = "GPS/Location Services Disabled. Enable in Settings.";
      });
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationError = "Location permission denied.";
        });
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationError = "Location permission permanently denied. Enable in Settings.";
      });
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

  List<LatLng> _parsePolygonCoordinates(dynamic rawCoords) {
    if (rawCoords == null) return [];
    try {
      List<dynamic> list;
      if (rawCoords is String) {
        list = jsonDecode(rawCoords) as List<dynamic>;
      } else if (rawCoords is List) {
        list = rawCoords;
      } else {
        return [];
      }
      return list.map((pt) {
        if (pt is List && pt.length >= 2) {
          return LatLng(_parseDouble(pt[0]) ?? 0.0, _parseDouble(pt[1]) ?? 0.0);
        }
        return const LatLng(0, 0);
      }).where((pt) => pt.latitude != 0 || pt.longitude != 0).toList();
    } catch (e) {
      return [];
    }
  }

  bool _isPointInPolygon(double lat, double lon, List<LatLng> polygon) {
    bool inside = false;
    int n = polygon.length;
    if (n < 3) return false;
    double p1x = polygon[0].latitude;
    double p1y = polygon[0].longitude;
    for (int i = 0; i <= n; i++) {
      double p2x = polygon[i % n].latitude;
      double p2y = polygon[i % n].longitude;
      if (lat > math.min(p1x, p2x) && lat <= math.max(p1x, p2x)) {
        if (lon <= math.max(p1y, p2y)) {
          if (p1x != p2x) {
            double xints = (lat - p1x) * (p2y - p1y) / (p2x - p1x) + p1y;
            if (p1y == p2y || lon <= xints) {
              inside = !inside;
            }
          }
        }
      }
      p1x = p2x;
      p1y = p2y;
    }
    return inside;
  }

  bool _checkIsInside(Map<String, dynamic> cp, Position position, double dist) {
    final geofenceType = cp['geofence_type'] as String? ?? 'circle';
    if (geofenceType == 'polygon') {
      final polygonCoords = _parsePolygonCoordinates(cp['polygon_coordinates']);
      if (polygonCoords.length >= 3) {
        return _isPointInPolygon(position.latitude, position.longitude, polygonCoords);
      }
    }
    final cpRadius = cp['radius_meters'] as double? ?? 50.0;
    return dist <= cpRadius;
  }

  void _processGeofenceNotifications(Position position) {
    final deviceConfig = ref.read(deviceConfigProvider).value;
    if (deviceConfig == null) return;

    final branchesList = deviceConfig['branches'] as List<dynamic>?;
    final List<Map<String, dynamic>> allGeofences = [];
    if (branchesList != null) {
      for (final branch in branchesList) {
        if (branch is Map) {
          allGeofences.add({
            'id': branch['id'],
            'name': branch['name'] as String? ?? 'Branch',
            'latitude': _parseDouble(branch['latitude']),
            'longitude': _parseDouble(branch['longitude']),
            'radius_meters': _parseDouble(branch['radius_meters']) ?? 50.0,
            'geofence_type': branch['geofence_type'] as String? ?? 'circle',
            'polygon_coordinates': branch['polygon_coordinates'],
            'is_checkpoint': false,
          });
          
          final cps = branch['checkpoints'] as List<dynamic>?;
          if (cps != null) {
            for (final cp in cps) {
              if (cp is Map && cp['is_active'] == true) {
                allGeofences.add({
                  'id': cp['id'],
                  'branch_id': cp['branch_id'],
                  'name': cp['name'] as String? ?? 'Checkpoint',
                  'latitude': _parseDouble(cp['latitude'] ?? cp['lat']),
                  'longitude': _parseDouble(cp['longitude'] ?? cp['lon']),
                  'radius_meters': _parseDouble(cp['radius_meters'] ?? cp['radius']) ?? 50.0,
                  'geofence_type': cp['geofence_type'] as String? ?? 'circle',
                  'polygon_coordinates': cp['polygon_coordinates'],
                  'is_checkpoint': true,
                });
              }
            }
          }
        }
      }
    } else if (deviceConfig['latitude'] != null) {
      allGeofences.add({
        'id': deviceConfig['branch_id'] ?? 0,
        'name': deviceConfig['branch_name'] ?? 'Branch',
        'latitude': _parseDouble(deviceConfig['latitude']),
        'longitude': _parseDouble(deviceConfig['longitude']),
        'radius_meters': _parseDouble(deviceConfig['radius_meters']) ?? 50.0,
        'geofence_type': deviceConfig['geofence_type'] as String? ?? 'circle',
        'polygon_coordinates': deviceConfig['polygon_coordinates'],
        'is_checkpoint': false,
      });
    }

    if (allGeofences.isEmpty) return;

    Map<String, dynamic>? activeCheckpoint;
    String status = 'outside'; // 'inside', 'near', 'outside'

    Map<String, dynamic>? nearestInside;
    double minInsideDist = double.infinity;

    Map<String, dynamic>? nearestNear;
    double minNearDist = double.infinity;

    Map<String, dynamic>? nearestOutside;
    double minOutsideDist = double.infinity;

    for (final cp in allGeofences) {
      final cpLat = cp['latitude'] as double?;
      final cpLng = cp['longitude'] as double?;
      final cpRadius = cp['radius_meters'] as double? ?? 50.0;
      final isPolygon = (cp['geofence_type'] as String? ?? 'circle') == 'polygon';

      if (cpLat != null && cpLng != null) {
        final dist = _haversineDistance(
          position.latitude,
          position.longitude,
          cpLat,
          cpLng,
        );

        final isInside = _checkIsInside(cp, position, dist);

        if (isInside) {
          if (dist < minInsideDist) {
            minInsideDist = dist;
            nearestInside = cp;
          }
        } else if (!isPolygon && dist <= cpRadius * 1.3) {
          // "Near" only applies to circular fences (polygon fences use
          // point-in-polygon; there is no meaningful perimeter radius).
          if (dist < minNearDist) {
            minNearDist = dist;
            nearestNear = cp;
          }
        } else {
          if (dist < minOutsideDist) {
            minOutsideDist = dist;
            nearestOutside = cp;
          }
        }
      }
    }

    if (nearestInside != null) {
      activeCheckpoint = nearestInside;
      status = 'inside';
    } else if (nearestNear != null) {
      activeCheckpoint = nearestNear;
      status = 'near';
    } else if (nearestOutside != null) {
      activeCheckpoint = nearestOutside;
      status = 'outside';
    }

    if (status != _lastGeofenceState) {
      final oldState = _lastGeofenceState;
      _lastGeofenceState = status;

      if (activeCheckpoint != null) {
        final name = activeCheckpoint['name'] ?? 'Checkpoint';
        if (status == 'inside' && oldState != 'inside') {
          NotificationService.showLocalNotification(
            id: 999,
            title: "Inside Geofence Area",
            body: "You have entered the $name geofence. Don't forget to clock in!",
          );
        } else if (status == 'near' && oldState == 'outside') {
          NotificationService.showLocalNotification(
            id: 998,
            title: "Approaching Checkpoint",
            body: "You are getting close to $name. Prepare to record attendance.",
          );
        }
      }
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

    final queueAsync = ref.watch(offlineQueueProvider);

    return Stack(
      children: [
        Container(
          color: Theme.of(context).colorScheme.surface,
          child: Column(
        children: [
          // Header Widget (Moved to the very top, out of map)
          deviceConfig.when(
            data: (config) {
              final branchesList = config['branches'] as List<dynamic>?;
              final firstBranch = branchesList != null && branchesList.isNotEmpty
                  ? _parseMap(branchesList[0])
                  : null;
              return _HeaderWidget(
                employeeId: _employeeId.isEmpty ? 'Not configured' : _employeeId,
                employeeName: config['employee_name'] as String?,
                isConfigured: _isConfigured,
                onSetupTap: _openSettings,
                onRefresh: () => ref.invalidate(deviceConfigProvider),
                branches: branchesList?.map((b) => _parseMap(b)?['name'] as String? ?? '').where((name) => name.isNotEmpty).toList(),
                branchName: firstBranch?['name'] as String? ?? config['branch_name'] as String?,
                deviceCount: config['device_count'] as int?,
                maxDevices: config['max_devices'] as int?,
                lastAuthTime: punchState.lastBiometricAuthTime,
                sessionSeconds: punchState.biometricSessionSeconds,
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
                  ? _parseMap(branchesList[0])
                  : null;
              
              double? branchLat = _parseDouble(firstBranch?['latitude'] ?? config['latitude']);
              double? branchLng = _parseDouble(firstBranch?['longitude'] ?? config['longitude']);

              // Build a flat list of all valid geofence areas: branch center + any active checkpoints (multipoints)
              final List<Map<String, dynamic>> allGeofences = [];
              if (branchesList != null) {
                for (final branch in branchesList) {
                  if (branch is Map) {
                    allGeofences.add({
                      'id': branch['id'],
                      'name': branch['name'] as String? ?? 'Branch',
                      'latitude': _parseDouble(branch['latitude']),
                      'longitude': _parseDouble(branch['longitude']),
                      'radius_meters': _parseDouble(branch['radius_meters']) ?? 50.0,
                      'geofence_type': branch['geofence_type'] as String? ?? 'circle',
                      'polygon_coordinates': branch['polygon_coordinates'],
                      'is_checkpoint': false,
                    });
                    
                    final cps = branch['checkpoints'] as List<dynamic>?;
                    if (cps != null) {
                      for (final cp in cps) {
                        if (cp is Map && cp['is_active'] == true) {
                          allGeofences.add({
                            'id': cp['id'],
                            'branch_id': cp['branch_id'],
                            'name': cp['name'] as String? ?? 'Checkpoint',
                            'latitude': _parseDouble(cp['latitude'] ?? cp['lat']),
                            'longitude': _parseDouble(cp['longitude'] ?? cp['lon']),
                            'radius_meters': _parseDouble(cp['radius_meters'] ?? cp['radius']) ?? 50.0,
                            'geofence_type': cp['geofence_type'] as String? ?? 'circle',
                            'polygon_coordinates': cp['polygon_coordinates'],
                            'is_checkpoint': true,
                          });
                        }
                      }
                    }
                  }
                }
              } else if (config['latitude'] != null) {
                allGeofences.add({
                  'id': config['branch_id'] ?? 0,
                  'name': config['branch_name'] ?? 'Branch',
                  'latitude': _parseDouble(config['latitude']),
                  'longitude': _parseDouble(config['longitude']),
                  'radius_meters': _parseDouble(config['radius_meters']) ?? 50.0,
                  'geofence_type': config['geofence_type'] as String? ?? 'circle',
                  'polygon_coordinates': config['polygon_coordinates'],
                  'is_checkpoint': false,
                });
              }

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
                        mapController: _mapController,
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
                                ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                                : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                            subdomains: const ['a', 'b', 'c', 'd'],
                          ),
                          PolygonLayer(
                            polygons: allGeofences
                                .where((b) => b['geofence_type'] == 'polygon' && b['polygon_coordinates'] != null)
                                .map((b) {
                                  final isCp = b['is_checkpoint'] == true;
                                  final fillColor = isCp
                                      ? AppTheme.primaryCyan.withOpacity(0.15)
                                      : AppTheme.secondaryViolet.withOpacity(0.15);
                                  final borderColor = isCp
                                      ? AppTheme.primaryCyan.withOpacity(0.7)
                                      : AppTheme.secondaryViolet.withOpacity(0.7);
                                  final coords = _parsePolygonCoordinates(b['polygon_coordinates']);
                                  return Polygon(
                                    points: coords,
                                    color: fillColor,
                                    borderColor: borderColor,
                                    borderStrokeWidth: isCp ? 1.5 : 2.0,
                                    isFilled: true,
                                  );
                                })
                                .toList(),
                          ),
                          CircleLayer(
                            circles: allGeofences
                                .where((b) => b['geofence_type'] != 'polygon' && b['latitude'] != null && b['longitude'] != null)
                                .map((b) {
                                  final isCp = b['is_checkpoint'] == true;
                                  final circleColor = isCp 
                                      ? AppTheme.primaryCyan.withOpacity(0.15) 
                                      : AppTheme.secondaryViolet.withOpacity(0.15);
                                  final borderColor = isCp 
                                      ? AppTheme.primaryCyan.withOpacity(0.7) 
                                      : AppTheme.secondaryViolet.withOpacity(0.7);
                                  return CircleMarker(
                                    point: LatLng(b['latitude'] as double, b['longitude'] as double),
                                    color: circleColor,
                                    borderStrokeWidth: isCp ? 1.5 : 2,
                                    borderColor: borderColor,
                                    useRadiusInMeter: true,
                                    radius: b['radius_meters'] as double,
                                  );
                                })
                                .toList(),
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
                                      color: Colors.blueAccent,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                      boxShadow: [
                                        BoxShadow(color: Colors.blueAccent.withOpacity(0.4), blurRadius: 15, spreadRadius: 6),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      // Locate-me button — re-centers map on user's position on tap
                      Positioned(
                        bottom: 64,
                        right: 12,
                        child: GestureDetector(
                          onTap: () {
                            if (_currentPosition != null) {
                              _mapController.move(
                                LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                16.0,
                              );
                            }
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.4)),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)],
                            ),
                            child: const Icon(Icons.my_location, color: Colors.white, size: 18),
                          ),
                        ),
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
                                        : (_locationError != null ? 'Error' : 'Acquiring...'),
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
                            // Calculate live distance from current position to nearest active geofence/checkpoint
                            String badgeText = _locationError ?? 'Locating...';
                            Color badgeColor = _locationError != null ? AppTheme.errorRed : Colors.grey;
                            IconData badgeIcon = _locationError != null ? Icons.location_off : Icons.location_searching;

                            if (_currentPosition != null) {
                              final List<Map<String, dynamic>> checkpoints = allGeofences;
                              Map<String, dynamic>? activeCheckpoint;
                              double activeDistance = double.infinity;
                              String status = 'outside'; // 'inside', 'near', 'outside'

                              Map<String, dynamic>? nearestInside;
                              double minInsideDist = double.infinity;

                              Map<String, dynamic>? nearestNear;
                              double minNearDist = double.infinity;

                              Map<String, dynamic>? nearestOutside;
                              double minOutsideDist = double.infinity;

                              for (final cp in checkpoints) {
                                final cpLat = cp['latitude'] as double?;
                                final cpLng = cp['longitude'] as double?;
                                final cpRadius = cp['radius_meters'] as double? ?? 50.0;
                                final isCpPolygon = (cp['geofence_type'] as String? ?? 'circle') == 'polygon';

                                if (cpLat != null && cpLng != null) {
                                  final dist = _haversineDistance(
                                    _currentPosition!.latitude,
                                    _currentPosition!.longitude,
                                    cpLat,
                                    cpLng,
                                  );

                                  final isInside = _checkIsInside(cp, _currentPosition!, dist);

                                  if (isInside) {
                                    if (dist < minInsideDist) {
                                      minInsideDist = dist;
                                      nearestInside = cp;
                                    }
                                  } else if (!isCpPolygon && dist <= cpRadius * 1.3) {
                                    // "Near" only applies to circular fences.
                                    if (dist < minNearDist) {
                                      minNearDist = dist;
                                      nearestNear = cp;
                                    }
                                  } else {
                                    if (dist < minOutsideDist) {
                                      minOutsideDist = dist;
                                      nearestOutside = cp;
                                    }
                                  }
                                }
                              }

                              if (nearestInside != null) {
                                activeCheckpoint = nearestInside;
                                activeDistance = minInsideDist;
                                status = 'inside';
                              } else if (nearestNear != null) {
                                activeCheckpoint = nearestNear;
                                activeDistance = minNearDist;
                                status = 'near';
                              } else if (nearestOutside != null) {
                                activeCheckpoint = nearestOutside;
                                activeDistance = minOutsideDist;
                                status = 'outside';
                              }

                              if (activeCheckpoint != null) {
                                final name = activeCheckpoint['name'] ?? 'Checkpoint';
                                if (status == 'inside') {
                                  badgeText = '✓ Inside $name (${activeDistance.toStringAsFixed(0)}m)';
                                  badgeColor = AppTheme.successGreen;
                                  badgeIcon = Icons.check_circle_outline;
                                } else if (status == 'near') {
                                  badgeText = '⚠ Near $name (${activeDistance.toStringAsFixed(0)}m)';
                                  badgeColor = Colors.orange;
                                  badgeIcon = Icons.warning_amber_outlined;
                                } else {
                                  badgeText = '✗ Outside Geofence (Nearest: $name, ${activeDistance.toStringAsFixed(0)}m away)';
                                  badgeColor = AppTheme.errorRed;
                                  badgeIcon = Icons.location_off_outlined;
                                }
                              }
                            }

                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
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
                                  ),
                                  if (branchesList != null && branchesList.length > 1)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                                        ),
                                        child: Text(
                                          'Multipoint Branch Active',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
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
            child: SafeArea(
              bottom: true,
              child: Container(
                padding: const EdgeInsets.all(24.0),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 16),

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
                      Builder(builder: (context) {
                        String gpsText = _locationError ?? 'Locating GPS...';
                        Color gpsColor = _locationError != null ? AppTheme.errorRed : Colors.grey;
                        if (_currentPosition != null) {
                          if (_currentPosition!.accuracy < 20) {
                            gpsText = 'GPS Signal Strong (±${_currentPosition!.accuracy.toStringAsFixed(0)}m)';
                            gpsColor = AppTheme.successGreen;
                          } else if (_currentPosition!.accuracy < 50) {
                            gpsText = 'GPS Signal Moderate (±${_currentPosition!.accuracy.toStringAsFixed(0)}m)';
                            gpsColor = Colors.orange;
                          } else {
                            gpsText = 'GPS Signal Weak (±${_currentPosition!.accuracy.toStringAsFixed(0)}m)';
                            gpsColor = AppTheme.errorRed;
                          }
                        }
                        
                        final config = deviceConfig.value;
                        final isCached = config != null && config['_cached'] == true;
                        final pendingSyncCount = ref.watch(syncStateProvider).pendingCount;
                        
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.circle, size: 8, color: gpsColor),
                                const SizedBox(width: 8),
                                Text(gpsText, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w500)),
                              ],
                            ),
                            if (isCached || pendingSyncCount > 0) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isCached ? Icons.cloud_off : Icons.cloud_queue,
                                    size: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isCached
                                        ? 'Offline Mode Active'
                                        : 'Pending Sync ($pendingSyncCount punch(es))',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        );
                      }),
                      const SizedBox(height: 24),
                      Text('\u00A9 ${DateTime.now().year} IT Dept HRM Group', style: TextStyle(color: Colors.grey.shade600, fontSize: 11), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),

            const SizedBox(height: 16),
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
    ), // SafeArea
          ), // Expanded
        ], // Column children
      ), // Column
    ),
        queueAsync.when(
          data: (queue) {
            if (queue.isEmpty) return const SizedBox.shrink();
            return _OfflineQueueDrawer(queue: queue);
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ─── Offline Sync Drawer ──────────────────────────────────────────────────────
// Glassmorphic slide-up bottom drawer containing the detailed offline log queue.
class _OfflineQueueDrawer extends ConsumerWidget {
  final List<OfflinePunche> queue;
  const _OfflineQueueDrawer({required this.queue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStateProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.12,
      minChildSize: 0.12,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xE60F172A)
                    : const Color(0xE6FFFFFF),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.08),
                  width: 1.5,
                ),
              ),
              child: CustomScrollView(
                controller: scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.2)
                                : Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorRed.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.errorRed.withOpacity(0.4)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.cloud_off_rounded, color: AppTheme.errorRed, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${queue.length} Pending Sync',
                                      style: const TextStyle(
                                        color: AppTheme.errorRed,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              if (syncState.status == SyncStatus.syncing)
                                const SizedBox(
                                  width: 24, height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF009CA6)),
                                )
                              else
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF009CA6),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  onPressed: () async {
                                    await HapticFeedback.mediumImpact();
                                    await ref.read(networkSyncProvider).syncOfflinePunches();
                                  },
                                  icon: const Icon(Icons.sync_rounded, size: 16),
                                  label: const Text('SYNC NOW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final punch = queue[index];
                        final isOut = punch.punchType.toLowerCase().contains('out');
                        final punchColor = isOut ? Colors.red.shade600 : AppTheme.primaryCyan;
                        
                        IconData statusIcon = Icons.cloud_queue_rounded;
                        Color statusColor = Colors.blue;
                        String statusLabel = 'Awaiting Sync';

                        if (punch.syncStatus == 'failed') {
                          statusIcon = Icons.warning_amber_rounded;
                          statusColor = Colors.orange;
                          statusLabel = 'Sync Failed (Will Retry)';
                        } else if (punch.syncStatus == 'failed_permanent') {
                          statusIcon = Icons.error_outline_rounded;
                          statusColor = Colors.red;
                          statusLabel = 'Failed Permanent';
                        } else if (punch.syncStatus == 'expired_pending_review') {
                          statusIcon = Icons.lock_clock;
                          statusColor = Colors.amber;
                          statusLabel = 'Pending Review (> 24h)';
                        }

                        String formattedTime = punch.timestamp;
                        try {
                          final parsed = DateTime.parse(punch.timestamp);
                          formattedTime = "${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')} "
                              "${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}:${parsed.second.toString().padLeft(2, '0')}";
                        } catch (_) {}

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark 
                                ? Colors.white.withOpacity(0.03) 
                                : Colors.black.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark 
                                  ? Colors.white.withOpacity(0.06) 
                                  : Colors.black.withOpacity(0.05),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: punchColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    punch.punchType.toUpperCase(),
                                    style: TextStyle(
                                      color: isDark ? Colors.white : Colors.black,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (punch.retryCount > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Retries: ${punch.retryCount}',
                                        style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade500),
                                  const SizedBox(width: 6),
                                  Text(
                                    formattedTime,
                                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.location_on_rounded, size: 14, color: Colors.grey.shade500),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${punch.latitude.toStringAsFixed(5)}, ${punch.longitude.toStringAsFixed(5)}',
                                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                                  ),
                                ],
                              ),
                              if (punch.errorMessage != null && punch.errorMessage!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: statusColor.withOpacity(0.2)),
                                  ),
                                  child: Text(
                                    punch.errorMessage!,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(statusIcon, color: statusColor, size: 13),
                                  const SizedBox(width: 6),
                                  Text(
                                    statusLabel,
                                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: queue.length,
                    ),
                  ),
                  SliverPadding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 20)),
                ],
              ),
            ),
          ),
        );
      },
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

class BiometricPadlock extends StatefulWidget {
  final DateTime? lastAuthTime;
  final int sessionSeconds;

  const BiometricPadlock({
    super.key,
    required this.lastAuthTime,
    required this.sessionSeconds,
  });

  @override
  State<BiometricPadlock> createState() => _BiometricPadlockState();
}

class _BiometricPadlockState extends State<BiometricPadlock> with SingleTickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _pulseController;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    
    _checkActive();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkActive();
    });
  }

  @override
  void didUpdateWidget(covariant BiometricPadlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkActive();
  }

  void _checkActive() {
    if (widget.lastAuthTime == null || widget.sessionSeconds <= 0) {
      if (_isActive) {
        setState(() {
          _isActive = false;
        });
      }
      return;
    }
    final elapsed = DateTime.now().difference(widget.lastAuthTime!).inSeconds;
    final active = elapsed < widget.sessionSeconds;
    if (active != _isActive) {
      setState(() {
        _isActive = active;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isActive) {
      return Icon(
        Icons.lock_outline,
        size: 18,
        color: Colors.grey.shade500,
      );
    }

    return ScaleTransition(
      scale: Tween<double>(begin: 0.9, end: 1.1).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
      ),
      child: const Icon(
        Icons.lock_open_rounded,
        size: 18,
        color: AppTheme.successGreen,
      ),
    );
  }
}

class _HeaderWidget extends StatelessWidget {
  final String employeeId;
  final String? employeeName;
  final bool isConfigured;
  final VoidCallback onSetupTap;
  final VoidCallback onRefresh;
  final List<String>? branches;
  final String? branchName;
  final int? deviceCount;
  final int? maxDevices;
  final DateTime? lastAuthTime;
  final int sessionSeconds;

  const _HeaderWidget({
    required this.employeeId,
    this.employeeName,
    required this.isConfigured,
    required this.onSetupTap,
    required this.onRefresh,
    this.branches,
    this.branchName,
    this.deviceCount,
    this.maxDevices,
    this.lastAuthTime,
    this.sessionSeconds = 0,
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
            child: isConfigured ? null : Icon(Icons.person_off, color: Theme.of(context).colorScheme.onSurface, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isConfigured ? (employeeName ?? employeeId) : 'Setup Required',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (isConfigured) ...[
                      const SizedBox(width: 8),
                      BiometricPadlock(
                        lastAuthTime: lastAuthTime,
                        sessionSeconds: sessionSeconds,
                      ),
                    ],
                  ],
                ),
                if (isConfigured && employeeName != null && employeeName!.isNotEmpty)
                  Text(
                    employeeId,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
            icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.onSurface),
            tooltip: 'Refresh Status',
            onPressed: onRefresh,
          ),
          IconButton(
            icon: Icon(Icons.notifications_none, color: Theme.of(context).colorScheme.onSurface),
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
      decoration: AppTheme.glassDecoration(context: context, borderRadius: 16).copyWith(
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
      decoration: AppTheme.glassDecoration(context: context, borderRadius: 16).copyWith(
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
      decoration: AppTheme.glassDecoration(context: context, borderRadius: 20).copyWith(
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
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final border = isOut
        ? Border.all(color: isDark ? Colors.red.withOpacity(0.5) : Colors.red.shade300, width: 1.5)
        : Border.all(color: isDark ? primary.withOpacity(0.5) : primary.withOpacity(0.5), width: 1.5);
        
    final bgColor = isOut 
        ? (isDark ? Colors.red.withOpacity(0.1) : Colors.red.shade50)
        : (isDark ? primary.withOpacity(0.15) : primary.withOpacity(0.15));
        
    final textColor = isDark ? Colors.white : (isOut ? Colors.red.shade700 : primary);
    final iconColor = isDark ? (isOut ? Colors.red.shade400 : primary) : (isOut ? Colors.red.shade700 : primary);
    
    final shadow = BoxShadow(
      color: isOut ? Colors.red.withOpacity(0.1) : primary.withOpacity(0.2),
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
                        ? SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(
                              color: iconColor,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(widget.icon, color: iconColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.loading ? 'Processing...' : widget.label,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (!widget.loading)
                    Icon(Icons.arrow_forward_ios, color: textColor.withOpacity(0.5), size: 20),
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
      decoration: AppTheme.glassDecoration(context: context, borderRadius: 16).copyWith(
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
      decoration: AppTheme.glassDecoration(context: context, borderRadius: 16).copyWith(
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
