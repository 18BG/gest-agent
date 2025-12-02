# Start PocketBase - Quick Guide

## The Error You're Seeing

```
Connection refused, address = 127.0.0.1, port = 35900
```

This means PocketBase is not running. Your Flutter app is trying to connect but can't find the server.

## Solution: Start PocketBase

### Step 1: Download PocketBase

**Linux (Your System):**
```bash
# Download PocketBase
wget https://github.com/pocketbase/pocketbase/releases/download/v0.20.0/pocketbase_0.20.0_linux_amd64.zip

# Extract
unzip pocketbase_0.20.0_linux_amd64.zip

# Make executable
chmod +x pocketbase
```

### Step 2: Start PocketBase

```bash
# Start the server
./pocketbase serve
```

You should see:
```
> Server started at http://127.0.0.1:8090
```

### Step 3: Initial Setup (First Time Only)

1. Open browser: http://127.0.0.1:8090/_/
2. Create admin account
3. Go to **Settings** > **Import collections**
4. Copy content from `pocketbase/pb_schema.json`
5. Click **Review** then **Confirm**

### Step 4: Create Test User

In PocketBase admin:
1. Go to **Collections** > **users**
2. Click **New record**
3. Fill in:
   - Email: `bg@agent.com` (or your preferred email)
   - Password: `Test123456!`
   - Name: `BG Agent`
4. Click **Create**

### Step 5: Test Your App

Now run your Flutter app again:
```bash
flutter run
```

Login with:
- Email: `bg@agent.com`
- Password: `Test123456!`

## Keep PocketBase Running

While developing, keep PocketBase running in a separate terminal:

**Terminal 1 (PocketBase):**
```bash
./pocketbase serve
```

**Terminal 2 (Flutter):**
```bash
flutter run
```

## Troubleshooting

### "pocketbase: command not found"
You need to download it first (see Step 1)

### "Permission denied"
```bash
chmod +x pocketbase
```

### Different port?
If you see a different port in the error, update `lib/core/constants/app_constants.dart`:
```dart
static const String pocketbaseUrl = 'http://127.0.0.1:YOUR_PORT';
```

## Quick Commands

```bash
# Download (Linux)
wget https://github.com/pocketbase/pocketbase/releases/download/v0.20.0/pocketbase_0.20.0_linux_amd64.zip && unzip pocketbase_0.20.0_linux_amd64.zip && chmod +x pocketbase

# Start
./pocketbase serve

# Start with debug logs
./pocketbase serve --debug
```

## Next Steps

Once PocketBase is running and configured:
1. ✅ Your app will connect successfully
2. ✅ You can login
3. ✅ You can create clients and operations
4. ✅ All features will work

**The key is: PocketBase must be running before you start your Flutter app!**
