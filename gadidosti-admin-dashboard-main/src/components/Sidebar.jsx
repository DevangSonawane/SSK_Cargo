import { useState } from 'react';
import { NavLink, useLocation } from 'react-router-dom';
import {
  LayoutDashboard, ClipboardList, Users, Building2, Truck,
  CarFront, IndianRupee, AlertTriangle, Flag, ShieldCheck, BarChart3,
  Settings, Radar, Receipt,
} from 'lucide-react';

const sections = [
  {
    label: 'Main',
    items: [{ path: '/', label: 'Dashboard', icon: LayoutDashboard }],
  },
  {
    label: 'Operations',
    items: [
      { path: '/bookings', label: 'Bookings', icon: ClipboardList },
      { path: '/drivers', label: 'Drivers', icon: CarFront },
      { path: '/trucks', label: 'Trucks', icon: Truck },
      { path: '/tracking', label: 'Live Tracking', icon: Radar },
    ],
  },
  {
    label: 'Management',
    items: [
      { path: '/users', label: 'Users', icon: Users },
      { path: '/brokers', label: 'Brokers', icon: Building2 },
      { path: '/pricing', label: 'Pricing', icon: IndianRupee },
    ],
  },
  {
    label: 'Finance',
    items: [
      { path: '/invoices', label: 'Invoices & Receipts', icon: Receipt },
    ],
  },
  {
    // Both are "something went wrong, admin needs to act" queues — Incidents are
    // driver-reported problems on an active trip, Disputes are client/broker complaints
    // raised on a booking after the fact. Grouped together since they're the same kind
    // of screen even though they're backed by different tables.
    label: 'Issues & Disputes',
    items: [
      { path: '/incidents', label: 'Incidents', subLabel: 'Reported by drivers', icon: AlertTriangle },
      { path: '/disputes', label: 'Disputes', subLabel: 'Raised by broker/client', icon: Flag },
    ],
  },
  {
    label: 'Compliance',
    items: [
      { path: '/kyc', label: 'KYC', icon: ShieldCheck },
    ],
  },
  {
    label: 'Insights',
    items: [
      { path: '/analytics', label: 'Analytics', icon: BarChart3 },
      { path: '/settings', label: 'Settings', icon: Settings },
    ],
  },
];

export default function Sidebar({ hoverExpand = false, forceExpanded = false, onHoverChange }) {
  const location = useLocation();
  const [hovered, setHovered] = useState(false);

  const collapsed = hoverExpand ? !hovered : !forceExpanded;

  const isActive = (path) =>
    path === '/' ? location.pathname === '/' : location.pathname.startsWith(path);

  const setHover = (value) => {
    if (!hoverExpand) return;
    setHovered(value);
    onHoverChange?.(value);
  };

  return (
    <aside
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => setHover(false)}
      className={`fixed left-0 top-0 h-screen bg-secondary z-40 transition-all duration-300 flex flex-col ${collapsed ? 'w-16' : 'w-64'}`}
    >
      {/* Logo */}
      <div className={`flex items-center h-16 border-b border-white/10 flex-shrink-0 ${collapsed ? 'justify-center px-2' : 'px-4'}`}>
        {!collapsed ? (
          <div className="bg-white rounded-xl px-2.5 py-1.5">
            <img src="/gadidost-logo.png" alt="GadiDost" className="h-7 w-auto object-contain" />
          </div>
        ) : (
          <div className="w-10 h-10 bg-white rounded-xl flex items-center justify-center overflow-hidden">
            <img src="/gadidost-logo.png" alt="GD" className="h-6 w-auto object-contain object-left" style={{ minWidth: 56, marginLeft: -4 }} />
          </div>
        )}
      </div>

      {/* Nav */}
      <nav className="flex-1 py-3 overflow-y-auto scrollbar-thin">
        {sections.map((section) => (
          <div key={section.label} className="mb-1">
            {!collapsed && (
              <p className="px-4 py-2 text-[10px] font-semibold text-white/30 uppercase tracking-widest">
                {section.label}
              </p>
            )}
            {collapsed && <div className="mx-3 my-1.5 h-px bg-white/10" />}
            <div className="px-2 space-y-0.5">
              {section.items.map((item) => {
                const active = isActive(item.path);
                const Icon = item.icon;
                return (
                  <NavLink
                    key={item.path}
                    to={item.path}
                    title={collapsed ? `${item.label}${item.subLabel ? ` — ${item.subLabel}` : ''}` : undefined}
                    className={`flex items-center gap-3 rounded-xl transition-all duration-200 ${collapsed ? 'justify-center px-0 py-3' : item.subLabel ? 'px-3 py-2' : 'px-3 py-2.5'} ${active ? 'bg-primary text-white shadow-sm' : 'text-white/60 hover:text-white hover:bg-white/8'}`}
                  >
                    <Icon size={collapsed ? 20 : 18} className="flex-shrink-0" />
                    {!collapsed && (
                      <span className="min-w-0">
                        <span className="block text-sm font-medium leading-tight">{item.label}</span>
                        {item.subLabel && (
                          <span className={`block text-[10px] leading-tight ${active ? 'text-white/70' : 'text-white/35'}`}>
                            {item.subLabel}
                          </span>
                        )}
                      </span>
                    )}
                    {!collapsed && active && <span className="ml-auto w-1.5 h-1.5 rounded-full bg-white/60 flex-shrink-0" />}
                  </NavLink>
                );
              })}
            </div>
          </div>
        ))}
      </nav>

      {/* Footer */}
      {!collapsed && (
        <div className="px-4 py-3 border-t border-white/10 flex-shrink-0">
          <p className="text-white/25 text-[11px] font-medium">© 2024 SSK Logistics</p>
        </div>
      )}
    </aside>
  );
}
