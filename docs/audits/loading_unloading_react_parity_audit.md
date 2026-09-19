# Loading/Unloading Stops React Parity Audit

Date: 2026-09-19

Scope: compare Flutter against the archived React web apps for loading/unloading stops across client, broker, and driver. React web is treated as the source of truth. This is an audit only; no Flutter behavior was changed.

Implementation update: 2026-09-19

The main Flutter parity work has now been implemented after this audit:

- Added shared loading/unloading stop parsing for booking, trip, nested trip/booking, and legacy location array payloads.
- Extended shared route map routing to preserve ordered stop waypoints after pickup while keeping pre-pickup routing focused on pickup.
- Wired stop-aware route cards/rails/maps into client tracking, client delivery, public tracking, broker active jobs, broker tracking, and driver trip shipments.
- Added broker tracking stop completion controls using `PATCH /api/trips/:tripId/stops/:index/complete`, with only the earliest pending stop of each type enabled.
- Kept existing driver stop completion/status blocking behavior intact.
- Verified with `flutter analyze` and `flutter test`.

Remaining product-choice differences from React:

- Client booking still uses Flutter's stricter "choose a resolved place" flow instead of React's typed-row geocode-at-submit fallback.
- Flutter map stop markers are stop-aware but do not render custom numbered marker glyphs.
- React's full broker force-status override is not recreated as a new standalone control; Flutter now covers broker stop completion and existing trip actions without adding a broader force-status UI.

## Source Of Truth Behavior

### Client booking

React client stores two ordered arrays: `loadingLocations` and `unloadingLocations`. They are visited as:

`pickup -> loading stops -> unloading stops -> drop`

Evidence:

- `archive/legacy-web/gadidosti-client-main/src/pages/BookTruck.jsx:53` defines loading/unloading locations as extra stops.
- `archive/legacy-web/gadidosti-client-main/src/pages/BookTruck.jsx:78` calculates distance across the full pickup/loading/unloading/drop chain.
- `archive/legacy-web/gadidosti-client-main/src/pages/BookTruck.jsx:251` lets map taps target pickup, drop, or a specific loading/unloading stop.
- `archive/legacy-web/gadidosti-client-main/src/pages/BookTruck.jsx:328` creates editable stop rows without requiring coordinates immediately.
- `archive/legacy-web/gadidosti-client-main/src/pages/BookTruck.jsx:726` geocodes typed stops that are missing coordinates before submit.
- `archive/legacy-web/gadidosti-client-main/src/pages/BookTruck.jsx:794` submits `add_loading_location`.
- `archive/legacy-web/gadidosti-client-main/src/pages/BookTruck.jsx:795` submits `add_unloading_location`.
- `archive/legacy-web/gadidosti-client-main/src/pages/BookTruck.jsx:906` displays the stop-chain distance in the booking summary.
- `archive/legacy-web/gadidosti-client-main/src/pages/BookTruck.jsx:1332` renders add-stop controls in the location step.
- `archive/legacy-web/gadidosti-client-main/src/pages/BookTruck.jsx:1868` shows loading stops in the review route summary.
- `archive/legacy-web/gadidosti-client-main/src/pages/BookTruck.jsx:1871` shows unloading stops in the review route summary.

React's booking summary map itself does not appear to pass loading/unloading waypoints into `summaryMapRoutes`; it keeps the main route as pickup -> drop and relies on the summary text/chain distance for stop awareness there.

### Find Truck / nearby trucks map

React passes stops into the nearby trucks map so the route shown during truck search can preserve loading/unloading order.

Evidence:

- `archive/legacy-web/gadidosti-client-main/src/components/NearbyTrucksMap.jsx:125` accepts a `stops` prop.
- `archive/legacy-web/gadidosti-client-main/src/components/NearbyTrucksMap.jsx:245` converts stops to Directions waypoints.
- `archive/legacy-web/gadidosti-client-main/src/components/NearbyTrucksMap.jsx:425` passes those waypoints into Google Directions.
- `archive/legacy-web/gadidosti-client-main/src/components/NearbyTrucksMap.jsx:426` preserves stop order with `optimizeWaypoints: false`.

