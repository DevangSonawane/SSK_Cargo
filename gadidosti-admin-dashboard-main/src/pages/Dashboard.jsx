import { useState, useEffect, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, Area, AreaChart,
} from "recharts";
import { ClipboardList, Truck, IndianRupee, CarFront, AlertTriangle, MapPin } from "lucide-react";
import StatCard from "../components/StatCard";
import Badge from "../components/Badge";
import MapView from "../components/MapView";
import { api, getToken } from "../services/api";

const PIE_COLORS = ["#1976FF", "#17D86B", "#F59E0B", "#041E42"];

// Every non-terminal trip status — same set Bookings.jsx's status tabs cover between
// "Accepted" and "Delivered", excluding the request-only "Requested" stage (no trip row
// exists yet for a booking that's still just pending broker acceptance).
const ACTIVE_TRIP_STATUSES = "confirmed,en_route_pickup,picked_up,in_transit";

function ChartTooltip({ active, payload, label, prefix = "" }) {
  if (!active || !payload?.length) return null;
  return (
    <div className="bg-secondary text-white px-3.5 py-2.5 rounded-xl shadow-lg text-sm">
      <p className="text-white/60 text-xs mb-1">{label}</p>
      <p className="font-semibold">{prefix}{payload[0].value?.toLocaleString("en-IN")}</p>
    </div>
  );
}

function SectionHeader({ title, action, onAction }) {
  return (
    <div className="card-header">
      <h3 className="card-title">{title}</h3>
      {action && (
        <button onClick={onAction} className="text-sm text-primary font-semibold hover:text-primary-dark transition-colors">
          {action}
        </button>
      )}
    </div>
  );
}

