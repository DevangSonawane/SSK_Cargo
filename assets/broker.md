# Broker Module — UI/UX Spec (for Claude Code)

App: **SSK** (logistics booking — client/broker/driver roles). This spec covers the **Broker** role UI only. Client flow is reference/done. `AppRole.broker` and `SignupRole.broker` already exist in code.

---

## 1. Design System (extracted from existing code — reuse, don't reinvent)

**Colors**
| Token | Hex | Use |
|---|---|---|
| Primary green | `#2FA56E` | Client brand, success states, accent dots |
| Broker blue | `#1F88C9` | **Broker primary accent** (already mapped to broker in signup_screen.dart) |
| Driver purple | `#7A5AF8` | Driver-related accents (3rd truck tile, driver role) |
| Warning amber | `#F59E0B` / `#F8B84D` | Pooling/scanner accents |
| Danger red | `#E23A4B` | Reject / Logout / destructive |
| Text primary | `#101828` / `#121826` | Headings |
| Text secondary | `#667085` / `#1C2430` | Body |
| Text muted | `#98A2B3` / `#9AA4B2` / Colors.black45 | Captions, hints |
| Border | `#E3E8EF` / `#E8EDF2` / `#F0F3F7` | Card borders |
| Surfaces | `#F5F7FB` / `#F3F4F6` / `#EFF6FF` | Tinted icon chips |

> **Rule:** Keep the global `AppTheme` (seed green) untouched. For broker screens, swap accent usages (selected states, CTAs, header) to `#1F88C9` to visually signal "broker mode," matching the existing role-color convention.

**Typography:** use existing `Theme.of(context).textTheme` (headlineMedium 24/w700, titleLarge 20/w700, titleMedium 16/w600, bodyMedium 14). Don't introduce new fonts.

**Shape language**
- Cards: `borderRadius: 22` (PackageTrackingCard), `18–24` for tiles/menus
- Border: `1px` solid `#E3E8EF`/`#E8EDF2`, soft shadow `black α0.03–0.045, blur 12–22, offset (0,6-10)`
- Pills/buttons: `borderRadius: 999` (full pill)
- Status dots: small circle + soft glow shadow (see PackageTrackingCard status dot)

**Reusable widgets already in code — extend, don't duplicate:**
- `PackageTrackingCard` → base for booking history cards & request cards (from/to dotted-line layout already solved)
- `PillTag` → generic status chip
- `ClientBottomBar` / `NavItem` → pattern for `BrokerBottomBar`
- `SheetContainer`, `OptionTile`, `_VehicleOptionTile` → pattern for Add Vehicle/Driver sheets
- `_ProfileMenuTile`, `_ProfileActionCard` (client_profile_screen.dart) → reuse directly for Broker Profile
- `TrackingMapBackdrop` + `_LiveRoutePainter` (tracking_details_screen.dart, CustomPainter-based fake map) → reuse for Driver Tracking detail (no real Maps SDK wired yet)

---

## 2. Navigation Structure

New `BrokerShell` (mirror `ClientShell`) with a **persistent header** + 4-tab `StatefulShellRoute`:

```
/broker/home        → New Booking (requests)
/broker/vehicles     → List Vehicles
/broker/tracking     → Driver Tracking
/broker/history      → Booking History
/broker/profile      → (pushed, not a tab) Profile
/broker/vehicles/add → (pushed) Add Vehicle
/broker/drivers/add  → (pushed) Add Driver / Create Credentials
/broker/drivers/:id  → (pushed) Driver live detail
```

**Header (persistent across all 4 tabs, inside BrokerShell body, above navigationShell):**
- Left: "Good morning, {Broker first name}" (titleLarge) + company name subtitle (bodySmall, muted)
- Right: circular avatar 40–44px (same style as client_profile avatar) → `context.push('/broker/profile')`
- Bell/notification icon optional, left of avatar, badge-dot if new requests pending
- White bg, no elevation, matches `AppBarTheme` (transparent/elevation 0)

