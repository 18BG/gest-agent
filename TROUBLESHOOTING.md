# Troubleshooting Connection Issue

## Current Situation

✅ PocketBase is running at `http://127.0.0.1:8090`
✅ App is configured to use `http://127.0.0.1:8090`
❌ Connection is failing

## Possible Issues

### 1. Collections Not Imported

The most likely issue is that the collections haven't been imported into PocketBase yet.

**Solution:**

1. Open PocketBase admin: http://127.0.0.1:8090/_/
2. Login with your admin account (`bg@admin.ad`)
3. Go to **Settings** (⚙️) > **Import collections**
4. Open the file `pocketbase/pb_schema.json` in a text editor
5. Copy ALL the content
6. Paste into the import box
7. Click **Review** then **Confirm**

You should now see 3 collections:
- clients
- operations
- payments

### 2. User Account Not Created

You created a **superuser** (`bg@admin.ad`) but you need a regular **user** to login to the app.

**Solution:**

1. In PocketBase admin, go to **Collections** > **users**
2. Click **New record**
3. Fill in:
   - Email: `bg@agent.com`
   - Password: `qwerty123`
   - Name: `BG Agent`
4. Click **Create**

### 3. Firewall or Network Issue

Sometimes Windows Firewall blocks the connection.

**Solution:**

1. Make sure Windows Firewall allows PocketBase
2. Try accessing http://127.0.0.1:8090/api/health in your browser
3. You should see: `{"code":200,"message":"API is healthy","data":{}}`

### 4. App Cache Issue

The app might have cached old connection data.

**Solution:**

Stop your Flutter app and restart it:
```bash
# Stop the app (Ctrl+C in terminal)
# Then restart
flutter run
```

Or do a clean rebuild:
```bash
flutter clean
flutter pub get
flutter run
```

## Step-by-Step Fix

### Step 1: Import Collections

```bash
# 1. Open browser
http://127.0.0.1:8090/_/

# 2. Login with admin account
Email: bg@admin.ad
Password: qwerty123

# 3. Go to Settings > Import collections
# 4. Copy content from pocketbase/pb_schema.json
# 5. Paste and confirm
```

### Step 2: Create User Account

```bash
# In PocketBase admin:
# Collections > users > New record

Email: bg@agent.com
Password: qwerty123
Name: BG Agent
```

### Step 3: Test Connection

Open browser and test the API:
```
http://127.0.0.1:8090/api/health
```

Should return:
```json
{"code":200,"message":"API is healthy","data":{}}
```

### Step 4: Restart Flutter App

```bash
flutter run
```

### Step 5: Login

In the app:
- Email: `bg@agent.com`
- Password: `qwerty123`

## Verify Collections Are Imported

In PocketBase admin dashboard, you should see:

```
Collections:
├── users (system collection)
├── clients (3 fields)
├── operations (5 fields)
└── payments (3 fields)
```

If you don't see `clients`, `operations`, and `payments`, the import didn't work.

## Check PocketBase Logs

Look at the terminal where PocketBase is running. You should see logs when the app tries to connect.

If you see errors like:
```
404 Not Found - Collection not found
```

This confirms the collections aren't imported.

## Quick Test Script

You can also test the connection with curl:

```bash
# Test health endpoint
curl http://127.0.0.1:8090/api/health

# Test auth endpoint (should return 400 if collections exist)
curl -X POST http://127.0.0.1:8090/api/collections/users/auth-with-password \
  -H "Content-Type: application/json" \
  -d '{"identity":"test","password":"test"}'
```

## Still Not Working?

If none of the above works:

1. **Stop PocketBase** (Ctrl+C)
2. **Delete the database** (if you haven't added important data):
   ```bash
   # In the PocketBase directory
   rm -rf pb_data
   ```
3. **Restart PocketBase**:
   ```bash
   .\pocketbase.exe serve
   ```
4. **Recreate admin**:
   ```bash
   .\pocketbase.exe superuser upsert bg@admin.ad qwerty123
   ```
5. **Import collections again** (follow Step 1 above)
6. **Create user** (follow Step 2 above)
7. **Test app**

## Expected Behavior

When everything is working:

1. PocketBase logs show incoming requests
2. App connects successfully
3. Login works
4. You see the dashboard with 0 UV, 0 Espèces, 0 Dettes

## Contact Info

If you're still stuck, check:
- PocketBase logs in the terminal
- Flutter app logs
- Browser console at http://127.0.0.1:8090/_/

The most common issue is **collections not imported** - make sure you see all 3 collections in the admin dashboard!
