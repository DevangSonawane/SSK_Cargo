# DigiLocker return → app: backend checklist

The app now passes this as `redirect_url` to `POST /api/kyc/verify/digilocker/start`:

```
https://apigadidosti.asynk.in/kyc/digilocker/return
```

DigiLocker appends `?verification_id=…`. On Android this URL is registered as an **App Link**
(`android:autoVerify="true"`, host `apigadidosti.asynk.in`, path prefix `/kyc/digilocker/return`),
so once it is verified Android opens the app directly instead of the browser. The app then calls
`GET /api/kyc/verify/digilocker/status` itself.

Three things are needed on `apigadidosti.asynk.in`. Today all three return 404.

## 1. `GET /.well-known/assetlinks.json` (Android, required)

Serve with `Content-Type: application/json`, HTTP 200, **no redirects**, over https:

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.gadidost.play",
      "sha256_cert_fingerprints": [
        "9D:AA:B2:79:0E:E4:E8:19:AB:3A:90:01:39:1F:D4:F7:E6:1D:27:1F:39:ED:E5:62:73:04:63:E5:48:5E:EF:B8",
        "01:79:0D:9D:1C:66:13:67:0A:6B:54:02:B2:AE:BE:D0:9F:0B:0A:D3:46:78:5F:0C:B5:47:33:0B:16:BC:A9:96"
      ]
    }
  }
]
```

- `9D:AA:…:EF:B8` is the **Play App Signing** key, read from the build installed from the Play
  Store. It's the one that matters for real users. You can double-check it in Play Console → Setup →
  App signing.
- `01:79:…:A9:96` is the local **debug** key, so `flutter run` builds verify too. Remove it if
  you'd rather not ship it.

Android checks this file when the app is installed or updated. To re-check on a test phone:
`adb shell pm verify-app-links --re-verify com.gadidost.play`, then
`adb shell pm get-app-links com.gadidost.play`. The domain should show `verified`.

## 2. `GET /kyc/digilocker/return` (fallback page, required)

This page only appears when the app does **not** open: the link isn't verified yet, the user opened
DigiLocker on a laptop, or the app isn't installed. Right now that case shows a JSON 404. Serve a
small HTML page instead, something like:

```html
<!doctype html>
<html><head><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Verification complete</title></head>
<body style="font-family:sans-serif;text-align:center;padding:48px 24px">
  <h2>DigiLocker verification complete</h2>
  <p>Go back to the Gadi Dost app to finish your KYC.</p>
  <a id="open" style="display:inline-block;padding:14px 24px;background:#0b6bcb;color:#fff;border-radius:12px;text-decoration:none"
     href="#">Open Gadi Dost</a>
  <script>
    var q = location.search || '';
    // Android: explicit-package intent opens the app even if the App Link isn't verified.
    var android = 'intent://apigadidosti.asynk.in/kyc/digilocker/return' + q +
                  '#Intent;scheme=https;package=com.gadidost.play;end';
    document.getElementById('open').href = /android/i.test(navigator.userAgent) ? android : location.href;
  </script>
</body></html>
```

Don't consume or invalidate `verification_id` on this route. The app reads the result through the
status endpoint.

## 3. `GET /.well-known/apple-app-site-association` (iOS, later)

This is only needed once the iOS app ships. The bundle id in the project is still
`com.example.ssk`, and no Apple team or Associated Domains entitlement is configured. When that's
ready, serve the file with `Content-Type: application/json` and no extension:

```json
{ "applinks": { "details": [ { "appIDs": ["<TEAMID>.<bundle id>"],
  "components": [ { "/": "/kyc/digilocker/return*" } ] } ] } }
```

iOS doesn't follow Universal Links from inside SFSafariViewController. Until then, the iOS app
re-checks the status when the user taps **Done** and comes back.

## Open questions for backend

1. Is the `done` result from `/digilocker/status` stored server-side before `POST /api/kyc/{role}`?
   The app now keeps the `verificationId` on the phone for 24 h, so it can re-read the result after
   a relaunch. A server-side record would also cover a reinstall.
2. Swagger says `POST /api/kyc/broker` requires `gst_number`, `bank_account_number` and
   `business_registration_number`, and always sets `submitted`. The DigiLocker guide says submit
   needs no numbers for documents DigiLocker verified, and returns `verified` straight away. Which
   one is right?
