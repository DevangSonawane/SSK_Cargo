import { useState, useEffect, useCallback } from 'react';
import { Search, Eye, ChevronLeft, ChevronRight, Truck, Plus } from 'lucide-react';
import Badge from '../components/Badge';
import Modal from '../components/Modal';
import Toast from '../components/Toast';
import BrokerPicker from '../components/BrokerPicker';
import { api, getToken } from '../services/api';
import { TRUCK_IMAGES } from '../lib/truckImages';

const STATUS_LABEL = { available: 'Available', on_trip: 'On Trip', maintenance: 'Under Maintenance' };
const STATUS_OPTIONS = ['available', 'on_trip', 'maintenance'];
const TRUCK_CATEGORIES = ['small', 'medium', 'large', 'part'];
const REGISTRATION_REGEX = /^[A-Z]{2}[-\s]?\d{1,2}[-\s]?[A-Z]{1,3}[-\s]?\d{1,4}$/i;
const EMPTY_REGISTER_FORM = { brokerId: '', registration: '', category: 'small', capacity: '', make: '', year: '', insuranceExpiry: '' };

function isInsuranceExpiring(dateStr) {
  if (!dateStr) return false;
  const expiry = new Date(dateStr);
  const daysLeft = (expiry - new Date()) / (1000 * 60 * 60 * 24);
  return daysLeft < 60;
}

function formatDate(value) {
  if (!value) return '—';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return date.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' });
}

// GET /api/vehicles/trucks doesn't join a broker display name (only brokerId) —
// fall back to a shortened id so the column still shows something meaningful.
function shortId(id) {
  return id ? `#${id.slice(0, 8)}` : '—';
}

function mapTruck(t) {
  return {
    id: t.id,
    regNo: t.registration,
    type: t.type || '—',
    category: t.category,
    make: t.make || '—',
    year: t.year || '—',
    capacity: t.capacity || '—',
    broker: shortId(t.brokerId),
    driver: t.driver || '—',
    driverId: t.driverId,
    lastTrip: t.lastTrip || '—',
    insuranceExpiry: t.insuranceExpiry,
    status: t.status,
    statusLabel: STATUS_LABEL[t.status] || t.status,
  };
}

