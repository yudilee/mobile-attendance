# Attendance Mobile App

A Flutter-based mobile attendance application that replaces traditional fingerprint machines. Features offline-first architecture, GPS geofencing, biometric verification, and optional selfie/QR verification.

## 📱 Features

### Core Punching
- **Biometric Clock In/Out** — Fingerprint or face unlock before each punch
- **GPS Geofence Verification** — Confirms you're at your office location
- **Offline Mode** — Punches queue locally and sync automatically when online
- **Multiple Punch Types** — Clock In, Clock Out, Break, Overtime, etc.
- **Duplicate Protection** — Prevents accidental double-punches

### Attendance Dashboard
- **Today's Summary** — Work duration, status (Present/Late/Absent), punch times
- **Weekly Overview** — Present days, total hours, daily color indicators
- **Monthly Stats** — Attendance percentage, late/absence counts

### Verification Methods
- **Biometric** — Device fingerprint or face unlock
- **Selfie** — Front-camera photo verification (optional)
- **QR Code** — Scan office QR code for physical presence proof (optional)
- **NFC** — Tap NFC tag at entrance (optional)

### Security
- **Certificate Pinning** — Prevents man-in-the-middle attacks
- **Root/Jailbreak Detection** — Blocks punching on compromised devices
- **Biometric Session** — Configurable re-authentication timeout
- **Secure Storage** — API key encrypted in Android Keystore
- **Mock Location Detection** — GPS spoofing attempts flagged

### Connectivity
- **Push Notifications** — Punch reminders and alerts (via Firebase)
- **Automatic Sync** — Offline queue processed when connection returns
- **Version Enforcement** — Update required if app version is too old

