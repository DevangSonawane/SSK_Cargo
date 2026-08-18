import { useCallback, useEffect, useMemo, useState } from "react";
import { GoogleMap, useJsApiLoader, Marker, DirectionsService, DirectionsRenderer } from "@react-google-maps/api";
import { GOOGLE_MAPS_SCRIPT_ID, GOOGLE_MAPS_LIBRARIES } from "../lib/googleMaps";

const DEFAULT_CENTER = { lat: 22.5, lng: 78.9 }; // Center of India — used only when there's nothing to fit bounds to

const MARKER_ICON = (color) => `https://maps.google.com/mapfiles/ms/icons/${color || "blue"}-dot.png`;

const MAP_OPTIONS = {
  streetViewControl: false,
  mapTypeControl: false,
  fullscreenControl: false,
  clickableIcons: false,
};

// One route's directions request + rendered polyline. Origin/destination can be lat/lng
// objects or plain address/city strings — the Directions API resolves either. Reports back
// the geocoded start/end points so MapView can still drop pickup/drop pins even when a trip
// only ever stored address text, not raw coordinates.
function RouteRenderer({ route, onResolved }) {
  const [directions, setDirections] = useState(null);
  const [requested, setRequested] = useState(false);

  useEffect(() => {
    setDirections(null);
    setRequested(false);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [route.origin, route.destination, JSON.stringify(route.waypoints || [])]);

  if (!route.origin || !route.destination) return null;

  return (
    <>
      {!requested && (
        <DirectionsService
          options={{
            origin: route.origin,
            destination: route.destination,
            waypoints: route.waypoints,
            optimizeWaypoints: false,
            travelMode: "DRIVING",
          }}
          callback={(result, status) => {
            setRequested(true);
            if (status === "OK" && result) {
              setDirections(result);
              const leg = result.routes[0]?.legs?.[0];
              if (leg) {
                onResolved?.(route.id, { start: leg.start_location.toJSON(), end: leg.end_location.toJSON() });
              }
            }
          }}
        />
      )}
      {directions && (
        <DirectionsRenderer
          directions={directions}
          options={{
            suppressMarkers: true,
            preserveViewport: true,
            polylineOptions: { strokeColor: route.color || "#1976FF", strokeWeight: 4, strokeOpacity: 0.85 },
          }}
        />
      )}
    </>
  );
}

// Shared map for admin screens — accepts routes (drawn via the Directions API, one entry per
// trip when a full route line is needed) and markers (plain pins, e.g. a trip's live position)
// as props, so multiple trips can render on the same map without each page reimplementing map
// plumbing. Loading/error states reuse this app's existing skeleton/card conventions.
export default function MapView({ routes = [], markers = [], height = "400px", className = "", zoom, onMarkerClick }) {
  const { isLoaded, loadError } = useJsApiLoader({
    id: GOOGLE_MAPS_SCRIPT_ID,
    googleMapsApiKey: import.meta.env.VITE_GOOGLE_MAPS_API_KEY,
    libraries: GOOGLE_MAPS_LIBRARIES,
  });

  const [map, setMap] = useState(null);
  const [resolvedEndpoints, setResolvedEndpoints] = useState({});

  useEffect(() => {
    setResolvedEndpoints({});
  }, [routes.map((r) => r.id).join(",")]);

  const handleResolved = useCallback((routeId, endpoints) => {
    setResolvedEndpoints((prev) => ({ ...prev, [routeId]: endpoints }));
  }, []);

  const routeMarkers = useMemo(
    () =>
      routes.flatMap((route) => {
        const resolved = resolvedEndpoints[route.id];
        if (!resolved) return [];
        return [
          { id: `${route.id}-start`, position: resolved.start, color: "blue", title: route.originLabel || "Pickup" },
          { id: `${route.id}-end`, position: resolved.end, color: "green", title: route.destinationLabel || "Drop" },
        ];
      }),
    [routes, resolvedEndpoints]
  );

  const allMarkers = useMemo(() => [...routeMarkers, ...markers], [routeMarkers, markers]);
  const pointsKey = allMarkers.map((m) => `${m.position?.lat},${m.position?.lng}`).join("|");

  const onLoad = useCallback((instance) => setMap(instance), []);
  const onUnmount = useCallback(() => setMap(null), []);

  useEffect(() => {
    if (!map || !isLoaded || !window.google || !allMarkers.length) return;
    if (allMarkers.length === 1) {
      map.setCenter(allMarkers[0].position);
      if (!zoom) map.setZoom(13);
      return;
    }
    const bounds = new window.google.maps.LatLngBounds();
    allMarkers.forEach((m) => { if (m.position) bounds.extend(m.position); });
    map.fitBounds(bounds, 56);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [map, isLoaded, pointsKey]);

  if (loadError) {
    return (
      <div className={`flex flex-col items-center justify-center bg-neutral-50 rounded-xl ${className}`} style={{ height }}>
        <p className="text-sm text-neutral-500">Couldn't load the map right now.</p>
      </div>
    );
  }

  if (!isLoaded) {
    return <div className={`skeleton ${className}`} style={{ height }} />;
  }

  return (
    <GoogleMap
      mapContainerClassName={className}
      mapContainerStyle={{ width: "100%", height }}
      center={allMarkers[0]?.position || DEFAULT_CENTER}
      zoom={zoom || 5}
      onLoad={onLoad}
      onUnmount={onUnmount}
      options={MAP_OPTIONS}
    >
      {allMarkers.map((m) => (
        <Marker
          key={m.id}
          position={m.position}
          icon={m.iconUrl ? {
            url: m.iconUrl,
            scaledSize: new window.google.maps.Size(40, 40),
            anchor: new window.google.maps.Point(20, 20),
          } : { url: MARKER_ICON(m.color) }}
          title={m.title}
          label={m.label}
          onClick={onMarkerClick ? () => onMarkerClick(m.id) : undefined}
        />
      ))}
      {routes.map((route) => (
        <RouteRenderer key={route.id} route={route} onResolved={handleResolved} />
      ))}
    </GoogleMap>
  );
}
