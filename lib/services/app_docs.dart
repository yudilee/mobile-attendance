import 'package:flutter/material.dart';

class DocSection {
  final String id;
  final String title;
  final IconData icon;
  final List<DocArticle> articles;

  const DocSection({
    required this.id,
    required this.title,
    required this.icon,
    required this.articles,
  });
}

class DocArticle {
  final String id;
  final String title;
  final String content; // Markdown-like text with simple formatting
  final List<String>? steps; // Ordered steps (optional)

  const DocArticle({
    required this.id,
    required this.title,
    required this.content,
    this.steps,
  });
}

class AppDocs {
  static List<DocSection> get allSections => [
        _gettingStarted,
        _deviceSetup,
        _punching,
        _offlineSync,
        _features,
        _accountSecurity,
        _adminGuide,
        _troubleshooting,
      ];

  static const _gettingStarted = DocSection(
    id: 'getting_started',
    title: 'Getting Started',
    icon: Icons.rocket_launch,
    articles: [
      DocArticle(
        id: 'what_is_this',
        title: 'What is This App?',
        content: '''This attendance system replaces traditional fingerprint machines with mobile-based clock-in/clock-out. It uses GPS geofencing, biometric verification, and optional selfie/QR verification to ensure accurate attendance tracking.

Key capabilities:
• Clock in/out from your phone using fingerprint or face unlock
• GPS location verification to confirm you're at the workplace
• Works offline — punches sync automatically when connection returns
• Real-time sync with your company's ADMS attendance server
• Administrative web dashboard for managing employees and viewing reports''',
      ),
      DocArticle(
        id: 'requirements',
        title: 'Requirements',
        content: '''Before using this app, make sure you have:

📱 Device Requirements
• Android device running Android 8.0 (API 26) or higher
• GPS/Location services enabled
• Fingerprint sensor OR Face unlock capability (recommended)
• Camera (for optional selfie and QR features)
• Internet connection for initial setup

🔧 Provided by Your IT Administrator
• Server URL (backend API address)
• API Key (unique to your device)
• Your Employee ID
• Branch/Office location details

🛡️ Permissions Required
• Location (GPS) — required for geofence verification
• Biometrics (Fingerprint/Face) — required for punch identity verification
• Camera — required for selfie verification & QR scanning (optional)''',
      ),
      DocArticle(
        id: 'first_time_setup',
        title: 'First-Time Setup Guide',
        content: '''Follow these steps to set up the app for the first time:

Step 1: Launch the App
Open the app. You'll see the Settings screen.

Step 2: Enter Server URL
Tap "Server URL" and enter the backend address provided by your IT admin. This is the address of the middleware server that connects to your company's attendance system.

Step 3: Enter API Key
Tap "API Key" and enter the key provided by your admin. This key links your device to your employee account.

Step 4: Configure Security (Recommended)
• Enable "Use Biometric" — this requires fingerprint/face before each punch
• Enable "Certificate Pinning" — this prevents man-in-the-middle attacks
• Set "Biometric Session Timeout" — choose how often to re-authenticate

Step 5: Enable Location
The app will ask for location permissions. Grant "Allow all the time" for automatic geofence detection.

Step 6: Test Connection
Tap the fingerprint icon in the Punch tab. If everything is configured correctly, you'll see the punch interface ready to use.''',
        steps: [
          'Launch the app and go to Settings',
          'Enter the Server URL from your IT admin',
          'Enter your API Key',
          'Configure biometric and security preferences',
          'Grant location permissions',
          'Test by tapping the Punch tab',
        ],
      ),
    ],
  );

  static const _deviceSetup = DocSection(
    id: 'device_setup',
    title: 'Device Registration',
    icon: Icons.phone_android,
    articles: [
      DocArticle(
        id: 'registering_device',
        title: 'Registering Your Device',
        content: '''Device registration links your phone to your employee account. This ensures only authorized devices can punch attendance.

Automatic Registration:
When you first open the app and enter your API key, the app automatically sends a registration request containing:
• Your device's unique hardware ID (Device UUID)
• Device name and model
• Employee ID (linked via API key)

Approval Flow:
1. Registration request is sent to the server
2. Admin reviews the request in the web dashboard
3. Admin assigns your device to a branch (office location)
4. Once approved, the device status changes to "Active"
5. You'll see "Ready to Punch" on the home screen

Status Indicators:
• "Pending Approval" — Waiting for admin to approve
• "No Branch Assigned" — Approved but not yet linked to a branch
• "Ready" — Fully active and ready to punch
• "Suspended" — Device has been deactivated by admin''',
      ),
      DocArticle(
        id: 'multi_device',
        title: 'Using Multiple Devices',
        content: '''You can register multiple devices under the same employee account. This is useful if:

• You switch between phone and tablet
• You get a new phone and want both active during transition
• You use a work-provided device and a personal device

Rules:
• Each device gets its own API key
• Each device registers independently
• All devices are linked to the same Employee ID
• Punches from any device are recorded under your name
• Admin can suspend individual devices if needed

To add another device, install the app on the new device and repeat the setup process with a new API key.''',
      ),
    ],
  );