### Supervisor Features
- **Team View** — Real-time attendance status of team members
- **History Access** — View team member punch history
- **Correction Management** — Approve/reject attendance corrections

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.24+ ([Install Flutter](https://flutter.dev/docs/get-started/install))
- Dart SDK 3.4+
- Android device running Android 8.0+ (API 26+)
- Backend server URL and API key (provided by IT admin)

### Installation

```bash
# Clone the repository
git clone <repo-url>
cd mobile

# Install dependencies
flutter pub get

# Generate database code (if modifying drift tables)
dart run build_runner build

# Run on connected device
flutter run

# Build APK
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

### First-Time Setup

1. **Open the app** — You'll see the Settings screen
2. **Enter Server URL** — Provided by your IT administrator
3. **Enter API Key** — Unique key linked to your employee account
4. **Enable Biometric** — Recommended for security (Settings → Security)
5. **Grant Location Permission** — Required for geofence verification
6. **Tap the Punch tab** — If configured correctly, you'll see "Ready to Punch"

## 📲 Usage Guide

### Clocking In/Out

```
Punch Tab → Select Type → Biometric Auth → GPS Check → [Selfie/QR] → Done!
```

1. Navigate to the **Punch tab** (fingerprint icon)
2. Select punch type: Clock In, Clock Out, Break Start, etc.
3. Authenticate with fingerprint or face unlock
4. Wait for GPS geofence verification (must be within office area)
5. Take optional selfie if prompted
6. Scan optional QR code if required by your branch
7. Confirm — punch is recorded and synced

### Offline Mode

If you lose internet connection:
- The app continues to work normally
- Punches are stored locally on your device
- When connection returns, punches sync automatically
- Check sync status in the History tab

### Viewing Dashboard

The Dashboard tab (first tab) shows:
- **Today's work hours** calculated from clock-in/out times
- **Weekly attendance** with colored day indicators
- **Monthly statistics** with attendance percentage

### Push Notifications

If enabled by your company, you'll receive:
- Morning reminder to clock in (8:00 AM)
- Evening reminder to clock out
- Missed punch alerts
- Geofence enter/exit notifications

## 🛠️ Tech Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Framework** | Flutter 3.24+ | Cross-platform UI |
| **Language** | Dart 3.4+ | Application logic |
| **State Management** | Riverpod | Reactive state |
| **Local Database** | Drift (SQLite) | Offline queue & cache |
| **HTTP Client** | Dio | API communication |
| **Biometrics** | local_auth | Fingerprint/face auth |
| **Location** | geolocator | GPS coordinates |
| **Secure Storage** | flutter_secure_storage | API key storage |
| **QR Scanning** | mobile_scanner | QR code verification |
| **Selfie Capture** | image_picker | Attendance selfies |
| **Push Notifications** | firebase_messaging | FCM integration |
| **NFC** | nfc_manager | NFC tag verification |
| **Connectivity** | connectivity_plus | Online/offline detection |
| **NTP** | ntp | GPS time validation |
| **Device Info** | device_info_plus | Device UUID generation |

## 🔧 Configuration

### App Settings (accessible in-app)

| Setting | Description | Default |
|---------|-------------|---------|
| Server URL | Backend API address | — |
| API Key | Authentication key | — |
| Use Biometric | Require fingerprint/face before punch | On |
| Biometric Session | Re-authentication interval | 30 seconds |
| Certificate Pinning | Enable MITM protection | Off |
| Selfie Verification | Require selfie on punch | Off |
| QR Verification | Require QR scan on punch | Off |
| NFC Verification | Require NFC tap on punch | Off |
| Push Notifications | Enable/disable all notifications | On |
| Punch Reminders | Clock in/out reminders | On |
| Dark Mode | Toggle dark theme | System default |

## 🗄️ Local Database Schema

### Tables (Drift/SQLite)

| Table | Purpose |
|-------|---------|
| `offline_punches` | Queue of unsynced punches with retry tracking |
| `punch_history` | Local copy of synced punch records |
| `cached_config` | Branch/geofence data for offline use |
| `cached_punch_types` | Cached punch type definitions |

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run specific test
flutter test test/punch_provider_test.dart

# Run with coverage
flutter test --coverage
```

## 🔐 Security Features

### Implemented
- ✅ API key stored in Android Keystore (encrypted at rest)
- ✅ Certificate pinning (configurable toggle)
- ✅ Root/jailbreak detection
- ✅ Biometric authentication before punch
- ✅ Configurable biometric session timeout
- ✅ GPS mock location detection
- ✅ NTP time validation

### Server-Enforced
- ✅ Rate limiting (10 punches/minute)
- ✅ Timestamp validation (±5 minutes)
- ✅ Daily punch limit (configurable)
- ✅ Duplicate punch detection (5 minute window)
- ✅ API key expiration and revocation

## 📦 Dependencies

Key packages (see `pubspec.yaml` for full list):

```yaml
dependencies:
  flutter_riverpod: ^2.6.0     # State management
  drift: ^2.22.0               # Local database
  dio: ^5.7.0                  # HTTP client
  geolocator: ^13.0.0          # GPS location
  local_auth: ^2.3.0           # Biometric auth
  flutter_secure_storage: ^9.2.0  # Encrypted storage
  mobile_scanner: ^6.0.0       # QR scanner
  image_picker: ^1.1.0         # Camera capture
  firebase_messaging: ^15.1.0  # Push notifications
  nfc_manager: ^3.4.0          # NFC reader
  connectivity_plus: ^6.1.0    # Network status
```

## 🏗️ Project Structure

```
mobile/
├── lib/
│   ├── main.dart                    # App entry point + Firebase init
│   ├── database/
│   │   ├── app_database.dart        # Drift database definition
│   │   └── app_database.g.dart      # Generated code
│   ├── providers/
│   │   ├── punch_provider.dart      # Punch state management
│   │   └── network_sync_provider.dart# Background sync state
│   ├── services/
│   │   ├── api_service.dart         # HTTP client + endpoints
│   │   ├── app_settings.dart        # SharedPreferences manager
│   │   ├── attendance_calculator.dart# Dashboard computations
│   │   ├── app_docs.dart            # Help documentation data
│   │   ├── notification_service.dart# FCM push notifications
│   │   ├── offline_sync_service.dart# Offline queue management
│   │   └── security_service.dart    # Biometrics + root detection
│   └── ui/
│       ├── theme.dart               # App theme configuration
│       └── screens/
│           ├── home_screen.dart     # Main tab navigation
│           ├── punch_tab.dart       # Clock in/out interface
│           ├── dashboard_screen.dart# Attendance summary
│           ├── history_screen.dart  # Punch history list
│           ├── settings_screen.dart # App configuration
│           ├── help_screen.dart     # In-app documentation
│           ├── qr_scan_screen.dart  # QR code scanner
│           └── selfie_screen.dart   # Selfie capture
├── test/
│   ├── attendance_calculator_test.dart
│   ├── punch_provider_test.dart
│   ├── security_service_test.dart
│   └── widget_test.dart
├── android/
│   └── app/src/main/AndroidManifest.xml
├── pubspec.yaml
└── README.md
```

## 🔄 Punch Lifecycle

```
1. User selects punch type
2. Biometric verification (fingerprint/face)
3. GPS location check against geofence
4. [Optional] Selfie capture
5. [Optional] QR code scan
6. 
   ├── Online: Submit to server → Server validates → Store in DB → Queue ADMS sync
   └── Offline: Store locally in SQLite → Queue for later batch sync
7. 
   ├── Success: Show confirmation → Update dashboard
   └── Failure: Show error → Allow retry
```

## 🤝 Contributing

[Your Contribution Guidelines Here]

## 📄 License

[Your License Here]