**Bottom nav (BrokerBottomBar, 4 items, broker blue `#1F88C9` as selected color instead of green):**
| Icon (Material) | Label |
|---|---|
| `Icons.inbox_rounded` / request icon | New Booking |
| `Icons.local_shipping_rounded` | Vehicles |
| `Icons.gps_fixed_rounded` | Tracking |
| `Icons.history_rounded` | History |

Badge: small red dot on "New Booking" icon when pending requests > 0.

---

## 3. Screen Specs

### 3.1 New Booking (Requests) — `/broker/home`
List of incoming client booking requests as rounded cards (Uber/Rapido/Porter accept-reject pattern).

**BrokerRequestCard** (new widget, base style = PackageTrackingCard):
- Top row: client avatar (initials circle, tinted bg) + client name (titleMedium w700) + time-ago (caption, right-aligned)
- Product/load name (e.g. "Office Chair Set") + weight chip
- From/To rows reusing the dotted route indicator from `PackageTrackingCard` (green start dot, grey end dot, vertical connector)
- Bottom row: vehicle type `PillTag` (e.g. "Medium truck") + distance/ETA text + **value chip** (₹ amount, bold, right-aligned)
- Divider, then two full-width buttons side by side:
  - **Reject** — outlined, red border/text `#E23A4B`
  - **Accept** — filled, broker blue `#1F88C9`, rounded 14–18
- On Accept: success snackbar + card animates out + moves into "Booking History" (status: Accepted) and triggers vehicle/driver assignment flow (future).
- On Reject: confirm dialog (small) → card removed.

**States:** empty state ("No new requests" + illustration/icon), pull-to-refresh (reuse rotating refresh icon pattern from client_home_screen), skeleton loading optional.

### 3.2 List Vehicles — `/broker/vehicles`
- Top: "Your fleet" title + count, "+ Add vehicle" pill button (top-right, broker blue) → pushes `/broker/vehicles/add`
- Grid (2-col, like vehicleOptions grid) or list of **VehicleCard**:
  - Vehicle image/icon tile (reuse `_VehiclePreviewTile` 84px tinted box)
  - Label + plate number + capacity
  - Status `PillTag`: **Idle** (grey `#98A2B3`), **On Trip** (green `#2FA56E`), **Maintenance** (amber)
  - Assigned driver name (small, muted) or "Unassigned"
  - Tap → vehicle detail (edit/remove) bottom sheet, reuse `SheetContainer`

