# Google Maps Integration — API Documentation

For: Flutter app developer
Scope: All backend endpoints and data needed to replicate the Google Maps features (address search, live tracking, distance/route, traffic-aware pricing) in the Flutter app.
Base URL: `https://apigadidosti.asynk.in/api` (all paths below are relative to this)
Auth: All endpoints below require `Authorization: Bearer <access_token>` header unless stated otherwise.

---

## 1. Overview — how Maps is used across the platform

Google Maps is **not** proxied entirely through our backend. The pattern is:

- **Places Autocomplete** (address search-as-you-type) and **map rendering** (pins, live truck marker, drawn routes) happen **client-side**, directly against Google's APIs, using the same API key issued for this project.
- **Distance + traffic data** (needed for pricing) is fetched **through our backend**, not directly from Google — because the backend combines it with server-side pricing logic afterward.

So for the Flutter app, you'll need:
1. The **Google Maps API key** (ask the web team for it — same key used across the 3 web apps, restricted per-platform in Google Cloud Console).
2. The Google Maps Flutter SDK (`google_maps_flutter` package) for map rendering.
3. A Places Autocomplete package or Google's Places SDK for address search (`google_places_flutter` or similar — implementation detail, your choice).
4. Our backend's `/config/distance` endpoint for distance + traffic data (do NOT call Google's Distance Matrix/Directions API directly from the app for this — use our endpoint, since it's the single source of truth the pricing engine also uses).

**APIs enabled on the Google Cloud project** (all already live, no additional enabling needed): Places API, Places API (New), Geocoding API, Maps JavaScript API (web only — Flutter uses the native SDK instead), Directions API, Distance Matrix API.

---

## 2. Address Autocomplete (client-side, direct to Google)

Used when: client enters pickup/drop location while booking a truck.

This is implemented entirely on the frontend, not via our backend. In the Flutter app, use the Places Autocomplete widget/SDK directly with the shared API key. When the user selects a suggestion, extract:
- The formatted address (string, for display and storage)
- The `lat`/`lng` coordinates (from the Place Details response)

**Important:** send both the address text AND the lat/lng to our backend when creating a booking (see `POST /bookings` in the features doc) — the backend does **not** re-geocode addresses itself. It trusts whatever coordinates the app supplies from Places Autocomplete. This avoids double-billing Google for the same geocoding lookup.

---

## 3. Map rendering (client-side, direct to Google)

Used in: live shipment tracking (client), driver navigation view, broker fleet view, admin all-trips view.

Implemented with the native Google Maps Flutter SDK (`google_maps_flutter`). No backend endpoint is involved in rendering the map itself — the backend only supplies the **data points** to plot:
- Pickup/drop coordinates — come from the booking record (see features doc, `GET /bookings/:id`)
- Live truck position — comes from the trip record's `current_lat`/`current_lng`, updated by the driver (see below)
- Route line — either draw it yourself using the Directions API result (if you want turn-by-turn polyline detail), or simply draw a straight line/marker pair if that's sufficient for MVP. The web apps use `DirectionsService`/`DirectionsRenderer` from `@react-google-maps/api` for this — the Flutter equivalent is calling Directions API directly from the app (client-side) with the same key, or using a Flutter polyline package.

## 4. Driver live location — sending position updates

**Endpoint:** `PATCH /vehicles/drivers/me/location`
**Role required:** `driver`

**Request body:**
```json
{
  "lat": 19.0760,
  "lng": 72.8777
}
```

**Response:** `200 OK` — no significant body, just confirms the update.

Call this periodically (every 3-5 seconds is the pattern used elsewhere in the system) while the driver is online/on a trip, from the Flutter app's background location service.

There is also a trip-specific location endpoint:

**Endpoint:** `PATCH /trips/:id/location`
**Role required:** `driver`

**Request body:** same shape (`lat`, `lng`). Use this one while actively on a trip — it updates the trip's live position specifically, which is what feeds the client's tracking map and admin's all-trips map.

---

## 5. Distance + traffic data (via our backend, not Google directly)

**Endpoint:** `POST /config/distance`
**Role required:** any authenticated user

**Request body:**
```json
{
  "pickup": "Bandra Kurla Complex, Mumbai",
  "drop": "Chhatrapati Shivaji Airport, Mumbai"
}
```
(Plain address strings — not lat/lng. The backend passes these straight to Google's Distance Matrix API.)

**Response — 200 OK:**
```json
{
  "success": true,
  "message": "Distance fetched",
  "data": {
    "distance": 6.8,
    "durationMin": 17,
    "durationInTrafficMin": 22
  }
}
```
- `distance` — kilometers (number, one decimal place)
- `durationMin` — normal/free-flow travel time in minutes
- `durationInTrafficMin` — current live-traffic-adjusted travel time in minutes

**Response — 404 Not Found** (if Google can't resolve one of the addresses):
```json
{
  "success": false,
  "message": "Distance unavailable for <pickup> -> <drop>. Please check the spelling or try a different location."
}
```

**Why this matters for pricing:** the app must call this endpoint **before** requesting a price quote, and pass `durationMin`/`durationInTrafficMin` straight through into the pricing endpoint (see features doc, `POST /pricing/estimate`) — that's what drives the traffic-surge multiplier on the fare. If you skip calling this and go straight to the pricing endpoint without duration data, pricing will silently compute with **no traffic surge** (defaults to a 1.0x multiplier) — not an error, just a flat/static price.

---

## 6. Sequence: what the app should do, in order, when a client books a truck

1. Client types pickup address → Places Autocomplete (direct to Google) → user selects a suggestion → capture address text + lat/lng.
2. Repeat for drop address.
3. Call `POST /config/distance` with both address strings → get back `distance`, `durationMin`, `durationInTrafficMin`.
4. Call `POST /pricing/estimate` (see features doc) passing `distance`, `duration_min`, `duration_in_traffic_min`, plus truck category/transport type → get back the priced breakdown, including any traffic surcharge.
5. Show the price breakdown to the user, including the traffic surge line if present.
6. On confirm, call `POST /bookings` with pickup/drop addresses, their lat/lng, and the distance — this creates the actual booking.

---

## 7. What NOT to do

- Don't call Google's Geocoding, Directions, or Distance Matrix APIs directly from the Flutter app for anything that feeds pricing — always go through `/config/distance` and `/pricing/estimate`, so pricing stays consistent with the web apps and stays auditable server-side.
- Don't attempt to compute the traffic multiplier yourself in the app — it's server-side logic in `PricingModel.estimate()`, tiered and capped at 1.5x; duplicating it in the app risks drift if the tiers are ever tuned.
