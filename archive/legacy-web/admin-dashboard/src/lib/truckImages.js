// Same artwork/mapping as the client app's src/lib/truckImages.js, for the same 4 fixed
// truck_category values used by Trucks.jsx's register form (TRUCK_CATEGORIES) and returned by
// GET /api/vehicles/trucks. "medium" points at truck-marker.png rather than a re-copied
// Tata_407_deselected.png — same image, already present here for the Live Tracking marker
// (see lib/truckIcon.js), no need for a duplicate file.
export const TRUCK_IMAGES = {
  small: '/truck/109_ICON_WITHOUT_DIMENSIONS.png',
  medium: '/truck/truck-marker.png',
  large: '/truck/2161_ICON_WITHOUT_DIMENSIONS.png',
  part: '/truck/1149_ICON_WITHOUT_DIMENSIONS.png',
};
