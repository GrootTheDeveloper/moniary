# Mobile App Links for Moniary invites

Moniary invite links should use the HTTPS host:

```text
https://go.vuivethoima.id.vn/friends/invite/<token>
https://go.vuivethoima.id.vn/groups/invite/<token>
```

The apps also keep legacy custom scheme support:

```text
moniary://friends/invite/<token>
moniary://groups/invite/<token>
```

## DNS and hosting

Create the subdomain `go.vuivethoima.id.vn` and host the files from:

```text
deploy/app-links/go.vuivethoima.id.vn/
```

The current deployment uses Vercel:

```text
go CNAME cname.vercel-dns.com
```

Vercel project:

```text
grootthedevelopers-projects/go.vuivethoima.id.vn
```

The important verification files must be reachable at exactly:

```text
https://go.vuivethoima.id.vn/.well-known/assetlinks.json
https://go.vuivethoima.id.vn/.well-known/apple-app-site-association
https://go.vuivethoima.id.vn/apple-app-site-association
```

The fallback invite paths should also return HTML:

```text
https://go.vuivethoima.id.vn/groups/invite/test-token
https://go.vuivethoima.id.vn/friends/invite/test-token
```

## Certificate fingerprints

The checked-in `assetlinks.json` includes the debug signing SHA-256 fingerprints
that have been used by local development APKs so far:

```text
10:83:5C:82:90:DD:4F:56:E7:75:10:9A:D4:D6:53:33:09:00:35:8A:F0:4D:AB:FD:17:12:8B:0F:15:87:02:96
FE:4C:A1:55:74:C3:DF:E0:50:C6:A2:52:48:EE:65:51:04:3A:33:EF:1C:2E:CC:BE:F0:60:75:3F:68:FE:05:C8
```

When testing a locally installed APK, verify its actual certificate with:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\build-tools\36.1.0\apksigner.bat" verify --print-certs build\app\outputs\flutter-apk\app-debug.apk
```

When Moniary is published through Google Play, add the Play Console **App
signing certificate** SHA-256 fingerprint to the same array. Without the Play
fingerprint, installed Play builds will open the HTTPS link in the browser
fallback instead of directly in the app.

## iOS Universal Links

The Runner app target must include this entitlement:

```text
applinks:go.vuivethoima.id.vn
```

The checked-in `apple-app-site-association` files include:

```text
FLHU923LV8.com.moniary.moniary
```

If the Apple Team ID or iOS bundle ID changes, update both:

- `ios/Runner/Runner.entitlements`
- `deploy/app-links/go.vuivethoima.id.vn/apple-app-site-association`
- `deploy/app-links/go.vuivethoima.id.vn/.well-known/apple-app-site-association`

After deploying the Vercel app-link host, verify the AASA response has no
redirect and uses JSON content:

```powershell
Invoke-WebRequest "https://go.vuivethoima.id.vn/.well-known/apple-app-site-association" -UseBasicParsing
```

On a physical iOS device or simulator with the signed app installed, opening:

```text
https://go.vuivethoima.id.vn/friends/invite/test-token
```

should launch Moniary. If Safari opens the fallback page, reinstall the app
after the AASA file is deployed; iOS caches Universal Link association data.

## Local Android test

After installing the app on an emulator or device:

```powershell
& "F:\Android\Sdk\platform-tools\adb.exe" shell am start -a android.intent.action.VIEW -d "https://go.vuivethoima.id.vn/groups/invite/test-token"
```

Expected behavior:

- Verified domain + installed app: Android opens Moniary directly.
- App not installed or domain not verified: browser opens the fallback page.
- Legacy test still works:

```powershell
& "F:\Android\Sdk\platform-tools\adb.exe" shell am start -a android.intent.action.VIEW -d "moniary://groups/invite/test-token"
```
