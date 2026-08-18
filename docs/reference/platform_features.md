# Platform Features — API Documentation

For: Flutter app developer
Scope: Negotiation/bidding, mechanic breakdown assistance, admin contact visibility + driver/truck registration, and the delivery payment/POD flow.
Not covered here: live chat (out of scope for this doc), Google Maps (see separate doc `01-google-maps-integration.md`).
Base URL: `https://apigadidosti.asynk.in/api`
Auth: All endpoints require `Authorization: Bearer <access_token>` unless stated otherwise. Role restrictions are noted per endpoint.

---

## 1. Negotiation / Bidding (inDrive-style pricing)

### How it works
A booking's price isn't fixed the moment a client posts it. The system broadcasts the booking to relevant brokers as `job_requests`. Each broker can **accept**, **decline**, or **counter-offer** a different price. If a broker counters, the **client** then sees the counter and can **accept**, **reject**, or **counter back**. This can go back and forth until one side accepts or the booking is cancelled/expires.

### Job request status values
`pending` → `countered` → (`accepted` | `declined` | `expired`)

### Broker side

**List job requests sent to this broker**
`GET /jobs/requests`
Role: `broker`

**Accept a job request at the original asking price**
`PATCH /jobs/requests/:id/accept`
Role: `broker`
No request body needed.

**Decline a job request**
`PATCH /jobs/requests/:id/decline`
Role: `broker`

**Counter-offer a different price**
`PATCH /jobs/requests/:id/counter`
Role: `broker`
Request body:
```json
{
  "amount": 1450,
  "note": "Fuel prices are high on this route"
}
```
`note` is optional. Only valid while the job request's status is `pending`. Response reflects the job request with status now `countered`.

### Client side

**View all offers/counters on your booking**
`GET /bookings/:id/offers`
Role: `client`, `admin`

**Accept a broker's counter-offer**
`PATCH /jobs/requests/:id/client-accept`
Role: `client`
No body. Only valid when the job request's status is `countered`. On success, the underlying booking is advanced to `confirmed` and all other pending offers on that booking are auto-declined.

**Reject a broker's counter-offer**
`PATCH /jobs/requests/:id/client-reject`
Role: `client`
No body. Only valid when status is `countered`.

**Counter back with a different price**
`PATCH /jobs/requests/:id/client-counter`
Role: `client`
Request body:
```json
{
  "amount": 1300,
  "note": "Can you do this instead?"
}
```
Only valid when status is `countered`.

### Notes for the Flutter app
- There is no fixed number of negotiation rounds — the app should just render whatever the current status/amount is and offer the appropriate action buttons (accept/decline/counter) based on whose turn it is and the current status.
- Every offer/counter triggers a notification to the other party (uses the existing notifications system) — poll or fetch notifications to prompt the user to check the negotiation screen.

---

## 2. Mechanic / Breakdown Assistance

### How it works
While a driver is on an active trip, they can report an issue. If the reported reason is specifically `breakdown`, the system automatically creates a linked **mechanic request** that the broker (or admin) can then track and update as they arrange help.

### Driver side — report the issue

`POST /trips/:id/report-issue`
Role: `driver`
Request body:
```json
{
  "reason": "breakdown",
  "notes": "Front tyre burst near the highway toll"
}
```
`reason` options: `accident`, `breakdown`, `traffic_block`, `medical`, `other`. Only `breakdown` creates a mechanic request automatically — the others create a plain incident record only.
Trip must be in an active status for this to succeed (in-progress trip states), otherwise you'll get a `409`.

On success, both the broker and client are automatically notified.

### Broker / Admin side — view and update

