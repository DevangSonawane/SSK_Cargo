import { Routes, Route, useNavigate } from 'react-router-dom';
import { useState, useEffect, useRef } from 'react';
import Sidebar from './components/Sidebar';
import TopBar from './components/TopBar';
import Toast from './components/Toast';
import Dashboard from './pages/Dashboard';
import Bookings from './pages/Bookings';
import Users from './pages/Users';
import Brokers from './pages/Brokers';
import Drivers from './pages/Drivers';
import Trucks from './pages/Trucks';
import Pricing from './pages/Pricing';
import Disputes from './pages/Disputes';
import Incidents from './pages/Incidents';
import KYC from './pages/KYC';
import Analytics from './pages/Analytics';
import Settings from './pages/Settings';
import Tracking from './pages/Tracking';
import TrackingDetail from './pages/TrackingDetail';
import Invoices from './pages/Invoices';
import Login from './pages/Login';
import { api } from './services/api';
import { requestFcmToken, onForegroundMessage } from './lib/firebase';

const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:5000';

export default function App() {
  const [authData, setAuthData] = useState(() => {
    try { return JSON.parse(localStorage.getItem('ssk_admin_auth')); } catch { return null; }
  });
  const [mobileOpen, setMobileOpen] = useState(false);
  const [sidebarHovered, setSidebarHovered] = useState(false);
  const [pushToast, setPushToast] = useState(null);
  const fcmTokenRef = useRef(null);
  const navigate = useNavigate();

  const isLoggedIn = !!authData;
  const accessToken = authData?.tokens?.access_token;

  const handleLogin = (user, tokens) => {
    const data = { user, tokens };
    localStorage.setItem('ssk_admin_auth', JSON.stringify(data));
    setAuthData(data);
  };

  const handleLogout = async () => {
    try {
      if (fcmTokenRef.current && accessToken) {
        await api.delete('/api/users/device-token', accessToken, { token: fcmTokenRef.current });
      }
    } catch { /* silently ignore — logging out should never block on this */ }
    try {
      if (authData?.tokens) {
        await fetch(`${API_BASE}/api/auth/logout`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${authData.tokens.access_token}`,
          },
          body: JSON.stringify({ refresh_token: authData.tokens.refresh_token }),
        });
      }
    } catch { /* silently ignore */ }
    localStorage.removeItem('ssk_admin_auth');
    setAuthData(null);
  };

  const toggleMobile = () => setMobileOpen(!mobileOpen);

  // Registers (or re-registers, on every login/session-start — see the
  // comment in lib/firebase.js on why that covers rotation on web) the FCM
  // device token right after login. Best-effort: a user who denies the
  // notification permission, or opens this in a browser without push
  // support, should still be able to use the dashboard normally.
  useEffect(() => {
    if (!isLoggedIn || !accessToken) return;
    let cancelled = false;

    (async () => {
      try {
        const fcmToken = await requestFcmToken();
        if (cancelled || !fcmToken) return;
        fcmTokenRef.current = fcmToken;
        await api.post('/api/users/device-token', { token: fcmToken, platform: 'web' }, accessToken);
      } catch {
        // Push is a nice-to-have here, not a login blocker.
      }
    })();

    return () => { cancelled = true; };
  }, [isLoggedIn, accessToken]);

  // Foreground push only — background/killed-tab push is handled by
  // public/firebase-messaging-sw.js. Shows a toast; tapping it applies
  // data.type's UI action (currently: booking → open that booking).
  useEffect(() => {
    if (!isLoggedIn) return;
    let unsubscribe = () => {};
    let cancelled = false;

    onForegroundMessage((payload) => {
      const { notification = {}, data = {} } = payload;
      const navigateTo = data.type === 'booking' && data.booking_id
        ? `/bookings?bookingId=${data.booking_id}`
        : null;
      setPushToast({
        message: [notification.title, notification.body].filter(Boolean).join(' — ') || 'New notification',
        navigateTo,
      });
    }).then((unsub) => {
      if (cancelled) unsub();
      else unsubscribe = unsub;
    });

    return () => { cancelled = true; unsubscribe(); };
  }, [isLoggedIn]);

  if (!isLoggedIn) {
    return <Login onLogin={handleLogin} />;
  }

  return (
    <div className="min-h-screen bg-[#F0F4FA]">
      <div className="hidden lg:block">
        <Sidebar hoverExpand onHoverChange={setSidebarHovered} />
      </div>

      {mobileOpen && (
        <div className="fixed inset-0 z-50 lg:hidden">
          <div className="absolute inset-0 bg-black/40" onClick={() => setMobileOpen(false)}></div>
          <div className="absolute left-0 top-0 h-full">
            <Sidebar forceExpanded />
          </div>
        </div>
      )}

      <div className={`transition-all duration-300 ${sidebarHovered ? 'lg:ml-64' : 'lg:ml-16'}`}>
        <TopBar onMenuClick={toggleMobile} onLogout={handleLogout} user={authData?.user} />
        <main className="px-4 pt-4 pb-8 lg:px-6 lg:pt-5 lg:pb-10 min-h-[calc(100vh-4rem)]">
          <Routes>
            <Route path="/"          element={<Dashboard />} />
            <Route path="/bookings"  element={<Bookings />} />
            <Route path="/users"     element={<Users />} />
            <Route path="/brokers"   element={<Brokers />} />
            <Route path="/drivers"   element={<Drivers />} />
            <Route path="/trucks"    element={<Trucks />} />
            <Route path="/tracking"        element={<Tracking />} />
            <Route path="/tracking/:imei"  element={<TrackingDetail />} />
            <Route path="/invoices"  element={<Invoices />} />
            <Route path="/pricing"   element={<Pricing />} />
            <Route path="/disputes"  element={<Disputes />} />
            <Route path="/incidents" element={<Incidents />} />
            <Route path="/kyc"       element={<KYC />} />
            <Route path="/analytics" element={<Analytics />} />
            <Route path="/settings"  element={<Settings />} />
          </Routes>
        </main>
      </div>

      {pushToast && (
        <Toast
          message={pushToast.message}
          type="info"
          onClose={() => setPushToast(null)}
          onClick={pushToast.navigateTo ? () => { navigate(pushToast.navigateTo); setPushToast(null); } : undefined}
        />
      )}
    </div>
  );
}
