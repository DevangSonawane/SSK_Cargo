import { useState, useEffect, useCallback, useMemo } from 'react';
import { Search, Eye, ChevronLeft, ChevronRight, Phone, Plus, Copy, CheckCircle2 } from 'lucide-react';
import Badge from '../components/Badge';
import Modal from '../components/Modal';
import Toast from '../components/Toast';
import BrokerPicker from '../components/BrokerPicker';
import { api, getToken } from '../services/api';

const EMPTY_REGISTER_FORM = { brokerId: '', name: '', phone: '', email: '', licenseNo: '', licenseExpiry: '', aadhaar: '', truckId: '' };

const formatAadhaar = (digits) => {
  const groups = [];
  for (let i = 0; i < digits.length; i += 4) groups.push(digits.slice(i, i + 4));
  return groups.map((g, i) => (i === groups.length - 1 ? g : 'X'.repeat(g.length))).join('-');
};

const STATUS_LABEL = { available: 'Available', on_trip: 'On Trip', offline: 'Offline' };
const KYC_LABEL = { pending: 'Pending', submitted: 'Pending', verified: 'Verified', rejected: 'Rejected' };

function isLicenseExpiring(dateStr) {
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

// GET /api/vehicles/drivers doesn't join a broker display name (only brokerId) —
// fall back to a shortened id so the column still shows something meaningful.
function shortId(id) {
  return id ? `#${id.slice(0, 8)}` : '—';
}

function mapDriver(d) {
  return {
    id: d.id,
    name: d.name,
    phone: d.phone,
    licenseNo: d.licenseNo || '—',
    licenseExpiry: d.licenseExpiry,
    aadhaar: d.aadhaar || '—',
    broker: d.broker || shortId(d.brokerId),
    truckReg: d.truckReg,
    truckId: d.truckId,
    totalTrips: d.totalTrips ?? 0,
    avatar: d.avatar,
    status: d.status,
    statusLabel: STATUS_LABEL[d.status] || d.status,
    kycStatus: d.kycStatus,
    kycStatusLabel: KYC_LABEL[d.kycStatus] || d.kycStatus,
  };
}

function DriverAvatar({ driver, size = 'w-10 h-10' }) {
  if (driver.avatar) {
    return <img src={driver.avatar} alt={driver.name} className={`${size} rounded-full object-cover`} />;
  }
  const initials = driver.name.split(' ').map((n) => n[0]).join('').toUpperCase().slice(0, 2);
  return (
    <div className={`${size} rounded-full bg-primary/10 flex items-center justify-center`}>
      <span className="text-primary font-semibold text-sm">{initials}</span>
    </div>
  );
}

export default function Drivers() {
  const [drivers, setDrivers] = useState([]);
  const [trucks, setTrucks] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [selectedDriver, setSelectedDriver] = useState(null);
  const itemsPerPage = 10;

  const [showRegister, setShowRegister] = useState(false);
  const [registerForm, setRegisterForm] = useState(EMPTY_REGISTER_FORM);
  const [aadhaarDigits, setAadhaarDigits] = useState('');
  const [registerErrors, setRegisterErrors] = useState({});
  const [registering, setRegistering] = useState(false);
  const [tempPasswordResult, setTempPasswordResult] = useState(null);
  const [toast, setToast] = useState(null);

  const fetchDrivers = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const [driversRes, trucksRes] = await Promise.all([
        api.get('/api/vehicles/drivers?limit=100', getToken()),
        api.get('/api/vehicles/trucks?limit=100', getToken()),
      ]);
      if (driversRes.success) {
        setDrivers(driversRes.data.drivers.map(mapDriver));
      } else {
        setError(driversRes.message || 'Failed to load drivers');
      }
      if (trucksRes.success) setTrucks(trucksRes.data.trucks || []);
    } catch {
      setError('Network error — could not load drivers');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchDrivers(); }, [fetchDrivers]);

  // Trucks belong to one broker — only offer trucks owned by whichever broker is selected,
  // and only ones not already assigned to another driver.
  const availableTrucksForBroker = useMemo(
    () => trucks.filter((t) => t.brokerId === registerForm.brokerId && !t.driverId),
    [trucks, registerForm.brokerId]
  );

  const openRegister = () => {
    setRegisterForm(EMPTY_REGISTER_FORM);
    setAadhaarDigits('');
    setRegisterErrors({});
    setTempPasswordResult(null);
    setShowRegister(true);
  };

  const validateRegister = () => {
    const next = {};
    if (!registerForm.brokerId) next.brokerId = 'Select which broker this driver will belong to.';
    if (!registerForm.name.trim()) next.name = 'Name is required.';
    if (registerForm.phone.replace(/\D/g, '').length !== 10) next.phone = 'Enter a valid 10-digit phone number.';
    if (!registerForm.email.trim() || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(registerForm.email.trim())) {
      next.email = 'Enter a valid email address — the driver logs in with email + password.';
    }
    if (registerForm.licenseExpiry) {
      const today = new Date(); today.setHours(0, 0, 0, 0);
      if (new Date(registerForm.licenseExpiry) < today) next.licenseExpiry = 'License expiry cannot be in the past.';
    }
    if (aadhaarDigits && aadhaarDigits.length !== 12) next.aadhaar = 'Aadhaar must be 12 digits.';
    setRegisterErrors(next);
    return Object.keys(next).length === 0;
  };

  const handleRegister = async () => {
    if (!validateRegister()) return;
    setRegistering(true);
    try {
      const res = await api.post('/api/vehicles/drivers/register', {
        broker_id: registerForm.brokerId,
        name: registerForm.name.trim(),
        phone: registerForm.phone.replace(/\D/g, ''),
        email: registerForm.email.trim(),
        license_no: registerForm.licenseNo.trim() || undefined,
        license_expiry: registerForm.licenseExpiry || undefined,
        aadhaar: aadhaarDigits.length === 12 ? aadhaarDigits : undefined,
        truck_id: registerForm.truckId || undefined,
      }, getToken());
      if (!res.success) throw new Error(res.message || 'Failed to register driver');
      setTempPasswordResult({ name: registerForm.name.trim(), email: registerForm.email.trim(), tempPassword: res.data.tempPassword });
      fetchDrivers();
    } catch (err) {
      setToast({ message: err.message || 'Failed to register driver', type: 'error' });
    } finally {
      setRegistering(false);
    }
  };

  const filtered = drivers.filter((d) =>
    !searchTerm ||
    d.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    d.phone?.includes(searchTerm) ||
    d.licenseNo?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    d.id.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const totalPages = Math.ceil(filtered.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const paginated = filtered.slice(startIndex, startIndex + itemsPerPage);

  return (
    <div className="space-y-4 animate-fade-in">
      <div className="flex items-start justify-between gap-3">
        <div>
          <h1 className="text-2xl font-poppins font-bold text-secondary">Drivers</h1>
          <p className="text-sm text-neutral-500 mt-1">Manage drivers and monitor their availability</p>
        </div>
        <button onClick={openRegister} className="btn-primary flex-shrink-0"><Plus size={16} /> Register Driver</button>
      </div>

      <div className="card p-4">
        <div className="relative max-w-xs">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-neutral-400" />
          <input
            type="text"
            placeholder="Search drivers..."
            value={searchTerm}
            onChange={(e) => { setSearchTerm(e.target.value); setCurrentPage(1); }}
            className="form-input pl-9"
          />
        </div>
      </div>

      {error && (
        <div className="card p-4 text-sm text-danger flex items-center gap-2">
          <span>{error}</span>
          <button onClick={fetchDrivers} className="underline">Retry</button>
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
                <th>Driver ID</th>
                <th>Name</th>
                <th>Phone</th>
                <th>License No. / Expiry</th>
                <th>Assigned Broker</th>
                <th>Truck</th>
                <th>KYC</th>
                <th>Status</th>
                <th className="text-right">Total Trips</th>
                <th className="text-center">Actions</th>
              </tr>
            </thead>
            <tbody>
              {paginated.length === 0 ? (
                <tr><td colSpan={10} className="text-center py-12 text-neutral-400">No data found.</td></tr>
              ) : paginated.map((driver) => (
                <tr key={driver.id}>
                  <td className="font-medium text-neutral-800">{shortId(driver.id)}</td>
                  <td className="font-medium">
                    <div className="flex items-center gap-2">
                      <DriverAvatar driver={driver} size="w-8 h-8" />
                      {driver.name}
                    </div>
                  </td>
                  <td className="whitespace-nowrap">
                    {driver.phone ? (
                      <a href={`tel:${driver.phone}`} onClick={(e) => e.stopPropagation()} className="flex items-center gap-1 text-primary hover:underline">
                        <Phone size={12} /> {driver.phone}
                      </a>
                    ) : '—'}
                  </td>
                  <td className="text-xs whitespace-nowrap">
                    <div>{driver.licenseNo}</div>
                    <div className={isLicenseExpiring(driver.licenseExpiry) ? 'text-danger font-semibold' : 'text-neutral-400'}>Exp: {formatDate(driver.licenseExpiry)}</div>
                  </td>
                  <td>{driver.broker}</td>
                  <td className="whitespace-nowrap">{driver.truckReg || '—'}</td>
                  <td><Badge status={driver.kycStatusLabel} /></td>
                  <td><Badge status={driver.statusLabel} /></td>
                  <td className="text-right font-medium">{driver.totalTrips}</td>
                  <td className="text-center">
                    <button onClick={() => setSelectedDriver(driver)} className="p-1.5 text-primary bg-primary/10 rounded-lg hover:bg-primary/20 transition-colors" title="View Details">
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

      <Modal isOpen={!!selectedDriver} onClose={() => setSelectedDriver(null)} title="Driver Details" size="md">
        {selectedDriver && (
          <div className="space-y-4">
            <div className="flex items-center gap-4">
              <DriverAvatar driver={selectedDriver} size="w-14 h-14" />
              <div>
                <h3 className="text-lg font-semibold text-secondary">{selectedDriver.name}</h3>
                <div className="flex items-center gap-1.5 mt-1">
                  <Badge status={selectedDriver.statusLabel} />
                  <Badge status={selectedDriver.kycStatusLabel} />
                </div>
              </div>
            </div>
            <div className="bg-neutral-50 rounded-lg p-4 space-y-3 text-sm">
              <div className="flex justify-between"><span className="text-neutral-500">Driver ID</span><span className="font-medium">{shortId(selectedDriver.id)}</span></div>
              <div className="flex justify-between"><span className="text-neutral-500">Phone</span>{selectedDriver.phone ? <a href={`tel:${selectedDriver.phone}`} className="font-medium text-primary hover:underline flex items-center gap-1"><Phone size={12} />{selectedDriver.phone}</a> : <span className="font-medium">—</span>}</div>
              <div className="flex justify-between"><span className="text-neutral-500">License Number</span><span className="font-medium">{selectedDriver.licenseNo}</span></div>
              <div className="flex justify-between">
                <span className="text-neutral-500">License Expiry</span>
                <span className={`font-medium ${isLicenseExpiring(selectedDriver.licenseExpiry) ? 'text-danger' : ''}`}>{formatDate(selectedDriver.licenseExpiry)}</span>
              </div>
              <div className="flex justify-between"><span className="text-neutral-500">Aadhaar</span><span className="font-medium">{selectedDriver.aadhaar}</span></div>
              <div className="flex justify-between"><span className="text-neutral-500">Assigned Broker</span><span className="font-medium">{selectedDriver.broker}</span></div>
              <div className="flex justify-between"><span className="text-neutral-500">Assigned Truck</span><span className="font-medium">{selectedDriver.truckReg || '—'}</span></div>
              <div className="flex justify-between"><span className="text-neutral-500">Total Trips</span><span className="font-medium">{selectedDriver.totalTrips}</span></div>
            </div>
            <div className="flex justify-end gap-2">
              <button onClick={() => setSelectedDriver(null)} className="btn-secondary">Close</button>
            </div>
          </div>
        )}
      </Modal>

      <Modal isOpen={showRegister} onClose={() => setShowRegister(false)} title="Register Driver" size="md">
        {tempPasswordResult ? (
          <div className="space-y-4">
            <div className="flex items-start gap-2 bg-emerald-50 border border-emerald-200 rounded-xl px-4 py-3 text-sm text-emerald-700">
              <CheckCircle2 size={16} className="flex-shrink-0 mt-0.5" />
              <span><b>{tempPasswordResult.name}</b> has been registered and added to the broker's fleet.</span>
            </div>
            <div className="bg-neutral-50 rounded-xl p-4 space-y-2">
              <p className="text-[11px] text-neutral-400 font-semibold uppercase">Share these login details with the driver</p>
              <div>
                <p className="text-[11px] text-neutral-400">Email</p>
                <p className="text-sm font-semibold text-neutral-800">{tempPasswordResult.email}</p>
              </div>
              <div className="flex items-center justify-between gap-3">
                <div>
                  <p className="text-[11px] text-neutral-400">Temporary Password</p>
                  <p className="text-sm font-mono font-semibold text-neutral-800">{tempPasswordResult.tempPassword}</p>
                </div>
                <button
                  onClick={() => { navigator.clipboard?.writeText(tempPasswordResult.tempPassword); setToast({ message: 'Password copied', type: 'success' }); }}
                  className="p-2 rounded-lg text-neutral-400 hover:text-primary hover:bg-primary/5 transition-all flex-shrink-0"
                >
                  <Copy size={14} />
                </button>
              </div>
              <p className="text-[11px] text-amber-600">This password is shown only once — the driver can change it from their profile after logging in.</p>
            </div>
            <button onClick={() => setShowRegister(false)} className="w-full btn-primary">Done</button>
          </div>
        ) : (
          <div className="space-y-4">
            <div>
              <label className="form-label">Broker *</label>
              <BrokerPicker value={registerForm.brokerId} onChange={(id) => setRegisterForm((f) => ({ ...f, brokerId: id }))} />
              {registerErrors.brokerId && <p className="text-xs text-danger mt-1">{registerErrors.brokerId}</p>}
              <p className="text-[11px] text-neutral-400 mt-1">The driver will be added to this broker's fleet.</p>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div className="col-span-2">
                <label className="form-label">Full Name *</label>
                <input value={registerForm.name} onChange={(e) => setRegisterForm((f) => ({ ...f, name: e.target.value }))} className="form-input" placeholder="Ramesh Kumar" />
                {registerErrors.name && <p className="text-xs text-danger mt-1">{registerErrors.name}</p>}
              </div>
              <div>
                <label className="form-label">Phone Number *</label>
                <input
                  value={registerForm.phone}
                  onChange={(e) => setRegisterForm((f) => ({ ...f, phone: e.target.value.replace(/\D/g, '').slice(0, 10) }))}
                  className="form-input font-mono"
                  placeholder="10-digit phone number"
                />
                {registerErrors.phone && <p className="text-xs text-danger mt-1">{registerErrors.phone}</p>}
              </div>
              <div>
                <label className="form-label">Email *</label>
                <input
                  type="email"
                  value={registerForm.email}
                  onChange={(e) => setRegisterForm((f) => ({ ...f, email: e.target.value }))}
                  className="form-input"
                  placeholder="driver@example.com"
                />
                {registerErrors.email && <p className="text-xs text-danger mt-1">{registerErrors.email}</p>}
              </div>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="form-label">License No.</label>
                <input value={registerForm.licenseNo} onChange={(e) => setRegisterForm((f) => ({ ...f, licenseNo: e.target.value }))} className="form-input" placeholder="MH-2020123456789" />
              </div>
              <div>
                <label className="form-label">License Expiry</label>
                <input type="date" value={registerForm.licenseExpiry} onChange={(e) => setRegisterForm((f) => ({ ...f, licenseExpiry: e.target.value }))} className="form-input" />
                {registerErrors.licenseExpiry && <p className="text-xs text-danger mt-1">{registerErrors.licenseExpiry}</p>}
              </div>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="form-label">Aadhaar</label>
                <input
                  value={formatAadhaar(aadhaarDigits)}
                  onChange={(e) => setAadhaarDigits(e.target.value.replace(/\D/g, '').slice(0, 12))}
                  className="form-input font-mono"
                  placeholder="XXXX-XXXX-1234"
                />
                {registerErrors.aadhaar && <p className="text-xs text-danger mt-1">{registerErrors.aadhaar}</p>}
              </div>
              <div>
                <label className="form-label">Assign Truck</label>
                <select
                  value={registerForm.truckId}
                  onChange={(e) => setRegisterForm((f) => ({ ...f, truckId: e.target.value }))}
                  className="form-select"
                  disabled={!registerForm.brokerId}
                >
                  <option value="">{registerForm.brokerId ? 'No truck yet' : 'Select a broker first'}</option>
                  {availableTrucksForBroker.map((truck) => (
                    <option key={truck.id} value={truck.id}>{truck.registration} · {truck.type || truck.category || ''}</option>
                  ))}
                </select>
              </div>
            </div>

            <div className="flex gap-3 pt-1">
              <button onClick={() => setShowRegister(false)} className="flex-1 btn-secondary">Cancel</button>
              <button onClick={handleRegister} disabled={registering} className="flex-1 btn-primary disabled:opacity-60">{registering ? 'Registering...' : 'Register Driver'}</button>
            </div>
          </div>
        )}
      </Modal>

      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
    </div>
  );
}
