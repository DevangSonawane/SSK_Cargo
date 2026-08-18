import { useCallback, useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Search, Eye, ChevronLeft, ChevronRight, List, Map as MapIcon, Gauge, History } from 'lucide-react';
import Badge from '../components/Badge';
import MapView from '../components/MapView';
import { api, getToken } from '../services/api';
import { buildTruckIcon } from '../lib/truckIcon';

const POLL_INTERVAL_MS = 15000;

function statusLabel(status) {
  return status === 'online' ? 'Available' : 'Offline';
}

function formatDateTime(value) {
  if (!value) return '—';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return date.toLocaleString('en-IN', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' });
}

export default function Tracking() {
  const navigate = useNavigate();
  const [devices, setDevices] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [tab, setTab] = useState('list');
  const [cachedFallback, setCachedFallback] = useState(false);
  const itemsPerPage = 10;

  const fetchDevices = useCallback(async ({ silent } = {}) => {
    if (!silent) setLoading(true);
    if (!silent) setError('');
    try {
      const res = await api.get('/api/tracking/devices', getToken());
      if (res.success) {
        setDevices(res.data.devices || []);
        setCachedFallback(res.data.source === 'cached');
        setError('');
      } else if (!silent) {
        setError(res.message || 'Failed to load tracker devices');
      }
    } catch {
      if (!silent) setError('Network error — could not load tracker devices');
    } finally {
      if (!silent) setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchDevices();
    const interval = setInterval(() => fetchDevices({ silent: true }), POLL_INTERVAL_MS);
    return () => clearInterval(interval);
  }, [fetchDevices]);

  const filtered = devices.filter((d) =>
    !searchTerm ||
    d.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    d.deviceImei?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    statusLabel(d.status).toLowerCase().includes(searchTerm.toLowerCase())
  );

  const totalPages = Math.ceil(filtered.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const paginated = filtered.slice(startIndex, startIndex + itemsPerPage);

  const markers = filtered
    .filter((d) => d.latitude != null && d.longitude != null)
    .map((d) => ({
      id: d.deviceImei,
      position: { lat: Number(d.latitude), lng: Number(d.longitude) },
      iconUrl: buildTruckIcon(d.course),
      title: d.source === 'cached' ? `${d.name} (last seen)` : d.name,
    }));

  const openDevice = (device) => navigate(`/tracking/${device.deviceImei}`);

  return (
    <div className="space-y-4 animate-fade-in">
      <div>
        <h1 className="text-2xl font-poppins font-bold text-secondary">Live Tracking</h1>
        <p className="text-sm text-neutral-500 mt-1">GPS tracker devices, refreshed every 15 seconds</p>
      </div>

      <div className="card p-4 flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-3">
        <div className="relative max-w-xs w-full">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-neutral-400" />
          <input
            type="text"
            placeholder="Search by name, IMEI or status..."
            value={searchTerm}
            onChange={(e) => { setSearchTerm(e.target.value); setCurrentPage(1); }}
            className="form-input pl-9"
          />
        </div>
        <div className="flex items-center gap-1 bg-neutral-100 rounded-lg p-1 flex-shrink-0">
          <button
            onClick={() => setTab('list')}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-md text-sm font-medium transition-colors ${tab === 'list' ? 'bg-white text-secondary shadow-sm' : 'text-neutral-500 hover:text-neutral-700'}`}
          >
            <List size={15} /> List
          </button>
          <button
            onClick={() => setTab('map')}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-md text-sm font-medium transition-colors ${tab === 'map' ? 'bg-white text-secondary shadow-sm' : 'text-neutral-500 hover:text-neutral-700'}`}
          >
            <MapIcon size={15} /> Map
          </button>
        </div>
      </div>

      {error && (
        <div className="card p-4 text-sm text-danger flex items-center gap-2">
          <span>{error}</span>
          <button onClick={() => fetchDevices()} className="underline">Retry</button>
        </div>
      )}

      {!error && cachedFallback && (
        <div className="card p-4 text-sm text-amber-700 bg-amber-50 border border-amber-200 flex items-center gap-2">
          <History size={16} className="flex-shrink-0" />
          <span>Live tracking is unavailable right now — showing each device's last known position.</span>
        </div>
      )}

      {loading ? (
        <div className="card p-10 flex justify-center">
          <div className="w-6 h-6 border-2 border-primary/20 border-t-primary rounded-full animate-spin" />
        </div>
      ) : tab === 'map' ? (
        <div className="card p-2 overflow-hidden">
          <MapView markers={markers} height="600px" onMarkerClick={(imei) => navigate(`/tracking/${imei}`)} />
        </div>
      ) : (
        <div className="card overflow-hidden">
          <div className="overflow-x-auto">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Name</th>
                  <th>IMEI</th>
                  <th>Status</th>
                  <th>Speed</th>
                  <th>Ignition</th>
                  <th>Last Update</th>
                  <th className="text-center">Actions</th>
                </tr>
              </thead>
              <tbody>
                {paginated.length === 0 ? (
                  <tr><td colSpan={7} className="text-center py-12 text-neutral-400">No devices found.</td></tr>
                ) : paginated.map((device) => (
                  <tr key={device.deviceImei}>
                    <td className="font-medium text-neutral-800">{device.name || '—'}</td>
                    <td className="whitespace-nowrap font-mono text-xs text-neutral-500">{device.deviceImei}</td>
                    <td><Badge status={statusLabel(device.status)} /></td>
                    <td className="whitespace-nowrap flex items-center gap-1"><Gauge size={13} className="text-neutral-400" />{device.speed ?? '—'} km/hr</td>
                    <td>{device.ignition === true ? 'On' : device.ignition === false ? 'Off' : '—'}</td>
                    <td className="whitespace-nowrap text-neutral-500">
                      {formatDateTime(device.lastUpdate)}
                      {device.source === 'cached' && <span className="block text-[10px] text-amber-600 font-semibold">last seen</span>}
                    </td>
                    <td className="text-center">
                      <button onClick={() => openDevice(device)} className="p-1.5 text-primary bg-primary/10 rounded-lg hover:bg-primary/20 transition-colors" title="View Details">
                        <Eye size={14} />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {totalPages > 1 && (
            <div className="flex items-center justify-between px-4 py-3 border-t border-neutral-100">
              <p className="text-sm text-neutral-500">Showing {startIndex + 1} to {Math.min(startIndex + itemsPerPage, filtered.length)} of {filtered.length} entries</p>
              <div className="flex items-center gap-1">
                <button onClick={() => setCurrentPage((p) => Math.max(1, p - 1))} disabled={currentPage === 1} className="p-1.5 rounded-lg border border-neutral-200 hover:bg-neutral-50 disabled:opacity-40 transition-colors"><ChevronLeft size={16} /></button>
                {Array.from({ length: totalPages }, (_, i) => i + 1).map((page) => (
                  <button key={page} onClick={() => setCurrentPage(page)} className={`w-8 h-8 rounded-lg text-sm font-medium transition-colors ${currentPage === page ? 'bg-primary text-white' : 'text-neutral-600 hover:bg-neutral-100'}`}>{page}</button>
                ))}
                <button onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))} disabled={currentPage === totalPages} className="p-1.5 rounded-lg border border-neutral-200 hover:bg-neutral-50 disabled:opacity-40 transition-colors"><ChevronRight size={16} /></button>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
