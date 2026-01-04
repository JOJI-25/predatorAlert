---
description: Connect to phone wirelessly for Flutter development
---

# Wireless Flutter Debugging

## Prerequisites
- Phone and computer on the same WiFi network
- USB cable (only needed for initial setup)

## Steps

// turbo-all

### 1. Connect phone via USB temporarily
Plug in the USB cable and run:
```powershell
cd "c:\Users\DELL\Desktop\PredatorAlert App\flutter_app"
adb devices
```
You should see your device listed.

### 2. Enable TCP/IP mode on the phone
```powershell
adb tcpip 5555
```

### 3. Get phone IP address (if changed)
```powershell
adb shell ip addr show wlan0 | Select-String "inet "
```
Note the IP address (e.g., 192.168.31.161)

### 4. Connect wirelessly
```powershell
adb connect 192.168.31.161:5555
```

### 5. Unplug USB cable
You can now disconnect the USB cable!

### 6. Run Flutter app wirelessly
```powershell
flutter run -d 192.168.31.161:5555
```

## Tips
- Hot reload works wirelessly (press 'r' in terminal)
- Hot restart: press 'R' in terminal
- If connection drops, repeat steps 1-4
- Your phone IP may change if you switch networks
