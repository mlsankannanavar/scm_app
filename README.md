# Medha AI BatchMate Mobile

Phase 1 implementation: camera preview, session entry, image capture + submit to backend.

## Getting Started
1. Install Flutter 3.19+.
2. `flutter pub get`
3. Connect a real device (camera required).
4. `flutter run`

## Android Permissions
Add to `android/app/src/main/AndroidManifest.xml`:
```
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

## iOS Permissions (Info.plist)
```
<key>NSCameraUsageDescription</key>
<string>Camera access required for batch scanning</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access for voice input</string>
```

## Roadmap
- Phase 2: Image review & quantity input
- Phase 3: Session management & QR scanning
- Phase 4: Approval workflow & voice recognition
- Phase 5: WebSocket integration & polish