export default function Trucks() {
  const [trucks, setTrucks] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [selectedTruck, setSelectedTruck] = useState(null);
  const [statusDraft, setStatusDraft] = useState('');
  const [savingStatus, setSavingStatus] = useState(false);
  const [toast, setToast] = useState(null);
  const itemsPerPage = 10;

  const [showRegister, setShowRegister] = useState(false);
  const [registerForm, setRegisterForm] = useState(EMPTY_REGISTER_FORM);
  const [registerError, setRegisterError] = useState('');
  const [registering, setRegistering] = useState(false);

  const openRegister = () => {
    setRegisterForm(EMPTY_REGISTER_FORM);
    setRegisterError('');
    setShowRegister(true);
  };

  const handleRegisterTruck = async () => {
    if (!registerForm.brokerId) {
      setRegisterError('Select which broker this truck will belong to.');
      return;
    }
    if (!registerForm.registration.trim()) {
      setRegisterError('Registration number is required.');
      return;
    }
    if (!REGISTRATION_REGEX.test(registerForm.registration.trim())) {
      setRegisterError('Registration number looks invalid, e.g. MH-12-AB-1234.');
      return;
    }
    if (!registerForm.capacity.trim()) {
      setRegisterError('Capacity is required.');
      return;
    }
    setRegisterError('');
    setRegistering(true);
    try {
      const res = await api.post('/api/vehicles/trucks', {
        broker_id: registerForm.brokerId,
        registration: registerForm.registration.trim(),
        type: registerForm.category,
        category: registerForm.category,
        capacity: registerForm.capacity.trim(),
        make: registerForm.make.trim() || undefined,
        year: Number(registerForm.year) || undefined,
        insurance_expiry: registerForm.insuranceExpiry || undefined,
      }, getToken());
      if (!res.success) throw new Error(res.message || 'Failed to register truck');
      setToast({ message: `${registerForm.registration.trim()} registered successfully`, type: 'success' });
      setShowRegister(false);
      fetchTrucks();
    } catch (err) {
      setRegisterError(err.message || 'Failed to register truck.');
    } finally {
      setRegistering(false);
    }
  };

  const fetchTrucks = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const res = await api.get('/api/vehicles/trucks?limit=100', getToken());
      if (res.success) {
        setTrucks(res.data.trucks.map(mapTruck));
      } else {
        setError(res.message || 'Failed to load trucks');
      }
    } catch {
      setError('Network error — could not load trucks');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchTrucks(); }, [fetchTrucks]);

  const filtered = trucks.filter((t) =>
    !searchTerm ||
    t.regNo?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    t.type?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    t.broker?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    t.driver?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    t.id.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const totalPages = Math.ceil(filtered.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const paginated = filtered.slice(startIndex, startIndex + itemsPerPage);

  const openTruck = (truck) => {
    setSelectedTruck(truck);
    setStatusDraft(truck.status);
  };

  const handleUpdateStatus = async () => {
    if (!selectedTruck || statusDraft === selectedTruck.status) return;
    setSavingStatus(true);
    try {
      const res = await api.patch(`/api/vehicles/trucks/${selectedTruck.id}`, { status: statusDraft }, getToken());
      if (res.success) {
        const updated = mapTruck(res.data.truck);
        setTrucks((prev) => prev.map((t) => t.id === updated.id ? updated : t));
        setSelectedTruck(updated);
        setToast({ message: `${updated.regNo} status updated to ${updated.statusLabel}`, type: 'success' });
      } else {
        setToast({ message: res.message || 'Failed to update truck status', type: 'error' });
      }
    } catch {
      setToast({ message: 'Network error — could not update truck status', type: 'error' });
    } finally {
      setSavingStatus(false);
    }
  };

  return (
    <div className="space-y-4 animate-fade-in">
      <div className="flex items-start justify-between gap-3">
        <div>
          <h1 className="text-2xl font-poppins font-bold text-secondary">Trucks</h1>
          <p className="text-sm text-neutral-500 mt-1">Manage fleet and track truck availability</p>
        </div>
        <button onClick={openRegister} className="btn-primary flex-shrink-0"><Plus size={16} /> Register Truck</button>
      </div>

      <div className="card p-4">
        <div className="relative max-w-xs">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-neutral-400" />
          <input
            type="text"
            placeholder="Search trucks..."
            value={searchTerm}
            onChange={(e) => { setSearchTerm(e.target.value); setCurrentPage(1); }}
            className="form-input pl-9"
          />
        </div>
      </div>

      {error && (
        <div className="card p-4 text-sm text-danger flex items-center gap-2">
          <span>{error}</span>
          <button onClick={fetchTrucks} className="underline">Retry</button>
        </div>
      )}

      {loading ? (
        <div className="card p-10 flex justify-center">
          <div className="w-6 h-6 border-2 border-primary/20 border-t-primary rounded-full animate-spin" />
        </div>
      ) : (
      <div className="card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="data-table">
            <thead>
              <tr>
                <th>Truck ID</th>
                <th>Registration No.</th>
                <th>Type</th>
                <th>Make / Year</th>
                <th>Broker</th>
                <th>Driver Assigned</th>
                <th>Last Trip</th>
                <th>Insurance Expiry</th>
                <th>Capacity</th>
                <th>Status</th>
                <th className="text-center">Actions</th>
              </tr>
            </thead>
            <tbody>
              {paginated.length === 0 ? (
                <tr><td colSpan={11} className="text-center py-12 text-neutral-400">No data found.</td></tr>
              ) : paginated.map((truck) => (
                <tr key={truck.id}>
                  <td className="font-medium text-neutral-800">{shortId(truck.id)}</td>
                  <td className="font-medium whitespace-nowrap">{truck.regNo}</td>
                  <td>
                    <div className="flex items-center gap-2">
                      <div className="w-7 h-7 rounded-lg bg-neutral-50 border border-neutral-100 flex items-center justify-center flex-shrink-0 p-0.5">
                        {TRUCK_IMAGES[truck.category] ? (
                          <img src={TRUCK_IMAGES[truck.category]} alt={truck.category} className="w-full h-full object-contain" />
                        ) : (
                          <Truck size={13} className="text-neutral-300" />
                        )}
                      </div>
                      {truck.type}
                    </div>
                  </td>
                  <td className="whitespace-nowrap">{truck.make} <span className="text-neutral-400">· {truck.year}</span></td>
                  <td className="whitespace-nowrap">{truck.broker}</td>
                  <td>{truck.driver}</td>
                  <td className="whitespace-nowrap text-neutral-500">{truck.lastTrip}</td>
                  <td className={`whitespace-nowrap ${isInsuranceExpiring(truck.insuranceExpiry) ? 'text-danger font-semibold' : ''}`}>{formatDate(truck.insuranceExpiry)}</td>
                  <td>{truck.capacity}</td>
                  <td><Badge status={truck.statusLabel} /></td>
                  <td className="text-center">
                    <button onClick={() => openTruck(truck)} className="p-1.5 text-primary bg-primary/10 rounded-lg hover:bg-primary/20 transition-colors" title="View Details">
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
              <button onClick={() => setCurrentPage(p => Math.max(1, p - 1))} disabled={currentPage === 1} className="p-1.5 rounded-lg border border-neutral-200 hover:bg-neutral-50 disabled:opacity-40 transition-colors"><ChevronLeft size={16} /></button>
              {Array.from({ length: totalPages }, (_, i) => i + 1).map((page) => (
                <button key={page} onClick={() => setCurrentPage(page)} className={`w-8 h-8 rounded-lg text-sm font-medium transition-colors ${currentPage === page ? 'bg-primary text-white' : 'text-neutral-600 hover:bg-neutral-100'}`}>{page}</button>
              ))}
              <button onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))} disabled={currentPage === totalPages} className="p-1.5 rounded-lg border border-neutral-200 hover:bg-neutral-50 disabled:opacity-40 transition-colors"><ChevronRight size={16} /></button>
            </div>
          </div>
        )}
      </div>
      )}

      <Modal isOpen={!!selectedTruck} onClose={() => setSelectedTruck(null)} title="Truck Details" size="md">
        {selectedTruck && (
          <div className="space-y-4">
            <div className="flex items-center gap-4">
              <div className="w-14 h-14 bg-primary/10 rounded-xl flex items-center justify-center overflow-hidden flex-shrink-0">
                {TRUCK_IMAGES[selectedTruck.category] ? (
                  <img src={TRUCK_IMAGES[selectedTruck.category]} alt={selectedTruck.category} className="w-11 h-11 object-contain" />
                ) : (
                  <Truck size={24} className="text-primary" />
                )}
              </div>
              <div>
                <h3 className="text-lg font-semibold text-secondary">{selectedTruck.regNo}</h3>
                <Badge status={selectedTruck.statusLabel} />
              </div>
            </div>
            <div className="bg-neutral-50 rounded-lg p-4 space-y-3 text-sm">
              <div className="flex justify-between"><span className="text-neutral-500">Truck ID</span><span className="font-medium">{shortId(selectedTruck.id)}</span></div>
              <div className="flex justify-between"><span className="text-neutral-500">Registration Number</span><span className="font-medium">{selectedTruck.regNo}</span></div>
              <div className="flex justify-between"><span className="text-neutral-500">Type</span><span className="font-medium">{selectedTruck.type}</span></div>
              <div className="flex justify-between"><span className="text-neutral-500">Make</span><span className="font-medium">{selectedTruck.make}</span></div>
              <div className="flex justify-between"><span className="text-neutral-500">Year</span><span className="font-medium">{selectedTruck.year}</span></div>
              <div className="flex justify-between"><span className="text-neutral-500">Capacity</span><span className="font-medium">{selectedTruck.capacity}</span></div>
              <div className="flex justify-between"><span className="text-neutral-500">Broker</span><span className="font-medium">{selectedTruck.broker}</span></div>
              <div className="flex justify-between"><span className="text-neutral-500">Driver</span><span className="font-medium">{selectedTruck.driver}</span></div>
              <div className="flex justify-between"><span className="text-neutral-500">Last Trip</span><span className="font-medium">{selectedTruck.lastTrip}</span></div>
              <div className="flex justify-between">
                <span className="text-neutral-500">Insurance Expiry</span>
                <span className={`font-medium ${isInsuranceExpiring(selectedTruck.insuranceExpiry) ? 'text-danger' : ''}`}>{formatDate(selectedTruck.insuranceExpiry)}</span>
              </div>
            </div>

            <div>
              <label className="form-label">Update Status</label>
              <div className="flex items-center gap-2">
                <select value={statusDraft} onChange={(e) => setStatusDraft(e.target.value)} className="form-select">
                  {STATUS_OPTIONS.map((s) => <option key={s} value={s}>{STATUS_LABEL[s]}</option>)}
                </select>
                <button
                  onClick={handleUpdateStatus}
                  disabled={savingStatus || statusDraft === selectedTruck.status}
                  className="btn-primary whitespace-nowrap disabled:opacity-40"
                >
                  {savingStatus ? 'Saving...' : 'Update'}
                </button>
              </div>
            </div>

            <div className="flex justify-end gap-2">
              <button onClick={() => setSelectedTruck(null)} className="btn-secondary">Close</button>
            </div>
          </div>
        )}
      </Modal>

      <Modal isOpen={showRegister} onClose={() => setShowRegister(false)} title="Register Truck" size="lg">
        <div className="grid grid-cols-2 gap-3">
          <div className="col-span-2">
            <label className="form-label">Broker *</label>
            <BrokerPicker value={registerForm.brokerId} onChange={(id) => setRegisterForm((f) => ({ ...f, brokerId: id }))} />
            <p className="text-[11px] text-neutral-400 mt-1">The truck will be added to this broker's fleet.</p>
          </div>
          <div className="col-span-2">
            <label className="form-label">Registration Number</label>
            <input
              type="text"
              value={registerForm.registration}
              onChange={(event) => setRegisterForm((current) => ({ ...current, registration: event.target.value }))}
              className="form-input"
              placeholder="MH-12-AB-1234"
            />
          </div>
          <div>
            <label className="form-label">Truck Type</label>
            <select value={registerForm.category} onChange={(event) => setRegisterForm((current) => ({ ...current, category: event.target.value }))} className="form-select">
              {TRUCK_CATEGORIES.map((cat) => <option key={cat} value={cat}>{cat[0].toUpperCase() + cat.slice(1)}</option>)}
            </select>
          </div>
          {[
            ['capacity', 'Capacity'],
            ['make', 'Make / Model'],
            ['year', 'Year'],
            ['insuranceExpiry', 'Insurance Expiry'],
          ].map(([key, label]) => (
            <div key={key}>
              <label className="form-label">{label}</label>
              <input
                type={key === 'insuranceExpiry' ? 'date' : 'text'}
                value={registerForm[key]}
                onChange={(event) => setRegisterForm((current) => ({ ...current, [key]: event.target.value }))}
                className="form-input"
              />
            </div>
          ))}
          {registerError && <div className="col-span-2 text-sm text-danger bg-red-50 border border-red-100 rounded-lg px-3 py-2">{registerError}</div>}
          <div className="col-span-2 flex gap-3 pt-1">
            <button onClick={() => setShowRegister(false)} className="flex-1 btn-secondary">Cancel</button>
            <button onClick={handleRegisterTruck} disabled={registering} className="flex-1 btn-primary disabled:opacity-60">{registering ? 'Registering...' : 'Register Truck'}</button>
          </div>
        </div>
      </Modal>

      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
    </div>
  );
}