export default function Dashboard() {
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({});
  const [analytics, setAnalytics] = useState({});
  const [bookings, setBookings] = useState([]);
  const [trucks, setTrucks] = useState([]);
  const [activeTrips, setActiveTrips] = useState([]);
  const [tripsLoading, setTripsLoading] = useState(true);
  const [tripsError, setTripsError] = useState(false);
  const navigate = useNavigate();

  useEffect(() => {
    const load = async () => {
      const token = getToken();
      const [statsRes, analyticsRes, bookingsRes, trucksRes] = await Promise.all([
        api.get("/api/admin/dashboard", token),
        api.get("/api/analytics/admin", token),
        api.get("/api/bookings?limit=5&sort=desc", token),
        api.get("/api/vehicles/trucks?limit=100", token),
      ]);

      setStats(statsRes.data || {});
      setAnalytics(analyticsRes.data || {});
      setBookings(bookingsRes.data?.bookings || []);
      setTrucks(trucksRes.data?.trucks || []);
      setLoading(false);

      // Separate call, not blocking the rest of the dashboard on it — the map card has its
      // own loading/error state below.
      try {
        const tripsRes = await api.get(`/api/trips?status=${ACTIVE_TRIP_STATUSES}&limit=50`, token);
        setActiveTrips(tripsRes.data?.trips || []);
      } catch {
        setTripsError(true);
      } finally {
        setTripsLoading(false);
      }
    };

    load().catch(() => setLoading(false));
  }, []);

  const activeTripRoutes = useMemo(() => activeTrips.map((trip, i) => ({
    id: trip.id,
    origin: trip.pickup?.lat != null && trip.pickup?.lng != null
      ? { lat: Number(trip.pickup.lat), lng: Number(trip.pickup.lng) }
      : trip.pickup?.location,
    destination: trip.drop?.lat != null && trip.drop?.lng != null
      ? { lat: Number(trip.drop.lat), lng: Number(trip.drop.lng) }
      : trip.drop?.location,
    originLabel: trip.pickup?.location,
    destinationLabel: trip.drop?.location,
    color: PIE_COLORS[i % PIE_COLORS.length],
  })), [activeTrips]);

  const activeTripMarkers = useMemo(() => activeTrips
    .filter((trip) => trip.currentLocation?.lat != null && trip.currentLocation?.lng != null)
    .map((trip) => ({
      id: `${trip.id}-live`,
      position: { lat: Number(trip.currentLocation.lat), lng: Number(trip.currentLocation.lng) },
      color: "red",
      title: `${trip.bookingNumber || "Trip"} — live position`,
    })), [activeTrips]);

  const now = new Date();
  const greeting = now.getHours() < 12 ? "Good morning" : now.getHours() < 17 ? "Good afternoon" : "Good evening";
  const dateStr = now.toLocaleDateString("en-IN", { weekday: "long", year: "numeric", month: "long", day: "numeric" });

  const bookingsOverDays = useMemo(() => {
    const sparkline = analytics.bookingConversionSparkline || [];
    const start = new Date();
    start.setDate(start.getDate() - (sparkline.length - 1));
    return sparkline.slice(-7).map((count, index, array) => {
      const date = new Date(start);
      date.setDate(start.getDate() + (sparkline.length - array.length) + index);
      return {
        day: date.toLocaleDateString("en-IN", { weekday: "short" }),
        bookings: count,
      };
    });
  }, [analytics]);

  const revenueByWeek = useMemo(() => (
    (analytics.revenueOverMonths || []).slice(-6).map((item, index, array) => ({
      week: item.month,
      revenue: Number(item.revenue || 0),
      highlight: index === array.length - 1,
    }))
  ), [analytics]);

  const truckTypeDistribution = useMemo(() => {
    const counts = trucks.reduce((acc, truck) => {
      const key = truck.type || "Other";
      acc[key] = (acc[key] || 0) + 1;
      return acc;
    }, {});
    return Object.entries(counts).map(([name, value]) => ({ name, value }));
  }, [trucks]);

  if (loading) {
    return (
      <div className="space-y-6 animate-fade-in">
        <div className="skeleton h-16 w-72 rounded-2xl" />
        <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
          {Array.from({ length: 4 }).map((_, i) => <div key={i} className="skeleton h-36 rounded-2xl" />)}
        </div>
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
          <div className="lg:col-span-2 skeleton h-80 rounded-2xl" />
          <div className="skeleton h-80 rounded-2xl" />
        </div>
        <div className="skeleton h-72 rounded-2xl" />
        <div className="skeleton h-72 rounded-2xl" />
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-fade-in">
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-poppins font-bold text-secondary">{greeting}, Admin</h1>
          <p className="text-sm text-neutral-500 mt-0.5">{dateStr} · Here's what's happening today.</p>
        </div>
        <div className="hidden md:flex items-center gap-2 bg-white border border-neutral-200 rounded-xl px-4 py-2.5 shadow-card">
          <span className="w-2 h-2 bg-tertiary rounded-full animate-pulse" />
          <span className="text-sm font-medium text-neutral-700">Live Dashboard</span>
        </div>
      </div>

      {stats.stalePendingBookings > 0 && (
        <button
          onClick={() => navigate("/bookings")}
          className="w-full flex items-center gap-3 bg-danger/5 border border-danger/20 rounded-xl px-4 py-3 text-left hover:bg-danger/10 transition-colors"
        >
          <AlertTriangle size={18} className="text-danger flex-shrink-0" />
          <span className="text-sm text-secondary">
            <span className="font-semibold">{stats.stalePendingBookings}</span> booking{stats.stalePendingBookings === 1 ? "" : "s"} {stats.stalePendingBookings === 1 ? "has" : "have"} been pending with no broker response for over 2 hours.
          </span>
        </button>
      )}

      {stats.openIncidents > 0 && (
        <button
          onClick={() => navigate("/incidents")}
          className="w-full flex items-center gap-3 bg-warning/5 border border-warning/20 rounded-xl px-4 py-3 text-left hover:bg-warning/10 transition-colors"
        >
          <AlertTriangle size={18} className="text-warning flex-shrink-0" />
          <span className="text-sm text-secondary">
            <span className="font-semibold">{stats.openIncidents}</span> open trip incident{stats.openIncidents === 1 ? "" : "s"} need{stats.openIncidents === 1 ? "s" : ""} attention.
          </span>
        </button>
      )}

      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        <StatCard title="Total Bookings" value={stats.totalBookings || 0} icon={ClipboardList} change={stats.bookingsChange || 0} changeType="positive" variant="primary" />
        <StatCard title="Active Trips" value={stats.activeTrips || 0} icon={Truck} change={stats.activeTripsChange || 0} changeType="positive" variant="warning" />
        <StatCard title="Total Revenue" value={stats.totalRevenue || 0} icon={IndianRupee} change={stats.revenueChange || 0} changeType="positive" variant="success" prefix="₹" />
        <StatCard title="Registered Trucks" value={stats.registeredTrucks || 0} icon={CarFront} change={stats.trucksChange || 0} changeType="positive" variant="secondary" />
      </div>

      <div className="card">
        <SectionHeader title="Active Trips" action="View all bookings →" onAction={() => navigate("/bookings")} />
        <div className="p-5">
          {tripsLoading ? (
            <div className="skeleton h-[360px] rounded-xl" />
          ) : tripsError ? (
            <div className="h-[360px] flex items-center justify-center text-danger text-sm">Failed to load active trips.</div>
          ) : !activeTrips.length ? (
            <div className="h-[360px] flex flex-col items-center justify-center text-neutral-400 text-sm">
              <MapPin size={28} className="mb-2 opacity-30" />
              No trips currently active
            </div>
          ) : (
            <MapView routes={activeTripRoutes} markers={activeTripMarkers} height="360px" className="rounded-xl overflow-hidden" />
          )}
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <div className="card lg:col-span-2">
          <SectionHeader title="Bookings — Last 7 Days" />
          <div className="p-5">
            <ResponsiveContainer width="100%" height={260}>
              <AreaChart data={bookingsOverDays} margin={{ top: 5, right: 10, left: -15, bottom: 0 }}>
                <defs>
                  <linearGradient id="bookingsGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#1976FF" stopOpacity={0.15} />
                    <stop offset="95%" stopColor="#1976FF" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#E2E8F0" vertical={false} />
                <XAxis dataKey="day" stroke="#94A3B8" fontSize={12} tickLine={false} axisLine={false} />
                <YAxis stroke="#94A3B8" fontSize={12} tickLine={false} axisLine={false} />
                <Tooltip content={<ChartTooltip />} cursor={{ stroke: "#1976FF", strokeWidth: 1, strokeDasharray: "4 4" }} />
                <Area
                  type="monotone"
                  dataKey="bookings"
                  stroke="#1976FF"
                  strokeWidth={2.5}
                  fill="url(#bookingsGrad)"
                  dot={{ fill: "#1976FF", r: 4, strokeWidth: 0 }}
                  activeDot={{ r: 6, fill: "#1976FF", stroke: "#fff", strokeWidth: 2 }}
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="card">
          <SectionHeader title="Fleet Distribution" />
          <div className="p-5">
            <ResponsiveContainer width="100%" height={200}>
              <PieChart>
                <Pie data={truckTypeDistribution} cx="50%" cy="50%" innerRadius={52} outerRadius={78} paddingAngle={4} dataKey="value">
                  {truckTypeDistribution.map((_, i) => (
                    <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip content={<ChartTooltip />} />
              </PieChart>
            </ResponsiveContainer>
            <div className="grid grid-cols-2 gap-2 mt-2">
              {truckTypeDistribution.map((item, i) => (
                <div key={item.name} className="flex items-center gap-2">
                  <div className="w-2.5 h-2.5 rounded-sm flex-shrink-0" style={{ backgroundColor: PIE_COLORS[i % PIE_COLORS.length] }} />
                  <div className="min-w-0">
                    <p className="text-xs font-medium text-neutral-700 truncate">{item.name}</p>
                    <p className="text-xs text-neutral-400">{item.value} trucks</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      <div className="card">
        <SectionHeader title="Weekly Revenue" />
        <div className="p-5">
          <ResponsiveContainer width="100%" height={240}>
            <BarChart data={revenueByWeek} margin={{ top: 5, right: 10, left: -5, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#E2E8F0" vertical={false} />
              <XAxis dataKey="week" stroke="#94A3B8" fontSize={12} tickLine={false} axisLine={false} />
              <YAxis stroke="#94A3B8" fontSize={12} tickLine={false} axisLine={false} tickFormatter={(v) => `₹${(v / 100000).toFixed(1)}L`} />
              <Tooltip content={<ChartTooltip prefix="₹" />} cursor={{ fill: "#1976FF", fillOpacity: 0.05 }} />
              <Bar dataKey="revenue" radius={[8, 8, 0, 0]} barSize={52}>
                {revenueByWeek.map((item, i) => (
                  <Cell key={i} fill={item.highlight ? "#1976FF" : "#E3F2FD"} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
          <p className="text-xs text-neutral-400 mt-2 text-right">Latest period highlighted in blue</p>
        </div>
      </div>

      <div className="card">
        <SectionHeader title="Recent Bookings" action="View all →" onAction={() => navigate("/bookings")} />
        <div className="overflow-x-auto">
          <table className="data-table">
            <thead>
              <tr>
                <th>Booking ID</th>
                <th>Client</th>
                <th>Route</th>
                <th>Truck Type</th>
                <th>Status</th>
                <th className="text-right">Amount</th>
              </tr>
            </thead>
            <tbody>
              {bookings.map((booking) => (
                <tr key={booking.id}>
                  <td className="font-semibold text-primary">{booking.id}</td>
                  <td className="font-medium text-neutral-800">{booking.clientName || booking.client_name || "-"}</td>
                  <td className="text-neutral-500">{booking.pickup} to {booking.drop}</td>
                  <td>{booking.truckType || booking.truck_type || "-"}</td>
                  <td><Badge status={booking.status} /></td>
                  <td className="text-right font-semibold text-neutral-800">₹{Number(booking.amount || 0).toLocaleString("en-IN")}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