**Add Vehicle screen/sheet** — form fields: Vehicle type (truck size selector reusing `_VehicleOptionTile` selection UI), Number plate, Capacity, Assign driver (dropdown of existing drivers), RC/document upload placeholder, Save button (filled, full width, bottom-pinned like SelectVehicleScreen's CTA).

### 3.3 Driver Tracking — `/broker/tracking`
"Konsa driver kya kar raha hai, kahan hai" — live roster of drivers under this broker.

- Top: "+ Add driver" pill button → `/broker/drivers/add`
- List of **DriverListTile**:
  - Avatar circle (initials/photo)
  - Name + phone (muted)
  - Status `PillTag`: **On Trip** (green, shows current booking ref) / **Idle** (grey) / **Offline** (light grey, no glow)
  - Current location text (e.g. "Near Pune Gateway Hub") + small location-pin icon
  - Trailing: chevron → tap opens Driver Detail
  - Long-press or trailing `more_horiz` → **Remove driver** (confirm dialog)

**Driver Detail (`/broker/drivers/:id`)** — reuse `TrackingDetailsScreen`'s `_LiveTrackingView` + `TrackingMapBackdrop` painter:
- Fake live map backdrop with route overlay
- Top info card: driver name, vehicle assigned, current status, "on trip since {time}" / idle duration
- If on trip: mini booking summary (from/to, client name) linking to that booking
- Contact buttons (call/message) — reuse `_ContactIconButton`

**Add Driver / Create Credentials (`/broker/drivers/add`)** — reuse exact field set from `signup_screen.dart` `SignupRole.driver`: Full name, Mobile number, Driver license no., Vehicle type, Password (broker sets initial password for driver login). Style: same form layout/AnimatedContainer pattern as signup screen, accent = driver purple `#7A5AF8` for the role icon, button = broker blue. Submit → driver appears in tracking list as **Offline** until they log in.

### 3.4 Booking History — `/broker/history`
Visually = client's "Activity" tab, reused almost 1:1.
- Filter chip row (PillTag-style, not pills with icons): All / Completed / Cancelled / Accepted
- List of `PackageTrackingCard` (existing widget, unchanged) — bind to broker's past bookings instead of demo client shipments
- Tap card → push `TrackingDetailsScreen` (existing screen, already reusable) with that booking's data

### 3.5 Broker Profile — `/broker/profile`
Mirror `ClientProfileScreen` layout exactly:
- Header: Broker name (large, two-line like client) + circular avatar top-right
- Action cards row (reuse `_ProfileActionCard`): "Company Details" (handshake icon, blue), "Support" (icon, green)
- Menu list (reuse `_ProfileMenuTile`):
  - Manage Drivers → `/broker/tracking`
  - Manage Vehicles → `/broker/vehicles`
  - **Create driver credentials** → `/broker/drivers/add` (primary highlighted tile, blue icon)
  - Payouts / Earnings (placeholder)
  - Settings
  - Legal
  - Logout (red, existing pattern) → `/login`

---

## 4. New Widgets to Build (`lib/features/broker/presentation/widgets/broker_flow_widgets.dart`)
| Widget | Based on |
|---|---|
| `BrokerShell` | `ClientShell` |
| `BrokerBottomBar` | `ClientBottomBar` (4 items, blue accent) |
| `BrokerHeader` | new — greeting + avatar |
| `BrokerRequestCard` | `PackageTrackingCard` |
| `VehicleCard` | `_VehicleOptionTile` / `_VehiclePreviewTile` |
| `DriverListTile` | `_ProfileMenuTile` + status pill |
| `StatusPill` | `PillTag` (generalize colors) |
| `AddVehicleSheet` | `SheetContainer` + `_VehicleOptionTile` |
| `AddDriverForm` | `signup_screen.dart` field/role pattern |

## 5. Placeholder Data Models (mirror `TrackingDemoShipment` pattern, replace with API later)
```dart
class BookingRequest { clientName, productName, from, to, weight, vehicleType, value, distance, etaText, requestedAt }
class BrokerVehicle { label, plateNumber, capacity, status(idle/onTrip/maintenance), assignedDriverName, assetPath }
class BrokerDriver { name, phone, licenseNo, vehicleType, status(onTrip/idle/offline), currentLocation, assignedVehicle, onTripSince }
```

## 6. Routing additions (`app_router.dart`)
Add a second `StatefulShellRoute.indexedStack` (parallel to client's) wrapped in `BrokerShell`, branches = the 4 paths above, plus standalone pushed routes for profile/add-vehicle/add-driver/driver-detail. `selectedRoleProvider` (already exists) determines post-login redirect to `/client/home` vs `/broker/home`.

## 7. Folder structure
```
lib/features/broker/presentation/screens/
  broker_shell.dart
  broker_home_screen.dart        (New Booking)
  broker_vehicles_screen.dart
  broker_tracking_screen.dart
  broker_history_screen.dart
  broker_profile_screen.dart
  add_vehicle_screen.dart
  add_driver_screen.dart
  driver_detail_screen.dart
lib/features/broker/presentation/widgets/
  broker_flow_widgets.dart
```

## 8. Build Order (suggested for Claude Code)
1. `BrokerShell` + `BrokerBottomBar` + `BrokerHeader` + router wiring (empty screens first, verify nav works)
2. Booking History (easiest — direct reuse of `PackageTrackingCard` + `TrackingDetailsScreen`)
3. List Vehicles + Add Vehicle sheet
4. Driver Tracking list + Add Driver form + Driver Detail (map reuse)
5. New Booking request cards + accept/reject interaction
6. Broker Profile screen

---
**Reference inspiration:** Uber/Rapido/Porter driver-request card pattern — avatar+name top, route in middle, price + accept/reject CTA row at bottom. Already structurally close to existing `PackageTrackingCard`, so extend rather than rebuild.