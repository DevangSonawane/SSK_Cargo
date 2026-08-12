import { useState, useEffect, useMemo } from "react";
import {
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  BarChart, Bar, PieChart, Pie, Cell, Legend,
} from "recharts";
import { TrendingUp, ClipboardList, IndianRupee, Users } from "lucide-react";
import { api, getToken } from "../services/api";

const COLORS = ["#1976FF", "#17D86B", "#F59E0B", "#8B5CF6", "#EF4444"];

function CustomTooltip({ active, payload, label, prefix = "" }) {
  if (active && payload && payload.length) {
    return (
      <div className="bg-white px-3 py-2 rounded-lg shadow-dropdown border border-neutral-200 text-sm">
        <p className="font-medium text-neutral-700">{label}</p>
        <p className="text-primary font-semibold">
          {prefix}{payload[0].value?.toLocaleString("en-IN")}
        </p>
      </div>
    );
  }
  return null;
}

function KPITooltip({ active, payload }) {
  if (active && payload && payload.length) {
    return (
      <div className="bg-white px-2 py-1 rounded shadow-dropdown border border-neutral-200 text-xs">
        <span className="text-primary font-semibold">{payload[0].value}%</span>
      </div>
    );
  }
  return null;
}

export default function Analytics() {
  const [loading, setLoading] = useState(true);
  const [analytics, setAnalytics] = useState({});
  const [stats, setStats] = useState({});

  useEffect(() => {
    const load = async () => {
      const token = getToken();
      const [analyticsRes, statsRes] = await Promise.all([
        api.get("/api/analytics/admin", token),
        api.get("/api/admin/dashboard", token),
      ]);

      setAnalytics(analyticsRes.data || {});
      setStats(statsRes.data || {});
      setLoading(false);
    };

    load().catch(() => setLoading(false));
  }, []);

  const avgBookingsPerDay = useMemo(() => {
    const sparkline = analytics.bookingConversionSparkline || [];
    if (!sparkline.length) return 0;
    return Math.round(sparkline.reduce((sum, value) => sum + value, 0) / sparkline.length);
  }, [analytics]);

  const avgRevenuePerBooking = useMemo(() => {
    const months = analytics.gmvOverMonths || [];
    const totalGmv = months.reduce((sum, item) => sum + Number(item.gmv || 0), 0);
    const totalBookings = Number(stats.totalBookings || 0);
    if (!totalBookings) return 0;
    return Math.round(totalGmv / totalBookings);
  }, [analytics, stats]);

  const repeatClientRate = useMemo(() => {
    const clients = analytics.topClients || [];
    if (!clients.length) return 0;
    const repeatCount = clients.filter((client) => Number(client.spend || 0) > 0).length;
    return Math.round((repeatCount / clients.length) * 100);
  }, [analytics]);

  const brokerEngagementRate = useMemo(() => {
    const fleet = analytics.fleetUtilization || [];
    if (!fleet.length) return 0;
    const engaged = fleet.filter((item) => Number(item.utilization || 0) > 0).length;
    return Math.round((engaged / fleet.length) * 100);
  }, [analytics]);

  const bookingConversionData = useMemo(() => {
    const sparkline = analytics.bookingConversionSparkline || [];
    const start = new Date();
    start.setDate(start.getDate() - (sparkline.length - 1));
    return sparkline.map((value, index) => {
      const date = new Date(start);
      date.setDate(start.getDate() + index);
      return {
        month: date.toLocaleDateString("en-IN", { day: "2-digit", month: "short" }),
        rate: value,
      };
    });
  }, [analytics]);

  if (loading) {
    return (
      <div className="space-y-6 animate-fade-in">
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="bg-white rounded-xl p-6 shadow-card border border-neutral-100">
              <div className="skeleton h-4 w-32 mb-3" />
              <div className="skeleton h-8 w-20 mb-2" />
            </div>
          ))}
        </div>
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          {Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="bg-white rounded-xl p-6 shadow-card border border-neutral-100">
              <div className="skeleton h-5 w-40 mb-6" />
              <div className="skeleton h-48 w-full" />
            </div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-fade-in">
      <div>
        <h1 className="text-2xl font-poppins font-bold text-secondary">Analytics</h1>
        <p className="text-sm text-neutral-500 mt-1">Platform performance metrics and insights</p>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="stat-card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-neutral-500 font-medium">Delivery Success Rate</p>
              <h3 className="text-2xl font-poppins font-bold text-secondary mt-1">{stats.totalBookings ? Math.max(0, Math.min(100, Math.round((Number(stats.activeTrips || 0) / Number(stats.totalBookings || 1)) * 100))) : 0}%</h3>
            </div>
            <div className="w-11 h-11 rounded-xl bg-tertiary/10 flex items-center justify-center">
              <TrendingUp size={20} className="text-tertiary" />
            </div>
          </div>
        </div>
        <div className="stat-card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-neutral-500 font-medium">Avg Bookings/Day</p>
              <h3 className="text-2xl font-poppins font-bold text-secondary mt-1">{avgBookingsPerDay}</h3>
            </div>
            <div className="w-11 h-11 rounded-xl bg-primary/10 flex items-center justify-center">
              <ClipboardList size={20} className="text-primary" />
            </div>
          </div>
        </div>
        <div className="stat-card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-neutral-500 font-medium">Avg Revenue/Booking</p>
              <h3 className="text-2xl font-poppins font-bold text-secondary mt-1">₹{avgRevenuePerBooking.toLocaleString("en-IN")}</h3>
            </div>
            <div className="w-11 h-11 rounded-xl bg-warning/10 flex items-center justify-center">
              <IndianRupee size={20} className="text-warning" />
            </div>
          </div>
        </div>
        <div className="stat-card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-neutral-500 font-medium">Broker Retention Rate</p>
              <h3 className="text-2xl font-poppins font-bold text-secondary mt-1">{brokerEngagementRate}%</h3>
            </div>
            <div className="w-11 h-11 rounded-xl bg-purple-50 flex items-center justify-center">
              <Users size={20} className="text-purple-500" />
            </div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <div className="card p-5">
          <h3 className="text-base font-poppins font-semibold text-secondary mb-4">GMV (Gross Merchandise Value) - 12 Months</h3>
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={analytics.gmvOverMonths || []} margin={{ top: 5, right: 20, left: -10, bottom: 5 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#E2E8F0" />
              <XAxis dataKey="month" stroke="#94A3B8" fontSize={12} />
              <YAxis stroke="#94A3B8" fontSize={12} tickFormatter={(v) => `₹${(v / 1000000).toFixed(1)}M`} />
              <Tooltip content={<CustomTooltip prefix="₹" />} />
              <Line type="monotone" dataKey="gmv" stroke="#1976FF" strokeWidth={2.5} dot={{ fill: "#1976FF", r: 3 }} activeDot={{ r: 5 }} />
            </LineChart>
          </ResponsiveContainer>
        </div>

        <div className="card p-5">
          <h3 className="text-base font-poppins font-semibold text-secondary mb-4">Total Revenue - 12 Months</h3>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={analytics.revenueOverMonths || []} margin={{ top: 5, right: 20, left: -10, bottom: 5 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#E2E8F0" />
              <XAxis dataKey="month" stroke="#94A3B8" fontSize={12} />
              <YAxis stroke="#94A3B8" fontSize={12} tickFormatter={(v) => `₹${(v / 100000).toFixed(0)}L`} />
              <Tooltip content={<CustomTooltip prefix="₹" />} />
              <Bar dataKey="revenue" fill="#17D86B" radius={[6, 6, 0, 0]} barSize={30} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      <div className="card p-5">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-base font-poppins font-semibold text-secondary">Booking Conversion Rate</h3>
          <div className="flex items-center gap-2">
            <span className="text-2xl font-poppins font-bold text-primary">{repeatClientRate}%</span>
            <span className="text-xs text-tertiary flex items-center gap-0.5">
              <TrendingUp size={12} /> Live
            </span>
          </div>
        </div>
        <ResponsiveContainer width="100%" height={80}>
          <LineChart data={bookingConversionData}>
            <Tooltip content={<KPITooltip />} />
            <Line type="monotone" dataKey="rate" stroke="#1976FF" strokeWidth={3} dot={false} />
          </LineChart>
        </ResponsiveContainer>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <div className="card p-5">
          <h3 className="text-base font-poppins font-semibold text-secondary mb-4">Top 5 Clients by Spend</h3>
          <ResponsiveContainer width="100%" height={280}>
            <BarChart data={analytics.topClients || []} layout="vertical" margin={{ top: 5, right: 20, left: 10, bottom: 5 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#E2E8F0" horizontal={false} />
              <XAxis type="number" stroke="#94A3B8" fontSize={12} tickFormatter={(v) => `₹${(v / 100000).toFixed(0)}L`} />
              <YAxis dataKey="name" type="category" stroke="#64748B" fontSize={12} width={100} />
              <Tooltip content={<CustomTooltip prefix="₹" />} />
              <Bar dataKey="spend" fill="#1976FF" radius={[0, 6, 6, 0]} barSize={24} />
            </BarChart>
          </ResponsiveContainer>
        </div>

        <div className="card p-5">
          <h3 className="text-base font-poppins font-semibold text-secondary mb-4">Repeat Client Rate</h3>
          <div className="flex items-center justify-center relative">
            <ResponsiveContainer width="100%" height={250}>
              <PieChart>
                <Pie
                  data={[{ name: "Repeat", value: repeatClientRate }, { name: "New", value: Math.max(0, 100 - repeatClientRate) }]}
                  cx="50%"
                  cy="50%"
                  innerRadius={65}
                  outerRadius={95}
                  paddingAngle={4}
                  dataKey="value"
                >
                  <Cell fill="#1976FF" />
                  <Cell fill="#E2E8F0" />
                </Pie>
                <Tooltip />
                <Legend verticalAlign="bottom" height={36} iconType="circle" iconSize={8} />
              </PieChart>
            </ResponsiveContainer>
            <div className="absolute">
              <span className="text-3xl font-poppins font-bold text-primary">{repeatClientRate}%</span>
            </div>
          </div>
          <p className="text-center text-sm text-neutral-500 mt-2">share of currently repeating top clients</p>
        </div>
      </div>

      <div className="card p-5">
        <h3 className="text-base font-poppins font-semibold text-secondary mb-4">Fleet Utilization % - Top Brokers</h3>
        <ResponsiveContainer width="100%" height={280}>
          <BarChart data={analytics.fleetUtilization || []} margin={{ top: 5, right: 20, left: -10, bottom: 5 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="#E2E8F0" />
            <XAxis dataKey="broker" stroke="#94A3B8" fontSize={12} />
            <YAxis stroke="#94A3B8" fontSize={12} domain={[0, 100]} tickFormatter={(v) => `${v}%`} />
            <Tooltip formatter={(v) => [`${v}%`, "Utilization"]} />
            <Bar dataKey="utilization" fill="#17D86B" radius={[6, 6, 0, 0]} barSize={60} />
          </BarChart>
        </ResponsiveContainer>
      </div>

      <div className="card p-5">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="text-base font-poppins font-semibold text-secondary">Average Revenue Per Broker</h3>
            <p className="text-sm text-neutral-500 mt-1">Monthly average across all active brokers</p>
          </div>
          <div className="text-right">
            <span className="text-3xl font-poppins font-bold text-secondary">
              ₹{Math.round((analytics.revenueOverMonths || []).reduce((sum, item) => sum + Number(item.revenue || 0), 0) / Math.max(1, (analytics.fleetUtilization || []).length)).toLocaleString("en-IN")}
            </span>
            <p className="text-sm text-tertiary flex items-center justify-end gap-1">
              <TrendingUp size={14} /> Live average
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