  static const _punching = DocSection(
    id: 'punching',
    title: 'Punching In/Out',
    icon: Icons.fingerprint,
    articles: [
      DocArticle(
        id: 'how_to_punch',
        title: 'How to Clock In/Out',
        content: '''The punch flow is designed to be quick and secure. Here's how it works:

Step-by-Step Punch Flow:

Step 1: Navigate to Punch Tab
Tap the fingerprint icon in the bottom navigation bar.

Step 2: Choose Punch Type
Select the type of punch from the grid:
• "Clock In" — Start of shift
• "Clock Out" — End of shift
• "Break Start" — Going on break
• "Break End" — Returning from break
(Your company may have custom punch types)

Step 3: Biometric Verification
The app will prompt for fingerprint or face unlock. This verifies your identity.

Step 4: Location Verification
The app checks your GPS location against the office geofence. You must be within the allowed radius.

Step 5: Optional Selfie
If enabled, you'll be prompted to take a selfie (front camera) for visual verification.

Step 6: Optional QR Scan
If the branch requires QR verification, scan the QR code displayed at your office entrance.

Step 7: Confirmation
A success message confirms your punch. The punch is immediately synced to the server.

For Clock Out:
The same flow applies. The system records your departure time and calculates total work duration.''',
        steps: [
          'Tap the Punch tab (fingerprint icon)',
          'Select the punch type (Clock In, Clock Out, Break, etc.)',
          'Authenticate with fingerprint or face',
          'Wait for GPS geofence verification',
          'Take optional selfie if prompted',
          'Scan optional QR code if prompted',
          'Confirm — punch is recorded!',
        ],
      ),
      DocArticle(
        id: 'punch_types',
        title: 'Punch Types Explained',
        content: '''Your company configures which punch types are available. Common types include:

🟢 Clock In (In)
Marks the start of your work day. Should be done when you arrive at the office.

🔴 Clock Out (Out)
Marks the end of your work day. Should be done when leaving the office.

🟡 Break Start
Marks the start of a break period. Required if your company tracks break time.

🔵 Break End
Marks the end of a break period.

🟣 Overtime Start
Marks the start of overtime work (if applicable).

⚪ Overtime End
Marks the end of overtime work.

Some punch types may have geofence requirements turned off (e.g., you can submit Overtime End from home). The app will show which types require geofence verification.''',
      ),
      DocArticle(
        id: 'geofence',
        title: 'GPS & Geofence Verification',
        content: '''The app uses GPS to confirm you're physically at your workplace when punching.

How It Works:
1. Your company defines geofence zones — circular areas around each office branch
2. Each branch has a center point (latitude/longitude) and radius (in meters)
3. When you punch, the app checks if your GPS location falls within any assigned branch's zone
4. If you're outside all zones, the punch is rejected (for punch types that require geofencing)

Distance Display:
The punch screen shows your distance from the nearest branch. You'll see:
• "📍 You're X meters from [Branch Name]" — within zone, ready to punch
• "📍 Outside geofence area" — move closer to the office

Tips:
• Enable high-accuracy GPS in your phone settings
• Make sure you're actually at the office location
• GPS works best outdoors; near windows indoors
• If GPS is slow, wait a moment for the blue dot to stabilize

Mock Location Detection:
If your phone detects mock locations (GPS spoofing), the punch is flagged but not automatically rejected. The admin can review flagged punches in the dashboard.''',
      ),
      DocArticle(
        id: 'duplicate_protection',
        title: 'Duplicate Punch Protection',
        content: '''The app prevents duplicate punches through two mechanisms:

1. Client-Side ID (Idempotency):
Each punch generates a unique ID (UUID). If the network fails and you retry, the server recognizes the same ID and returns the existing result instead of creating a duplicate.

2. 5-Minute Window:
The server automatically rejects a punch if:
• Same employee
• Same punch type (e.g., "Clock In")
• Within 5 minutes of the last punch

This prevents accidental double-taps from creating multiple records.

3. Daily Limit:
The server enforces a maximum number of punches per day (configurable by admin, default: 10). This prevents abuse or automated punching.''',
      ),
    ],
  );

