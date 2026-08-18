import { Search, Menu, LogOut, ChevronDown, Settings, User } from 'lucide-react';
import { useState, useRef, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import NotificationBell from './NotificationBell';

export default function TopBar({ onMenuClick, onLogout, user }) {
  const [searchOpen, setSearchOpen] = useState(false);
  const [open, setOpen] = useState(false);
  const dropRef = useRef(null);
  const navigate = useNavigate();

  const initials = user?.name
    ? user.name.split(' ').map((n) => n[0]).join('').toUpperCase().slice(0, 2)
    : 'AD';

  useEffect(() => {
    const handler = (e) => {
      if (dropRef.current && !dropRef.current.contains(e.target)) setOpen(false);
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  return (
    <header className="sticky top-0 z-30 bg-white border-b border-neutral-200/80 h-16 flex items-center justify-between px-4 lg:px-6">
      {/* Left */}
      <div className="flex items-center gap-3">
        <button
          onClick={onMenuClick}
          className="lg:hidden w-9 h-9 flex items-center justify-center rounded-xl hover:bg-neutral-100 text-neutral-600 transition-colors"
        >
          <Menu size={20} />
        </button>
        <img src="/gadidost-logo.png" alt="GadiDost" className="h-7 w-auto object-contain lg:hidden" />
        <div className={`relative hidden sm:block transition-all duration-300 ${searchOpen ? 'w-72' : 'w-52'}`}>
          <Search size={15} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-neutral-400" />
          <input
            type="text"
            placeholder="Search anything..."
            onFocus={() => setSearchOpen(true)}
            onBlur={() => setSearchOpen(false)}
            className="w-full pl-10 pr-4 py-2 text-sm bg-neutral-50 border border-neutral-200 rounded-xl focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/20 focus:bg-white transition-all"
          />
        </div>
      </div>

      {/* Right */}
      <div className="flex items-center gap-2">
        {/* Notification bell */}
        <NotificationBell />

        <div className="w-px h-6 bg-neutral-200 mx-1" />

        {/* Avatar + dropdown */}
        <div className="relative" ref={dropRef}>
          <button
            onClick={() => setOpen((v) => !v)}
            className="flex items-center gap-2.5 px-2 py-1.5 rounded-xl hover:bg-neutral-50 transition-colors"
          >
            <div className="w-9 h-9 bg-primary rounded-xl flex items-center justify-center shadow-sm flex-shrink-0">
              <span className="text-sm font-bold text-white">{initials}</span>
            </div>
            <div className="hidden sm:block text-left">
              <p className="text-sm font-semibold text-neutral-800 leading-tight">
                {user?.name || 'Admin User'}
              </p>
              <p className="text-xs text-neutral-400 leading-tight capitalize">
                {user?.role || 'Super Admin'}
              </p>
            </div>
            <ChevronDown
              size={15}
              className={`text-neutral-400 hidden sm:block transition-transform duration-200 ${open ? 'rotate-180' : ''}`}
            />
          </button>

          {/* Dropdown */}
          {open && (
            <>
              <div className="fixed inset-0 z-40" onClick={() => setOpen(false)} />
              <div className="absolute right-0 top-12 w-52 bg-white border border-neutral-100 rounded-2xl shadow-[0_8px_30px_rgba(0,0,0,0.12)] z-50 overflow-hidden">
                <div className="p-2">
                  <button
                    onClick={() => { setOpen(false); navigate('/settings'); }}
                    className="w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm text-neutral-700 hover:bg-neutral-50 transition-colors font-medium"
                  >
                    <div className="w-7 h-7 rounded-lg bg-neutral-100 flex items-center justify-center flex-shrink-0">
                      <Settings size={14} className="text-neutral-500" />
                    </div>
                    Settings
                  </button>

                  <div className="my-1.5 border-t border-neutral-100" />

                  <button
                    onClick={() => { setOpen(false); onLogout(); }}
                    className="w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm text-red-500 hover:bg-red-50 transition-colors font-medium"
                  >
                    <div className="w-7 h-7 rounded-lg bg-red-50 flex items-center justify-center flex-shrink-0">
                      <LogOut size={14} className="text-red-500" />
                    </div>
                    Sign Out
                  </button>
                </div>
              </div>
            </>
          )}
        </div>
      </div>
    </header>
  );
}