### Client tracking

React client reads `activeBooking.stops`, filters loading/unloading stops, shows them in the route rail, and uses them as map waypoints only after pickup.

Evidence:

- `archive/legacy-web/gadidosti-client-main/src/pages/TrackShipment.jsx:270` derives `routeStops`.
- `archive/legacy-web/gadidosti-client-main/src/pages/TrackShipment.jsx:395` renders pickup, extra stops, then drop in the route rail.
- `archive/legacy-web/gadidosti-client-main/src/pages/TrackShipment.jsx:559` passes route stops as Directions waypoints after pickup.
- `archive/legacy-web/gadidosti-client-main/src/pages/TrackShipment.jsx:581` adds numbered stop markers on the map.
- `archive/legacy-web/gadidosti-client-main/src/components/MapView.jsx:153` sets `optimizeWaypoints: false`, preserving the stop order.

### Driver trip

React driver reads `trip.stops`, blocks coarse status advancement until relevant stops are complete, completes only the earliest pending stop of each type, routes maps through stops, and makes "Open directions" target the next actual destination.

Evidence:

- `archive/legacy-web/gadidosti-broker-driver-main/src/pages/driver/MyTrip.jsx:247` calculates next destination from pickup/loading/unloading/drop order.
- `archive/legacy-web/gadidosti-broker-driver-main/src/pages/driver/MyTrip.jsx:269` reads `trip.stops`.
- `archive/legacy-web/gadidosti-broker-driver-main/src/pages/driver/MyTrip.jsx:273` allows only earliest pending stop per type.
- `archive/legacy-web/gadidosti-broker-driver-main/src/pages/driver/MyTrip.jsx:276` blocks starting delivery until loading stops are complete.
- `archive/legacy-web/gadidosti-broker-driver-main/src/pages/driver/MyTrip.jsx:278` blocks marking delivered until unloading stops are complete.
- `archive/legacy-web/gadidosti-broker-driver-main/src/pages/driver/MyTrip.jsx:364` passes stops to `RouteMapPanel`.
- `archive/legacy-web/gadidosti-broker-driver-main/src/pages/driver/MyTrip.jsx:464` completes a stop.
- `archive/legacy-web/gadidosti-broker-driver-main/src/components/driver/RouteMapPanel.jsx:25` converts loading/unloading stops to waypoints.
- `archive/legacy-web/gadidosti-broker-driver-main/src/components/driver/RouteMapPanel.jsx:44` skips stop waypoints pre-pickup.

### Broker job detail

React broker has two stop-related surfaces:

- Read-only job detail shows loading/unloading stops and done/pending status.
- Override/takeover panel can complete stops and force status, using the same sequential stop rule.

Evidence:

- `archive/legacy-web/gadidosti-broker-driver-main/src/pages/broker/JobDetail.jsx:232` finds the next actionable override stop.
- `archive/legacy-web/gadidosti-broker-driver-main/src/pages/broker/JobDetail.jsx:239` calls `PATCH /api/trips/:id/stops/:index/complete` from broker override.
- `archive/legacy-web/gadidosti-broker-driver-main/src/pages/broker/JobDetail.jsx:408` renders override stop controls.
- `archive/legacy-web/gadidosti-broker-driver-main/src/pages/broker/JobDetail.jsx:488` renders read-only loading/unloading stop status.
- `archive/legacy-web/gadidosti-broker-driver-main/src/pages/broker/JobDetail.jsx:471` passes stops into the broker route map.

## API Contract

This section captures the endpoint/payload contract needed for implementation. Source priority for this feature is React web source, then current Flutter API wrappers, then local backend handoff docs.

### Pricing / quote

Endpoint:

`POST /api/bookings/quote`

Auth:

Any authenticated role, per `docs/driver/DEVELOPER_HANDOFF_NOTES.md`.

Request body used by React / Flutter:

```json
{
  "truck_category": "small|medium|large|part",
  "transport_type": "intra|inter",
  "distance": 12.4,
  "capacity_used_pct": 40,
  "duration_min": 55,
  "duration_in_traffic_min": 68,
  "pickup_lat": 19.08,
  "pickup_lng": 72.88,
  "is_express": false
}
```