  static const _offlineSync = DocSection(
    id: 'offline_sync',
    title: 'Offline Mode & Sync',
    icon: Icons.wifi_off,
    articles: [
      DocArticle(
        id: 'offline_punching',
        title: 'Punching When Offline',
        content: '''The app works even without internet. Here's how:

When You're Offline:
1. All punch flow steps remain the same (biometric, GPS, etc.)
2. The punch is stored locally on your device in an offline queue
3. A "Pending" indicator shows the punch hasn't synced yet
4. The punch is queued for automatic sync when connection returns

When Connection Returns:
1. The app detects internet availability automatically
2. All queued punches are sent to the server in a batch
3. The server processes each punch (checking for duplicates)
4. Results are stored locally so you can see them in History
5. A sync confirmation appears

What Works Offline:
✅ Biometric verification (device-local)
✅ GPS location (device-local)
✅ QR code scanning (device-local)
✅ Selfie capture (stored for later upload)
✅ Viewing cached branch/punch type info
✅ Viewing previously synced history

What Needs Internet:
❌ Initial setup (need API key verification)
❌ Real-time geofence data updates
❌ Syncing punches to server
❌ Dashboard attendance calculations (uses server data)

Sync Status Codes:
• "Pending" — Waiting to sync
• "Synced" — Successfully uploaded
• "Failed" — Error during sync (tap to retry)
• "Stale" — Not synced after 7 days''',
      ),
      DocArticle(
        id: 'offline_setup',
        title: 'Preparing for Offline Use',
        content: '''To ensure the app works properly when you're offline:

1. Connect At Least Once
Before going offline, open the app with internet and let it fully load. This caches:
• Branch locations and geofence data
• Available punch types
• Your device registration status
• Recent punch history

2. Enable Background Sync (Optional)
In Settings → Notifications, enable push notifications. When available, the server can push updates to your device.

3. Handle Sync Failures
If a punch fails to sync:
• Go to the History tab
• Look for punches marked with "Failed" status
• Tap to retry individual punches
• Or wait for automatic retry (every 5 minutes)

4. Storage Management
Offline queue data is stored in the app's local database. To manage storage:
• Settings → Clear Cache removes temporary data
• Old synced records are automatically cleaned up
• Offline queue is preserved until successfully synced''',
      ),
    ],
  );

