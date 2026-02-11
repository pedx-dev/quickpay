# Face ID / Touch ID Icon Locations

## Updated Icons - All Now Use `CupertinoIcons.faceid` ✅

### 1. **Login Page - Biometric Login Button**
**File**: `lib/auth/login_page.dart` (Line ~119)

```dart
Icon(CupertinoIcons.faceid, size: 50, color: CupertinoColors.activeBlue)
Text('Login with Face ID')
```

**Visual**: 
```
┌──────────────────────────┐
│                          │
│      [Username Field]    │
│      [Password Field]    │
│                          │
│      ┌──────────────┐    │
│      │   Sign In    │    │
│      └──────────────┘    │
│                          │
│          👤              │  <-- Face ID Icon (size: 50)
│    Login with Face ID    │
│                          │
│      [Reset Data]        │
│                          │
└──────────────────────────┘
```

---

### 2. **Settings Page (main.dart) - Biometric Toggle**
**File**: `lib/main.dart` (Line ~2191)

```dart
icon: CupertinoIcons.faceid
title: 'Face ID / Touch ID'
trailing: CupertinoSwitch(...)
```

**Visual**:
```
Settings
┌──────────────────────────────────┐
│  🔔  Notifications        [ON]   │
│  ─────────────────────────────   │
│  👤  Face ID / Touch ID   [ON]   │  <-- Face ID Icon
│  ─────────────────────────────   │
│  🌙  Dark Mode            [OFF]  │
└──────────────────────────────────┘
```

---

### 3. **Settings Page (homepage.dart) - Biometric Toggle**
**File**: `lib/homepage.dart` (Line ~2766)

```dart
leading: Icon(CupertinoIcons.faceid, color: CupertinoColors.systemBlue)
title: 'Face ID / Touch ID'
trailing: CupertinoSwitch(...)
```

**Visual**:
```
Settings
┌──────────────────────────────────┐
│  📱  Change PIN                  │
│  ─────────────────────────────   │
│  👤  Face ID / Touch ID   [ON]   │  <-- Face ID Icon (Blue)
│  ─────────────────────────────   │
└──────────────────────────────────┘
```

---

## Icon Properties:

### Login Page Button:
- **Icon**: `CupertinoIcons.faceid`
- **Size**: 50 (larger for visibility)
- **Color**: `CupertinoColors.activeBlue` (iOS blue)
- **Label**: "Login with Face ID"
- **Style**: Bold text

### Settings Pages:
- **Icon**: `CupertinoIcons.faceid`
- **Size**: Default (16-20)
- **Color**: 
  - main.dart: Default color
  - homepage.dart: `CupertinoColors.systemBlue`
- **Label**: "Face ID / Touch ID"

---

## How It Works:

1. **On Login Screen**: 
   - Shows Face ID icon if biometrics are enabled
   - Tap to authenticate with Face ID/Touch ID
   - Falls back to username/password if fails

2. **In Settings**:
   - Toggle switch to enable/disable biometric login
   - Icon shows current biometric type available on device
   - Automatically detects Face ID or Touch ID capability

3. **Platform Support**:
   - iOS: Shows Face ID on newer devices, Touch ID on older
   - Android: Shows fingerprint authentication
   - Windows/Desktop: May show PIN authentication

---

## Testing:

1. Enable biometrics in Settings
2. Logout
3. On login page, you should see the Face ID icon button
4. Click it to authenticate with biometrics

---

## Note:
The `faceid` icon automatically adapts to show:
- 👤 Face ID icon on devices with Face ID
- 👆 Touch ID icon on devices with Touch ID
- The system handles the icon variation automatically