**List incidents for a trip**
`GET /trips/:id/incidents`
Role: any authenticated user (scoped to trips they're party to)

Each incident includes a `mechanicRequest` sub-object when the reason was `breakdown`, containing:
```json
{
  "status": "requested",
  "mechanicName": null,
  "mechanicPhone": null,
  "notes": null
}
```

**Update the mechanic request** (assign a mechanic, update progress)
`PATCH /trips/:id/incidents/:incidentId/mechanic`
Role: `broker`, `admin`
Request body (all fields optional, send what's changed):
```json
{
  "status": "mechanic_assigned",
  "mechanicName": "Suresh Auto Repairs",
  "mechanicPhone": "9876543210",
  "notes": "ETA 30 minutes"
}
```
`status` options: `requested` → `mechanic_assigned` → `in_progress` → `resolved`.
Setting `status` to `resolved` here also automatically resolves the underlying incident.

**Resolve an incident directly** (for non-breakdown incidents, or to close out without going through mechanic states)
`PATCH /trips/:id/incidents/:incidentId/resolve`
Role: `broker`, `admin`

### Notes for the Flutter app
- If building the driver-facing app: only implement the "report breakdown/issue" side (`POST /trips/:id/report-issue`) — the mechanic tracking/assignment UI is a broker/admin concern.
- If the driver app also needs to show mechanic status back to the driver (e.g. "mechanic assigned, ETA 30 min"), read it from `GET /trips/:id/incidents`.

---

## 3. Admin: Contact Visibility + Direct Driver/Truck Registration

### Contact visibility
Admin-facing endpoints that return driver or broker details include phone numbers directly in the response — for example, incident/dispute listings include `driverPhone` and `brokerPhone` fields alongside names, so admin can call directly without navigating elsewhere. If building an admin-facing Flutter view, render these as tappable `tel:` links / native call intents.

### Driver & truck registration — now allowed for admin, not just brokers

Previously only brokers could register their own drivers/trucks. These endpoints now also accept the `admin` role:

**Create a truck**
`POST /vehicles/trucks`
Role: `broker`, `admin`
Request body:
```json
{
  "registration": "MH-12-AB-1234",
  "type": "medium",
  "category": "full",
  "capacity": "5 ton",
  "make": "Tata",
  "year": 2022,
  "insurance_expiry": "2027-03-01",
  "broker_id": "..."
}
```
**Important:** `broker_id` is required when the caller is `admin` (a truck must belong to a broker; admin must explicitly choose which broker owns it). When the caller is a `broker`, this can be omitted — it defaults to themselves.

**Register a new driver** (creates a full driver profile, not just a link)
`POST /vehicles/drivers/register`
Role: `broker`, `admin`
Request body:
```json
{
  "name": "Ramesh Kumar",
  "phone": "9123456780",
  "email": "ramesh@example.com",
  "license_no": "MH1234567890",
  "license_expiry": "2028-05-01",
  "broker_id": "..."
}
```
Same rule: `broker_id` required for admin callers, optional (defaults to self) for broker callers. `phone` must be exactly 10 digits, `email` must be valid.

**List / get / update / delete drivers and trucks** — all now also accept `admin`:
- `GET /vehicles/trucks`, `GET /vehicles/trucks/:id`, `PATCH /vehicles/trucks/:id`, `DELETE /vehicles/trucks/:id`
- `GET /vehicles/drivers`, `GET /vehicles/drivers/:id`, `PATCH /vehicles/drivers/:id`, `DELETE /vehicles/drivers/:id`
- `GET /vehicles/drivers/lookup?phone=...` — look up an existing driver by phone before creating a duplicate

### Notes for the Flutter app
- Only relevant if building an admin-facing app. If the Flutter app is client/driver-facing only, this section can be skipped.
- If admin functionality is included: the app must supply a broker picker (dropdown/search) when admin creates a truck or driver — there's no "list brokers" shortcut endpoint documented here; check with the backend team if one exists, or fall back to whatever broker-listing endpoint is available.

---

## 4. Delivery Completion: Proof of Delivery (POD) + Payment Collection

### How it works — the flow, in order
1. Driver marks the trip as arrived (existing trip status flow — not covered here, see trip status endpoints separately).
2. Driver uploads photo(s) as proof of delivery (up to 6 per trip).
3. **Branch point:** check the booking's payment status.
   - If already `paid` (client paid in advance/online) → skip straight to marking the trip complete.
   - If `pending` (cash/UPI on delivery) → show a payment collection screen, driver collects payment (UPI via their saved QR code, or cash), then confirms collection before completing the trip.
4. Trip is marked `completed`.

### Step 1: Upload proof of delivery photos

`POST /trips/:id/pod`
Role: `driver`
Content-Type: `multipart/form-data`, field name `files` (can send multiple files in one request)
Max 6 photos per trip total (across all upload calls combined — the backend tracks a running count and rejects if the new batch would exceed 6).
Trip must be in `in_transit` or `delivered` status.

**Response — 200 OK:**
```json
{
  "success": true,
  "message": "Proof of delivery uploaded",
  "data": {
    "podPhotos": [
      "https://apigadidosti.asynk.in/api/trips/pod/file/<id1>",
      "https://apigadidosti.asynk.in/api/trips/pod/file/<id2>"
    ]
  }
}
```
Each URL can be fetched directly (authenticated) via `GET /trips/pod/file/:id` to display/download the actual image.

### Step 2: Check payment status before deciding what screen to show next

`GET /trips/:id` (existing trip detail endpoint)
Role: `broker`, `driver`, `admin`

Relevant fields in the response:
```json
{
  "paymentStatus": "pending",
  "amountToCollect": 1450.00,
  "driverQrUrl": "https://apigadidosti.asynk.in/.../qr.png",
  "podPhotos": ["..."]
}
```
- `paymentStatus`: `"paid"` or `"pending"` — this is the branch condition. If `"paid"`, skip the payment screen entirely and go straight to completing the trip.
- `amountToCollect`: the booking amount, to display on the payment screen.
- `driverQrUrl`: the driver's saved personal UPI QR code image (`null` if they haven't uploaded one yet — prompt them to add one, see below).
- `podPhotos`: array of already-uploaded proof photos.

**Recompute this on every screen load, not from local app state** — if the driver backgrounds the app mid-flow and returns, or the app is killed and reopened, re-fetch this endpoint to determine which screen to resume on. Don't rely on a locally-cached "I already checked this" flag.

### Step 3 (only if payment is pending): Driver's payment QR code

If `driverQrUrl` is `null`, the driver needs to upload their personal UPI QR code once (it's then reused for all future trips):

`POST /vehicles/drivers/me/payment-qr`
Role: `driver`
Content-Type: `multipart/form-data`, field name `file` (single image)

Once uploaded, subsequent `GET /trips/:id` calls will return the saved `driverQrUrl`.

### Step 4 (only if payment is pending): Confirm payment collected

After the client has paid (scanned the UPI QR, or handed over cash), the driver confirms:

`PATCH /trips/:id/collect-payment`
Role: `driver`
Request body:
```json
{
  "mode": "upi"
}
```
`mode` options: `"upi"` or `"cash"`.

Only valid when the booking's payment status is currently `pending` — calling this when already `paid` returns a `409 Conflict`.

**Response — 200 OK:**
```json
{
  "success": true,
  "message": "Payment recorded",
  "data": {
    "paymentStatus": "paid",
    "paymentMode": "upi"
  }
}
```
This automatically notifies both the client and the broker that payment was collected.

### Step 5: Mark the trip complete
(Existing trip status transition endpoint — set status to `completed`. Not repeated here since it predates this flow; the settlement logic that already exists on this transition is unaffected by the payment/POD additions above.)

### Summary flowchart for the Flutter driver app

```
Driver arrives at drop location
        ↓
Upload POD photos (1-6) → POST /trips/:id/pod
        ↓
GET /trips/:id → check paymentStatus
        ↓
   ┌────┴────┐
 "paid"   "pending"
   │          │
   │    Show payment screen
   │    (amountToCollect, driverQrUrl or prompt to add one)
   │          │
   │    Driver collects payment (UPI scan or cash)
   │          │
   │    PATCH /trips/:id/collect-payment { mode }
   │          │
   └────┬─────┘
        ↓
  Mark trip completed
        ↓
  Show "Thank you / Complete" screen
```