  static const _features = DocSection(
    id: 'features',
    title: 'Features',
    icon: Icons.star,
    articles: [
      DocArticle(
        id: 'dashboard',
        title: 'Attendance Dashboard',
        content: '''The Dashboard (first tab) gives you a real-time overview of your attendance.

Today's Summary Card:
• Shows current date and time
• Total work duration today (calculated from Clock In to Clock Out)
• Status badge: Present, Late, or Absent
• Your first punch time and last punch time
• Overtime hours (if applicable)

Weekly Overview Card:
• Current week stats: present days, total hours, average per day
• Each day shown with color indicator:
  🟢 Green — Present on time
  🟡 Yellow — Late arrival
  🔴 Red — Absent
  ⚪ Gray — Non-working day

Monthly Stats Card:
• Month-to-date totals
• Present days count
• Late days count
• Absence count
• Attendance percentage bar''',
      ),
      DocArticle(
        id: 'history',
        title: 'Punch History',
        content: '''The History tab shows all your recorded punches.

View:
• Scrollable list of all punches
• Each entry shows: date, time, punch type, sync status
• Color-coded by punch type
• Distance from branch at time of punch

Sync Status Indicators:
• ✅ Green check — Synced to server
• ⏳ Yellow clock — Pending sync (offline)
• ❌ Red X — Sync failed (tap to retry)

Filtering:
• By date range
• By punch type
• By sync status

Export:
Your HR admin can export all attendance records from the web dashboard as CSV.''',
      ),
      DocArticle(
        id: 'selfie',
        title: 'Selfie Verification (Optional)',
        content: '''When enabled by your company, you may be asked to take a selfie when punching. This provides visual proof of attendance.

How It Works:
1. After biometric auth, the front camera opens
2. Take a photo of your face
3. Review and confirm the photo
4. The photo is stored securely on the server
5. Admins can review selfies alongside punch records

Privacy:
• Selfies are stored on the company server, not on your device
• Only HR administrators can view them
• Selfies are linked to specific punch records for audit purposes
• You can skip selfie if you prefer (but it may be noted in your record)

Tip: Ensure good lighting when taking a selfie for clear identification.''',
      ),
      DocArticle(
        id: 'qr_nfc',
        title: 'QR Code & NFC Check-in (Optional)',
        content: '''Some branches may require QR code scanning or NFC tag tapping as additional location verification.

QR Code Check-in:
1. Your office displays a unique QR code at the entrance
2. When punching, the app opens the camera
3. Scan the QR code
4. The app verifies it matches the expected branch code
5. Punch proceeds only if QR matches

NFC Tag Check-in:
1. Your office has NFC tags installed at entry points
2. Tap your phone to the NFC tag when punching
3. The app reads the tag and verifies it's valid
4. Punch proceeds only if tag is authentic

These features are optional and configured per-branch. Your admin will inform you if they're required.

Tip: Enable NFC in your phone's quick settings before punching if NFC verification is active at your branch.''',
      ),
      DocArticle(
        id: 'notifications',
        title: 'Push Notifications',
        content: '''When enabled, push notifications help you stay on track with your attendance.

Types of Notifications:

⏰ Punch Reminders
• Morning reminder (8:00 AM): "Good morning! Don't forget to clock in."
• Evening reminder: "Your shift is ending soon. Please clock out."

📍 Geofence Alerts
• Entering area: "You've arrived at [Branch]. Clock in now?"
• Leaving area: "You're leaving the work area. Don't forget to clock out!"

⚠️ Missed Punch Alerts
• If no clock-in detected by late morning
• If clock-in without clock-out detected in the evening

Configuring Notifications:
Go to Settings → Notifications to toggle:
• Master notification on/off switch
• Punch reminder on/off

Note: Push notifications require Firebase Cloud Messaging setup by your IT admin.''',
      ),
    ],
  );

  static const _accountSecurity = DocSection(
    id: 'security',
    title: 'Account & Security',
    icon: Icons.security,
    articles: [
      DocArticle(
        id: 'api_key_security',
        title: 'API Key Management',
        content: '''Your API key is the credential that links your device to your employee account.

Important Rules:
🔑 Keep your API key secret — never share it with others
🔑 Your key is shown only once when created by the admin
🔑 If you lose your key, ask your admin to generate a new one
🔑 Old keys can be revoked by admin if compromised

Key Expiry:
• API keys may have an expiration date (configurable by admin)
• Before expiry, a warning appears in the admin dashboard
• When expired, the app will stop working until you get a new key
• Admins can set a grace period (old key + new key both work for X days)

Best Practices:
• Don't screenshot or save your API key in plain text
• If you suspect your key is compromised, request a new one immediately
• Use a strong device PIN/password to protect your phone''',
      ),
      DocArticle(
        id: 'biometric_security',
        title: 'Biometric & Session Security',
        content: '''The app uses your device's built-in biometric security (fingerprint or face unlock) to verify your identity.

How Biometric Authentication Works:
1. Before each punch, the app requests fingerprint or face scan
2. Your biometric data NEVER leaves your device
3. The app only receives a "success/failure" result from the system
4. Your fingerprint template is stored securely by your device's hardware

Biometric Session Timeout:
To balance security and convenience:
• You can set how often to re-authenticate in Settings
• Options: Every Punch, 30 seconds, 1 minute, or 5 minutes
• Example: Set to 1 minute — after one biometric auth, you can punch freely for 60 seconds
• When the session expires, biometric is required again

Device Security Check:
The app detects if your device is rooted or jailbroken. If detected:
• Punching is blocked
• A red "Device Compromised" banner is shown
• Contact your IT admin for assistance
• This protects against tampered devices being used for attendance fraud''',
      ),
      DocArticle(
        id: 'certificate_pinning',
        title: 'Certificate Pinning (Advanced)',
        content: '''Certificate pinning is a security feature that prevents man-in-the-middle attacks.

What it does:
• Normally, your phone trusts any certificate signed by a recognized CA
• An attacker on the same network could intercept traffic with a forged certificate
• Certificate pinning makes your app ONLY trust the specific certificate from your server
• This prevents any third party from intercepting your punch data

When to Enable:
✅ Enable in production environments
✅ Enable when using public WiFi
✅ Enable if your company requires it
❌ Disable during development/testing with self-signed certificates

How to Enable:
Settings → Security → Certificate Pinning → Toggle ON

Note: If enabled incorrectly, the app may not connect to the server. Toggle off if you can't connect after enabling. Your IT admin will inform you if pinning is required.''',
      ),
    ],
  );

