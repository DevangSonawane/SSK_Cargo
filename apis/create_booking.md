Bookings
Client booking lifecycle: create (system price or a client-proposed price), list (role-scoped), view, live-track, advance status through the delivery pipeline, and view incoming broker negotiation offers.



POST
/api/bookings/validate-location
Check the Locations step before letting the user continue (client)


Stateless — creates nothing. Runs the exact same pickup_location/drop_location/transport_type/city rule as POST /api/bookings (see that endpoint's description), so a 200 here guarantees these same location fields will pass validation on the real POST /api/bookings call later. Call this right after the user fills in the Locations step, and only let them continue to Load Info if it 200s.

Parameters
Try it out
No parameters

Request body

application/json
Example Value
Schema
{
  "pickup_location": "string",
  "drop_location": "string",
  "transport_type": "intra",
  "city": "string"
}
Responses
Code	Description	Links
200	
Location is valid

Media type

application/json
Controls Accept header.
Example Value
Schema
{
  "success": true,
  "message": "Operation successful",
  "data": {}
}
No links
422	
city missing for an intra-city booking, or pickup_location/drop_location not within the given city

Media type

application/json
Example Value
Schema
{
  "success": false,
  "message": "Something went wrong",
  "errors": [
    {}
  ]
}
No links

POST
/api/bookings
Create a booking (client)


No broker or truck is assigned at creation — the booking is broadcast as a job_request to every KYC-verified, active broker. Brokers may counter or decline; the client picks one via PATCH /api/jobs/requests/{id}/client-accept, which confirms the booking and auto-declines every other offer. The winning broker then assigns a driver + truck via POST /api/jobs/{id}/assign-driver.

transport_type / city rule: for an intra-city booking (transport_type omitted or "intra"), city is required — the single city both pickup_location and drop_location must fall within (checked as a case-insensitive substring match, e.g. city="Indore" matches an address containing "...Indore, Madhya Pradesh..."). For an inter-city booking (transport_type "inter"), city does not apply and pickup/drop may be in different cities.

Parameters
Try it out
Name	Description
Idempotency-Key
string
(header)
Optional. A duplicate key + same user replays the original booking response instead of creating a new one.

Idempotency-Key
Request body

application/json
Example Value
Schema
{
  "pickup_location": "string",
  "pickup_lat": 0,
  "pickup_lng": 0,
  "drop_location": "string",
  "drop_lat": 0,
  "drop_lng": 0,
  "transport_type": "intra",
  "city": "string",
  "truck_type": "string",
  "truck_category": "small",
  "weight": 0,
  "weight_unit": "tons",
  "quantity": 0,
  "material": "string",
  "notes": "string",
  "scheduled_date": "2026-08-04T10:04:01.448Z",
  "distance": 0,
  "duration_min": 0,
  "duration_in_traffic_min": 0,
  "amount": 0,
  "payment_status": "pending"
}
Responses
Code	Description	Links
201	
Booking created

Media type

application/json
Controls Accept header.
Example Value
Schema
{
  "success": true,
  "message": "Operation successful",
  "data": {}
}
No links
422	
Validation errors — pickup_location/drop_location missing, transport_type invalid, city missing for an intra-city booking, or pickup_location/drop_location not within the given city

Media type

application/json
Example Value
Schema
{
  "success": false,
  "message": "Something went wrong",
  "errors": [
    {}
  ]
}