Notes:

- React and Flutter both calculate the quoted `distance` across `pickup -> loading stops -> unloading stops -> drop` when stop coordinates are available.
- `duration_min` and `duration_in_traffic_min` come from `/api/config/distance` for traffic-aware pricing when available.
- `is_express` should only be true for intra-city bookings.
- Current Flutter wrappers: `ApiClient.quoteBooking(...)` and `ApiClient.estimatePricing(...)`.

### Distance

Endpoint:

`POST /api/config/distance`

Request body:

```json
{
  "pickup": "Pickup address",
  "drop": "Drop address"
}
```

Response fields used:

```json
{
  "distance": 12.4,
  "durationMin": 55,
  "durationInTrafficMin": 68
}
```

Notes:

- This endpoint is pickup/drop only. React/Flutter use local leg-summed distance when extra stops exist.
- Current Flutter wrapper: `ApiClient.getDistanceEstimate(...)`.

### Create booking

Endpoint:

`POST /api/bookings`

Auth:

Client.

Optional header:

`Idempotency-Key`

Request body fields relevant to loading/unloading:

```json
{
  "pickup_location": "Pickup address",
  "pickup_lat": 19.08,
  "pickup_lng": 72.88,
  "drop_location": "Drop address",
  "drop_lat": 18.52,
  "drop_lng": 73.85,
  "transport_type": "intra|inter",
  "city": "Mumbai",
  "add_loading_location": [
    { "location": "Warehouse A", "lat": 19.10, "lng": 72.90 }
  ],
  "add_unloading_location": [
    { "location": "Depot B", "lat": 18.60, "lng": 73.80 }
  ],
  "truck_type": "Medium Truck",
  "truck_category": "medium",
  "weight": 5,
  "weight_unit": "tons",
  "quantity": 2,
  "material": "Steel",
  "notes": "Handle carefully",
  "scheduled_date": "2026-09-19T12:00:00.000Z",
  "distance": 12.4,
  "duration_min": 55,
  "duration_in_traffic_min": 68,
  "amount": 1163.8,
  "payment_status": "pending",
  "search_mode": "truck|broker",
  "search_radius_km": 10,
  "broker_id": "broker-id"
}
```

Notes:

- React always sends `add_loading_location` and `add_unloading_location` arrays at create time, even if empty.
- Current Flutter only includes those keys when non-empty.
- The important stop object shape is `{ location, lat, lng }`.
- Backend validation historically allows optional stop coordinates, but React now geocodes unresolved typed stops before submit and blocks if still unresolved.
- Current Flutter wrapper: `ApiClient.createBooking(...)`.

### Booking / tracking read models

Endpoints:

- `GET /api/bookings/:id`
- `GET /api/bookings?status=...`
- `GET /api/bookings/:id/track`
- `GET /api/track/:token`

Booking response fields relevant to parity:

```json
{
  "id": "booking-id",
  "bookingNumber": "BKG-...",
  "pickup": "Pickup address",
  "drop": "Drop address",
  "pickupLat": 19.08,
  "pickupLng": 72.88,
  "dropLat": 18.52,
  "dropLng": 73.85,
  "loadingLocations": [
    { "location": "Warehouse A", "lat": 19.10, "lng": 72.90 }
  ],
  "unloadingLocations": [
    { "location": "Depot B", "lat": 18.60, "lng": 73.80 }
  ],
  "stops": [
    { "type": "pickup", "location": "Pickup address", "lat": 19.08, "lng": 72.88, "status": "done" },
    { "type": "loading", "location": "Warehouse A", "lat": 19.10, "lng": 72.90, "status": "pending" },
    { "type": "unloading", "location": "Depot B", "lat": 18.60, "lng": 73.80, "status": "pending" },
    { "type": "drop", "location": "Drop address", "lat": 18.52, "lng": 73.85, "status": "pending" }
  ],
  "currentLat": 19.09,
  "currentLng": 72.89
}
```

Tracking response fields:

```json
{
  "status": "in_transit",
  "driverLat": 19.08,
  "driverLng": 72.88,
  "lastLocationAt": "2026-09-19T12:00:00.000Z",
  "isTerminal": false,
  "distanceRemainingKm": 3.2,
  "etaMinutes": 5,
  "incident": {
    "reason": "breakdown",
    "status": "reported",
    "mechanicStatus": "requested"
  }
}
```

Notes:

- Stop rendering should prefer `stops` when present because it includes type/order/status.
- Fall back to `loadingLocations` and `unloadingLocations` only for pre-trip/read-only display if `stops` is absent.
- Current Flutter wrappers: `getBookingById`, `getBookings`, `getBookingTrack`, `getPublicTracking`.

### Trip read models

Endpoints:

- `GET /api/trips/active`
- `GET /api/trips/:id`
- `GET /api/trips?status=...`
- React broker also uses `GET /api/trips/booking/:bookingId` for override/takeover.

Trip stop shape:

```json
{
  "id": "trip-id",
  "status": "picked_up",
  "pickup": { "location": "Pickup address", "lat": 19.08, "lng": 72.88 },
  "drop": { "location": "Drop address", "lat": 18.52, "lng": 73.85 },
  "currentLocation": { "lat": 19.09, "lng": 72.89 },
  "stops": [
    { "type": "pickup", "location": "Pickup address", "lat": 19.08, "lng": 72.88, "status": "done" },
    { "type": "loading", "location": "Warehouse A", "lat": 19.10, "lng": 72.90, "status": "pending" },
    { "type": "unloading", "location": "Depot B", "lat": 18.60, "lng": 73.80, "status": "pending" },
    { "type": "drop", "location": "Drop address", "lat": 18.52, "lng": 73.85, "status": "pending" }
  ]
}
```

Notes:

- `stops` is usually just pickup/drop when no extra stops exist.
- Only `loading` and `unloading` stops are completable through the stop endpoint.
- Use the array index as the stop identifier.
- Current Flutter wrappers: `getActiveTrip`, `getTrip`, `getTrips`.
- Flutter does not currently have a wrapper for `GET /api/trips/booking/:bookingId`; broker override parity may need one.

### Update trip status

Endpoint:

`PATCH /api/trips/:tripId/status`

Auth:

Driver, broker, admin according to local handoff docs.

Request body:

```json
{
  "status": "confirmed|en_route_pickup|picked_up|in_transit|delivered|completed|cancelled",
  "pickup_otp": "1234"
}
```

Response:

```json
{
  "trip": { "id": "trip-id", "status": "in_transit" }
}
```

Important errors to surface:

- `409` too far from pickup/drop.
- `409` pending loading/unloading stops.
- `403` no access.
- `404` trip not found.

Notes:

- `pickup_otp` is only used when moving to `picked_up`.
- Backend blocks `picked_up -> in_transit` while loading stops are pending.
- Backend blocks `in_transit -> delivered` while unloading stops are pending.
- Current Flutter wrapper: `ApiClient.updateTripStatus(...)`.

### Complete loading/unloading stop

Endpoint:

`PATCH /api/trips/:tripId/stops/:index/complete`

Request body:

```json
{}
```

Response:

```json
{
  "trip": {
    "id": "trip-id",
    "stops": [
      { "type": "loading", "location": "Warehouse A", "status": "done" }
    ]
  },
  "message": "Stop completed"
}
```

Important errors to surface:

- `404` trip/stop not found.
- `422` index points at pickup/drop.
- `409` stop already done.
- `409` earlier same-type stop still pending.
- `409` driver too far from stop, with distance in message.
- `409` no current location yet.

Auth note:

- `docs/driver/DEVELOPER_HANDOFF_NOTES.md` says this endpoint is driver-only.
- React broker source calls this endpoint from broker override (`archive/legacy-web/gadidosti-broker-driver-main/src/pages/broker/JobDetail.jsx:239`), so broker/admin authorization must be verified before implementing Flutter broker override.
- Current Flutter wrapper exists: `ApiClient.completeTripStop(...)`.

## Flutter Current State

### Client booking: partially matching

Flutter now has loading/unloading stop state and submits the expected backend keys.

Evidence:

- `lib/features/client/presentation/widgets/client_flow_widgets.dart:4047` adds intermediate stop flow.
- `lib/features/client/presentation/widgets/client_flow_widgets.dart:4056` requires selected coordinates.
- `lib/features/client/presentation/widgets/client_flow_widgets.dart:5094` calculates route distance across pickup/loading/unloading/drop.
- `lib/features/client/presentation/widgets/client_flow_widgets.dart:5765` submits `add_loading_location`.
- `lib/features/client/presentation/widgets/client_flow_widgets.dart:5769` submits `add_unloading_location`.
- `lib/features/client/presentation/widgets/client_flow_widgets.dart:6930` includes loading/unloading stops in booking map camera/marker points.

Differences:

- Flutter requires the user to choose a suggestion with coordinates; React allows typed stops and geocodes them at submit time.
- Flutter does not create empty editable stop rows inline; it opens a dedicated location picker and only adds the stop after a resolved place is chosen.
- Flutter does not match React's map-tap pinning model for individual loading/unloading stop rows.
- Flutter's booking map camera/markers include stop points, but route polyline is intentionally cleared when extra stops exist. That is different from React's nearby-truck map, which uses ordered stop waypoints.
- `GooglePlacesService.fetchDrivingRoute` has no waypoint parameter today (`lib/core/services/google_places_service.dart:242`), so any Flutter map parity work must extend the service before shared maps can draw ordered stop routes.

### Client tracking/details/list: not matching

Flutter client tracking and delivery screens mostly use pickup/drop only.

Evidence:

- `lib/features/client/data/client_booking_models.dart` keeps `raw`, but `ClientBooking` has no typed `stops` field.
- `lib/features/client/presentation/screens/tracking_details_screen.dart:1975` calls `_ReactRouteRail` with only `fromLocation` and `toLocation`.
- `lib/features/client/presentation/screens/tracking_details_screen.dart:2246` `_ReactRouteRail` accepts only pickup/drop.
- `lib/features/client/presentation/screens/client_delivery_screen.dart:452` renders `_CompactRouteBlock` with only pickup/drop.
- `lib/features/client/presentation/widgets/tracking_route_map_view.dart:40` reads pickup/drop/live only.
- `lib/features/client/presentation/widgets/tracking_route_map_view.dart:253` fetches a route with only origin/destination.

Missing for parity:

- Parse booking/trip `stops`.
- Render pickup -> loading -> unloading -> drop in route rails/cards.
- Show done status for completed stops.
- Route map through stop waypoints after pickup.
- Add numbered stop markers.
- Preserve waypoint order.
- Apply the same behavior to public tracking if the public tracking payload includes stops.

### Driver trip: mostly matching, with map/directions gaps

Flutter driver can complete stops and blocks status advancement.

Evidence:

- `lib/features/driver/presentation/screens/driver_delivery_details_screen.dart:691` calls `completeTripStop`.
- `lib/features/driver/presentation/screens/driver_delivery_details_screen.dart:962` reads `tripRaw['stops']`.
- `lib/features/driver/presentation/screens/driver_delivery_details_screen.dart:982` finds the next actionable stop index.
- `lib/features/driver/presentation/screens/driver_delivery_details_screen.dart:1001` blocks status advancement for pending loading/unloading stops.
- `lib/features/driver/presentation/screens/driver_delivery_details_screen.dart:1017` renders the loading/unloading checklist.

Differences:

- Flutter map route still uses only pickup/live/drop via shared `TrackingRouteMapView`; it does not route through loading/unloading stops.
- Flutter does not appear to compute "open maps / next destination" from loading/unloading stops like React does.
- `TrackingDemoShipment` does not expose stop data, so shared map widgets cannot consume it yet.

### Broker: not matching

Flutter broker screens do not currently expose stop data or override stop controls.

Evidence:

- `rg` found no broker-side calls to `completeTripStop`.
- `rg` found no broker-side `Loading & Unloading Stops`, `Mark Loaded`, or `Mark Unloaded` UI.
- `lib/features/broker/presentation/screens/broker_request_detail_screen.dart:1564` route detail uses pickup/drop only.
- `lib/features/broker/presentation/screens/broker_active_jobs_screen.dart:623` route display uses pickup/drop only.
- `lib/features/broker/presentation/screens/broker_tracking_screen.dart:1633` uses `TrackingRouteMapView`, which has no stops support.