  static const _adminGuide = DocSection(
    id: 'admin_guide',
    title: 'Admin Guide',
    icon: Icons.admin_panel_settings,
    articles: [
      DocArticle(
        id: 'admin_dashboard',
        title: 'Web Admin Dashboard Overview',
        content: '''The web admin dashboard (accessible via browser) is where IT administrators manage the entire attendance system.

Access:
• URL: http://[server-address]:8999/
• Login: Username and password provided during setup

Main Sections:

1. Dashboard (Home)
• Overview of all registered devices
• Quick statistics: active devices, pending approvals
• Recent punch activity
• ADMS sync status

2. Devices
• View all registered devices and their status
• Approve or reject pending device registrations
• Assign devices to branches
• Suspend or reactivate devices
• View device details (model, UUID, last used)

3. Branches (Geofences)
• Add new office branches with GPS coordinates
• Set geofence radius (in meters)
• Enable/disable QR code verification per branch
• Generate QR code data for branch
• Assign devices to branches

4. API Keys
• Create new API keys for employees
• Set key expiration dates
• View key usage (last used IP, last used time)
• Rotate keys (creates new key, old key works for 7 days grace)
• Revoke compromised keys

5. Punch Types
• Configure which punch types are available
• Set colors for each type (displayed in mobile app)
• Enable/disable geofence requirement per type

6. ADMS Sync
• View sync statistics (records synced/pending/failed)
• Monitor ADMS server connectivity
• View and retry failed sync records
• Trigger manual full sync

7. App Settings
• Set minimum app version (force update if outdated)
• Configure sync intervals
• Manage ADMS server targets and credentials

8. Supervisors
• Assign supervisors to employees
• View and manage attendance correction requests
• Approve or reject correction requests''',
      ),
      DocArticle(
        id: 'device_approval',
        title: 'Device Approval Workflow',
        content: '''The device registration process requires admin approval. Here's the workflow:

Step 1: Employee Installs App
Employee installs the app and enters their API key.

Step 2: Registration Request Sent
The app sends an automatic registration request containing device info.

Step 3: Admin Reviews in Dashboard
Go to the Dashboard → check the "Pending Approval" section.

Step 4: Approve Device
Click "Approve" to accept the device. The device status changes to "Pending Branch".

Step 5: Assign Branch
Select the device and assign it to one or more branches (office locations).

Step 6: Device is Active
The device is now active. The employee can start punching.

Step 7: Monitor
You can view device details, suspend, or delete devices at any time.

Bulk Operations:
• Approve multiple devices at once using the checkboxes
• Assign branches in bulk
• Export device list as CSV''',
      ),
      DocArticle(
        id: 'adms_config',
        title: 'ADMS Server Configuration',
        content: '''The system syncs attendance data with your existing ADMS (ZKTeco) server.

Configuration Steps:

1. Add ADMS Target
In Settings → ADMS Target, enter:
• Server URL (e.g., http://192.168.1.100:8080)
• Device Serial Number
• Device Name

2. Set Credentials
In Settings → ADMS Credentials, enter:
• Username
• Password (encrypted at rest)

3. Enable Sync
The system starts syncing automatically using the ZKTeco iClock 501/502 protocol.

How Sync Works:
• Each punch is queued for sync
• The ARQ worker processes the queue
• Handshake with ADMS server happens every 60 seconds
• Failed punches are retried automatically with exponential backoff
  (Retry sequence: 10s → 20s → 40s → 80s → 160s, up to 5 attempts)

Monitoring:
Go to ADMS Sync Dashboard to view:
• Total records synced, pending, and failed
• Recent sync failures with error messages
• ADMS server connectivity status
• Retry buttons for failed records

Troubleshooting:
• "Connection refused" — Check ADMS server is running and reachable
• "Authentication failed" — Check credentials in ADMS Credentials
• "Serial number mismatch" — Verify device serial number in ADMS Target''',
      ),
    ],
  );

