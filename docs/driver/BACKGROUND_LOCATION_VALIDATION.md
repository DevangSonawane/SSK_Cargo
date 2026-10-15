# Background driver location validation

Tracking runs for a signed-in driver who is online or has an active trip. It
continues with the screen locked or another app open. Android uses an ongoing
location foreground-service notification and a wake lock; iOS uses location
background mode with its location indicator. The app starts the stream while
visible and keeps the same stream across background/resume transitions.

## Physical-device checks before release

Use a test driver account and a second client/broker device to observe tracking.
Run these checks on Android and iPhone with a freshly installed release build.

1. Sign in as a driver. The location-sharing disclosure must appear before the
   driver's location permission prompt. Cancel it: tracking must not start.
2. Go offline, then online, accept the disclosure, and grant location access.
   Confirm driver coordinates reach the broker/client. Android's ongoing
   tracking notification must appear; iOS should show its location indicator.
3. Start a test trip. Lock the phone for at least five minutes while moving
   safely as a passenger. Confirm fresh coordinates on the second device.
4. Open another app or external navigation for five minutes. Confirm tracking
   continues, then return to the app and confirm no duplicate tracking service.
5. Go offline during the active trip: trip tracking must continue. Finish the
   trip while offline: location updates and the Android notification must stop.
6. Sign out: subsequent coordinates must not be uploaded. Sign in with a client
   or broker account: driver tracking must remain stopped.
7. Deny location permanently, then use the tracking settings action. It must open
   app settings. Grant permission and return: tracking should recover.
8. Disable device location while tracking, then enable it and return to the app.
   Confirm tracking resumes. Repeat with temporary network loss and verify fresh
   coordinates arrive after connectivity returns.

Automated regression tests are in
`test/core/services/driver_location_tracker_test.dart`. They cover stream startup,
platform settings, concurrent permission requests, cancellation, stream failure,
consent, and app lifecycle behavior. They do not prove native OS delivery.

Force-stopping an Android app or force-quitting an iOS app is outside this
implementation's guarantee. Reopen and sign in as needed to resume tracking.
Device battery restrictions can also affect delivery; test the actual devices.

Google Play's background-location declaration, privacy policy, and store review
materials must describe the same online-driver and active-trip behavior.