Missing for parity:

- Parse stops into broker job/trip models.
- Show read-only stop list/status on active job/detail/history/tracking where React does.
- Add broker takeover/override stop completion using existing `ApiClient.completeTripStop`.
- Add force-status/override handling with backend 409 messages surfaced verbatim, if the corresponding Flutter broker workflow is intended to match React `JobDetail`.

## Implementation Plan For Later

Do not implement until approved.

1. Add a shared stop model
   - Suggested type: `RouteStop` or `TripRouteStop`.
   - Fields: `index`, `type`, `location`, `lat`, `lng`, `status`.
   - Helpers: `isLoading`, `isUnloading`, `isDone`, `isExtraStop`, `nextActionableIndex(type)`.

2. Extend shared shipment/booking models
   - Add `stops` to `TrackingDemoShipment`.
   - Add typed `stops` to `ClientBooking`.
   - Add typed `stops` to broker active job/detail models that render route data.
   - Preserve raw fallback parsing from `stops`, nested `trip.stops`, or `booking.stops` where APIs differ.

3. Upgrade shared map routing
   - Add `stops` to `TrackingRouteMapView`.
   - For pre-pickup: route live/pickup, skip stop waypoints, keep drop visible.
   - After pickup: route live-or-pickup to drop through loading/unloading stop waypoints.
   - Add stop markers with labels and order preserved.
   - Extend `GooglePlacesService.fetchDrivingRoute` to accept ordered waypoints and send them to Google Directions.
   - Keep waypoint optimization disabled, matching React.

4. Match client tracking UI
   - Update `_ReactRouteRail` and `_CompactRouteBlock` to accept stops.
   - Render pickup, each loading/unloading stop, then drop.
   - Show a completion indicator for `status == done`.
   - Wire this into `tracking_details_screen.dart`, `client_delivery_screen.dart`, `client_tracking_screen.dart`, and public tracking if data is present.

5. Finish driver parity
   - Pass stops into map widgets.
   - Add next-destination logic matching React: pickup pre-pickup, first pending loading after pickup, first pending unloading after loading/in transit, otherwise drop.
   - Use next destination for any Google Maps external navigation entry point.

6. Add broker parity
   - Show read-only stops/status in broker active jobs, tracking, history/detail screens.
   - Add override/takeover panel stop completion where Flutter has the equivalent broker job detail flow.
   - Use `ApiClient.completeTripStop`.
   - Disable non-actionable stops and surface backend errors.
   - Confirm whether force-status exists already in Flutter; if not, decide whether to add it as part of React parity.

7. Client booking polish
   - Decide whether Flutter should exactly copy React's typed-stop geocode fallback or keep stricter "must choose suggestion" behavior.
   - If exact parity is required, add geocode-before-submit for loading/unloading stops.
   - Decide whether to copy React's inline empty stop rows plus map-tap pin targeting.
   - Preserve current stop-chain quote distance behavior.

8. Test checklist
   - Booking payload with no stops remains unchanged.
   - Booking payload with one loading and one unloading stop matches React keys and order.
   - Typed stop without coordinates either geocodes like React or blocks by agreed product choice.
   - Client tracking shows stops and map waypoints only after pickup.
   - Driver cannot advance from `picked_up` with pending loading stops.
   - Driver cannot advance from `in_transit` with pending unloading stops.
   - Driver can complete only earliest pending stop per type.
   - Broker read-only screens show done/pending status.
   - Broker override can mark earliest pending stop and updates UI.

## Risk Notes

- The existing Flutter `docs/reference/LOADING_UNLOADING_STOPS_FLUTTER_GUIDE.md` is stale. It says Flutter has none of this, but current Flutter already has client stop submission and driver stop completion.
- The shared Flutter `TrackingRouteMapView` is used by client, broker, and driver-adjacent screens. Adding stops there is efficient but needs careful regression testing because many screens depend on it.
- Broker parity may require product confirmation: React has a stronger broker override/takeover concept than the current Flutter broker screens expose.