  static const _troubleshooting = DocSection(
    id: 'troubleshooting',
    title: 'Troubleshooting',
    icon: Icons.build,
    articles: [
      DocArticle(
        id: 'cant_connect',
        title: 'Can\'t Connect to Server',
        content: '''If the app can't connect to the server, try these steps:

1. Check Server URL
• Go to Settings → Server URL
• Make sure the URL is correct (including http:// or https://)
• Ask your IT admin to confirm the correct address

2. Check Internet Connection
• Make sure WiFi or mobile data is enabled
• Try opening a website in your browser
• If you're on a corporate WiFi, check if there are restrictions

3. Check API Key
• Go to Settings → API Key
• Make sure the key is entered correctly
• Keys are case-sensitive
• Ask your admin if your key is still valid and not expired

4. Check Server Status
• Ask your IT admin to check if the backend server is running
• The admin can check the server's health endpoint: http://[server]/health
• If the server is down, wait for IT to restart it

5. Certificate Issues
• If using HTTPS with certificate pinning, try disabling it in Settings → Security
• If you can connect with pinning off but not on, the server certificate may have changed
• Contact your IT admin for updated certificate info''',
      ),
      DocArticle(
        id: 'gps_not_working',
        title: 'GPS / Location Not Working',
        content: '''If the app can't get your location:

1. Enable GPS
• Open your phone's Quick Settings
• Make sure Location/GPS is turned ON
• Set to "High Accuracy" mode

2. Check App Permissions
• Go to Settings → Apps → Attendance → Permissions
• Make sure Location permission is "Allow all the time"
• If it's "Allow only while using app", GPS may not initialize in time

3. Wait for GPS Fix
• GPS can take 10-30 seconds to get an accurate fix
• Go outdoors or near a window
• The location icon in the status bar should stop flashing when fixed

4. Restart the App
• Close and reopen the app
• If still not working, restart your phone

5. Check Geofence Settings
• Your assigned branch location might be incorrect
• Ask your admin to verify branch coordinates in the dashboard
• You might be too far from the branch center point''',
      ),
      DocArticle(
        id: 'biometric_fails',
        title: 'Biometric / Fingerprint Not Working',
        content: '''If biometric authentication fails:

1. Clean the Sensor
• Wipe the fingerprint sensor with a clean, dry cloth
• Make sure your finger is clean and dry

2. Re-register Fingerprints
• Go to your phone's Settings → Security → Fingerprints
• Delete and re-register your fingerprints
• Register multiple fingers (both thumbs, index fingers)

3. Check Face Unlock
• If using face unlock, make sure your face is well-lit
• Remove masks, sunglasses, or hats
• Re-register face in different lighting conditions

4. Use Alternative Method
• If biometric keeps failing, try:
  - Restarting your phone
  - Using a different registered finger
  - Entering your device PIN/password (if prompted)

5. Skip Biometric (Temporarily)
• In Settings → Security → Disable "Use Biometric"
• This bypasses biometric for testing
• Re-enable once the sensor is working

6. Still Not Working?
• Your device's biometric hardware may need service
• Contact your device manufacturer or IT support''',
      ),
      DocArticle(
        id: 'sync_failures',
        title: 'Punch Sync Failures',
        content: '''If punches aren't syncing:

1. Check Internet Connection
• Make sure you have an active internet connection
• Try opening a website to verify

2. Manual Retry
• Go to History tab
• Find punches with ❌ status
• Tap on a failed punch to retry it individually
• Or wait for automatic retry (every 5 minutes)

3. Check Server Status
• The backend server might be down for maintenance
• Ask your IT admin to verify the server is running
• Punches remain safely on your device until server is back

4. Check API Key
• Your API key might have expired
• Go to Settings and check your API key status
• Contact admin for a new key if expired

5. Storage Full
• If your phone storage is full, the offline queue can't save new punches
• Free up storage space
• Old synced records are automatically cleaned up''',
      ),
      DocArticle(
        id: 'app_crashes',
        title: 'App Crashes or Freezes',
        content: '''If the app crashes or freezes:

1. Force Close and Reopen
• Close the app from recent apps
• Reopen and try again

2. Clear App Cache
• Go to your phone's Settings → Apps → Attendance → Storage
• Tap "Clear Cache" (not "Clear Data" — that would remove your settings)

3. Update the App
• Check if there's a newer version
• Go to Settings → App Info to see the current version
• If a newer version is required, the app will show an update screen
• Contact your admin for the latest APK

4. Reinstall the App
• As a last resort, uninstall and reinstall
• Make sure you have your API key saved before reinstalling
• You'll need to go through setup again

5. Report the Issue
• If crashes persist, note:
  - When it happens (during punch? opening app?)
  - What you were doing
  - Your device model and Android version
• Send this info to your IT support''',
      ),
    ],
  );
}
