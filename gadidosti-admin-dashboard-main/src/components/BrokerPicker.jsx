import { useState, useEffect, useRef } from 'react';
import { createPortal } from 'react-dom';
import { ChevronDown, Check, Building2, Search } from 'lucide-react';
import { api, getToken } from '../services/api';

// Searchable broker combobox backed by GET /api/admin/users?role=broker&search=... — used
// wherever an admin needs to pick which broker's fleet a new truck/driver belongs to, since
// trucks.broker_id / driver_profiles.broker_id are NOT NULL and admin has no "own" broker.
export default function BrokerPicker({ value, onChange, placeholder = 'Search broker by name or phone' }) {
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState('');
  const [results, setResults] = useState([]);
  const [loading, setLoading] = useState(false);
  const [selected, setSelected] = useState(null);
  const [pos, setPos] = useState(null);
  const wrapRef = useRef(null);
  const panelRef = useRef(null);

  useEffect(() => {
    const handler = (e) => {
      if (wrapRef.current?.contains(e.target)) return;
      if (panelRef.current?.contains(e.target)) return;
      setOpen(false);
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  useEffect(() => {
    if (!open) return;
    const updatePos = () => {
      const rect = wrapRef.current?.getBoundingClientRect();
      if (rect) setPos({ top: rect.bottom + 6, left: rect.left, width: rect.width });
    };
    updatePos();
    window.addEventListener('scroll', updatePos, true);
    window.addEventListener('resize', updatePos);
    return () => {
      window.removeEventListener('scroll', updatePos, true);
      window.removeEventListener('resize', updatePos);
    };
  }, [open]);

  useEffect(() => {
    if (!open) return;
    let cancelled = false;
    setLoading(true);
    const timer = setTimeout(async () => {
      try {
        const params = new URLSearchParams({ role: 'broker', limit: '20' });
        if (query.trim()) params.set('search', query.trim());
        const res = await api.get(`/api/admin/users?${params.toString()}`, getToken());
        if (!cancelled) setResults(res?.data?.users || []);
      } catch {
        if (!cancelled) setResults([]);
      } finally {
        if (!cancelled) setLoading(false);
      }
    }, 300);
    return () => { cancelled = true; clearTimeout(timer); };
  }, [query, open]);

  // Parent cleared the value externally (e.g. form reset) — drop the displayed selection too.
  useEffect(() => {
    if (!value) setSelected(null);
  }, [value]);

  const handleSelect = (broker) => {
    setSelected(broker);
    onChange(broker.id);
    setOpen(false);
    setQuery('');
  };

  return (
    <div className="relative w-full" ref={wrapRef}>
      <div
        role="button"
        tabIndex={0}
        onClick={() => setOpen((v) => !v)}
        onKeyDown={(e) => { if (e.key === 'Enter' || e.key === ' ') setOpen((v) => !v); }}
        className={`w-full flex items-center justify-between gap-2 bg-white border rounded-xl px-3.5 py-2.5 text-sm cursor-pointer transition-all ${
          open ? 'border-primary ring-2 ring-primary/20' : 'border-neutral-200 hover:border-neutral-300'
        }`}
      >
        {selected ? (
          <span className="text-neutral-800 font-medium truncate">{selected.name} <span className="text-neutral-400 font-normal">&middot; {selected.phone}</span></span>
        ) : (
          <span className="text-neutral-400 truncate">{placeholder}</span>
        )}
        <ChevronDown size={14} className={`text-neutral-400 flex-shrink-0 transition-transform duration-200 ${open ? 'rotate-180' : ''}`} />
      </div>

      {open && pos && createPortal(
        <div
          ref={panelRef}
          className="fixed z-[10000] bg-white border border-neutral-100 rounded-xl shadow-lg py-1"
          style={{ top: pos.top, left: pos.left, width: pos.width }}
        >
          <div className="px-2 py-1.5 border-b border-neutral-100">
            <div className="flex items-center gap-2 px-2 py-1.5 bg-neutral-50 rounded-lg">
              <Search size={13} className="text-neutral-400 flex-shrink-0" />
              <input
                autoFocus
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                placeholder="Search by name or phone..."
                className="flex-1 bg-transparent text-sm outline-none placeholder:text-neutral-400 min-w-0"
              />
            </div>
          </div>
          <div className="max-h-56 overflow-y-auto">
            {loading && <div className="px-3 py-3 text-xs text-neutral-400">Searching...</div>}
            {!loading && !results.length && (
              <div className="px-3 py-3 text-xs text-neutral-400 flex items-center gap-2">
                <Building2 size={14} className="opacity-40" /> No brokers found
              </div>
            )}
            {!loading && results.map((broker) => (
              <div
                key={broker.id}
                role="option"
                aria-selected={value === broker.id}
                onClick={() => handleSelect(broker)}
                className={`flex items-center justify-between gap-2 px-3 py-2 text-sm cursor-pointer transition-colors ${
                  value === broker.id ? 'bg-primary/5 text-primary font-medium' : 'text-neutral-700 hover:bg-neutral-50'
                }`}
              >
                <span className="truncate">{broker.name} <span className="text-neutral-400 font-normal">&middot; {broker.phone}</span></span>
                {value === broker.id && <Check className="w-3.5 h-3.5 text-primary flex-shrink-0" strokeWidth={3} />}
              </div>
            ))}
          </div>
        </div>,
        document.body
      )}
    </div>
  );
}
