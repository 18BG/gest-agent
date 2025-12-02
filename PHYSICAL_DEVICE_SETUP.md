# Setup for Physical Device Testing

## The Problem

When testing on a physical phone, `127.0.0.1` (localhost) refers to the **phone itself**, not your computer. That's why you're getting "Connection refused" - your phone can't reach your computer's PocketBase server.

## The Solution

Use your computer's IP address instead of `127.0.0.1`.

---

## Step-by-Step Fix

### Step 1: Find Your Computer's IP Address

**On Windows (PowerShell):**
```powershell
ipconfig
```

Look for **"IPv4 Address"** under your WiFi or Ethernet adapter:
```
Wireless LAN adapter Wi-Fi:
   IPv4 Address. . . . . . . . . . . : 192.168.1.105
```

**Quick command:**
```powershell
ipconfig | findstr IPv4
```

### Step 2: Make Sure Both Devices Are on Same WiFi

⚠️ **IMPORTANT:** Your computer and phone must be on the **same WiFi network**!

- Computer: Connected to WiFi (e.g., "Home WiFi")
- Phone: Connected to the **same** WiFi (e.g., "Home WiFi")

### Step 3: Update app_constants.dart

Open `lib/core/constants/app_constants.dart` and replace the IP:

**Before:**
```dart
static const String pocketbaseUrl = 'http://127.0.0.1:8090';
```

**After (example with IP 192.168.1.105):**
```dart
static const String pocketbaseUrl = 'http://192.168.1.105:8090';
```

**Replace `192.168.1.105` with YOUR actual computer's IP address!**

### Step 4: Allow Firewall Access (Windows)

PocketBase needs to accept connections from your phone.

**Option A: When prompted**
- When you first run PocketBase, Windows Firewall will ask
- Click "Allow access" for **Private networks**

**Option B: Manual configuration**
1. Open Windows Defender Firewall
2. Click "Allow an app through firewall"
3. Find `pocketbase.exe`
4. Check both "Private" and "Public"
5. Click OK

**Option C: Quick PowerShell command (Run as Administrator):**
```powershell
netsh advfirewall firewall add rule name="PocketBase" dir=in action=allow protocol=TCP localport=8090
```

### Step 5: Test Connection from Phone

Before running your Flutter app, test if your phone can reach PocketBase:

1. Open a browser on your phone
2. Go to: `http://YOUR_COMPUTER_IP:8090/_/`
   - Example: `http://192.168.1.105:8090/_/`
3. You should see the PocketBase admin login page

If you can't access it:
- ❌ Check WiFi (same network?)
- ❌ Check Firewall (allowed?)
- ❌ Check IP address (correct?)

### Step 6: Restart Your Flutter App

```bash
# Stop the app (Ctrl+C)
# Then restart
flutter run
```

The app should now connect successfully!

---

## Quick Reference

### Your Configuration

1. **Computer IP:** `_______________` (fill this in after running `ipconfig`)
2. **PocketBase URL:** `http://_______________:8090`
3. **WiFi Network:** `_______________` (same on both devices)

### Test URLs

- **Admin Dashboard:** `http://YOUR_IP:8090/_/`
- **API Health:** `http://YOUR_IP:8090/api/health`
- **REST API:** `http://YOUR_IP:8090/api/`

---

## Common Issues

### Issue 1: "Connection refused"
**Cause:** Phone can't reach computer
**Fix:** 
- Check same WiFi network
- Check firewall settings
- Verify IP address is correct

### Issue 2: "Network unreachable"
**Cause:** Different networks or VPN
**Fix:**
- Disconnect VPN on computer
- Connect both to same WiFi
- Disable mobile data on phone

### Issue 3: Firewall blocking
**Cause:** Windows Firewall blocking PocketBase
**Fix:**
```powershell
netsh advfirewall firewall add rule name="PocketBase" dir=in action=allow protocol=TCP localport=8090
```

### Issue 4: IP address changed
**Cause:** Router assigned new IP to computer
**Fix:**
- Run `ipconfig` again
- Update `app_constants.dart` with new IP
- Restart Flutter app

---

## For Different Scenarios

### Testing on Emulator
```dart
static const String pocketbaseUrl = 'http://10.0.2.2:8090'; // Android emulator
// or
static const String pocketbaseUrl = 'http://127.0.0.1:8090'; // iOS simulator
```

### Testing on Physical Device
```dart
static const String pocketbaseUrl = 'http://192.168.1.105:8090'; // Your computer's IP
```

### Production
```dart
static const String pocketbaseUrl = 'https://your-domain.com';
```

---

## Verification Checklist

Before running your app:

- [ ] Found computer's IP address (`ipconfig`)
- [ ] Both devices on same WiFi network
- [ ] Updated `app_constants.dart` with correct IP
- [ ] Firewall allows PocketBase (port 8090)
- [ ] Can access `http://YOUR_IP:8090/_/` from phone browser
- [ ] PocketBase is running on computer
- [ ] Collections imported in PocketBase
- [ ] User account created in PocketBase

---

## Example Configuration

If your computer's IP is `192.168.1.105`:

**File:** `lib/core/constants/app_constants.dart`
```dart
static const String pocketbaseUrl = 'http://192.168.1.105:8090';
```

**Test in phone browser:**
```
http://192.168.1.105:8090/_/
```

**Expected result:** PocketBase admin login page appears

---

## Need Help?

1. **Find IP:** `ipconfig | findstr IPv4`
2. **Test from phone browser:** `http://YOUR_IP:8090/_/`
3. **Check firewall:** Allow port 8090
4. **Verify same WiFi:** Both devices on same network

Once you can access PocketBase admin from your phone's browser, the Flutter app will work too!
