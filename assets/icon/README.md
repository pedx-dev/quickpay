# App Launcher Icons Setup

## Instructions to Generate Icons

1. **Create your app icon image**:
   - Create a PNG image with size 1024x1024 pixels
   - Name it `icon.png` and place it in this directory (`assets/icon/icon.png`)
   - Make sure it's a high-quality image with transparent background if needed

2. **Generate launcher icons** by running:
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

3. The icons will be automatically generated for:
   - iOS (all required sizes)
   - Android (adaptive icons with purple background)

## Icon Specifications

- **Size**: 1024x1024 px minimum
- **Format**: PNG with transparency support
- **Android Adaptive Icon Background**: Purple (#6A11CB)
- **Recommended**: Use a simple, recognizable logo

## What This Does

The `flutter_launcher_icons` package will:
- Generate all iOS icon sizes automatically
- Create Android adaptive icons
- Update the platform-specific configuration files
- Deploy icons to both platforms

## Current Configuration

See `pubspec.yaml` for the current icon configuration:
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/icon.png"
  min_sdk_android: 21
  adaptive_icon_background: "#6A11CB"
  adaptive_icon_foreground: "assets/icon/icon.png"
```

## Note

After generating the icons, you may need to:
1. Clean the project: `flutter clean`
2. Rebuild the app: `flutter build ios` or `flutter run`
