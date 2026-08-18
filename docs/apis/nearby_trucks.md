GET
/api/vehicles/trucks/nearby
Available trucks near a pickup point, with driver live GPS (any authenticated role)


Powers the Truck-selection step of booking creation — shows available trucks (status=available, with an available, KYC-verified driver actually assigned to it, who has reported a location) near the client's pickup point, before any broker/driver is assigned to the booking. Platform-wide, not scoped to one broker.

No driver name/phone is included — nobody has been assigned to this client's booking yet. Each result includes the driver's live current_lat/current_lng and last_location_at so the frontend can plot it on a map; there's no push/socket channel for movement — join the truck:{truckId} Socket.IO room (event join-truck-tracking) for each returned truck to get live truck-location push updates instead of polling.

Parameters
Try it out
Name	Description
pickup_lat *
number
(query)
19.076
pickup_lng *
number
(query)
72.8777
truck_category
string
(query)
Available values : small, medium, large, part


--
capacity
string
(query)
Matches the truck's freeform capacity field exactly (case-insensitive) — pass whatever the user picked on the Truck step (e.g. "5" or "5 Tons"), matching the value shown on the category card.

5 Tons
radius_km
number
(query)
Only trucks within this many km of the pickup point are returned. Omit for no radius cap (still sorted nearest-first).

radius_km
page
integer
(query)
Default value : 1

1
limit
integer
(query)
Default value : 20

20
Responses
Code	Description	Links
200	
Nearby trucks fetched

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
pickup_lat/pickup_lng missing or invalid

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