import { useState, useEffect, useCallback } from 'react';
import { Search, Eye, PauseCircle, PlayCircle, ChevronLeft, ChevronRight, Building2, Phone } from 'lucide-react';
import Badge from '../components/Badge';
import Modal from '../components/Modal';
import Toast from '../components/Toast';
import { api, getToken } from '../services/api';

const KYC_LABEL = { pending: 'Pending', submitted: 'Pending', verified: 'Verified', rejected: 'Rejected' };

// GET /api/admin/users?role=broker doesn't return a display id like "BRK-001" — shorten the uuid instead.
function shortId(id) {
  return id ? `#${id.slice(0, 8)}` : '—';
}

export default function Brokers() {
  const [brokers, setBrokers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [selectedBroker, setSelectedBroker] = useState(null);
  const [actionLoading, setActionLoading] = useState(null);
  const [toast, setToast] = useState(null);
  const itemsPerPage = 10;

  const fetchBrokers = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const [usersRes, trucksRes, settlementsRes] = await Promise.all([
        api.get('/api/admin/users?role=broker&limit=100', getToken()),
        api.get('/api/vehicles/trucks?limit=100', getToken()),
        api.get('/api/payments/settlements?limit=100', getToken()),
      ]);

      if (!usersRes.success) {
        setError(usersRes.message || 'Failed to load brokers');
        return;
      }

      const trucks = trucksRes.success ? trucksRes.data.trucks : [];
      const settlements = settlementsRes.success ? settlementsRes.data.settlements : [];

      const merged = usersRes.data.users.map((u) => {
        const ownTrucks = trucks.filter((t) => t.brokerId === u.id);
        // "Total Earnings" = realized (paid) settlements only, not pending payouts.
        const totalEarnings = settlements
          .filter((s) => s.brokerId === u.id && s.status === 'paid')
          .reduce((sum, s) => sum + (s.netEarnings || 0), 0);

        return {
          id: u.id,
          name: u.name,
          phone: u.phone,
          status: u.status,
          kycStatus: u.kyc_status,
          fleetSize: ownTrucks.length,
          activeTrucks: ownTrucks.filter((t) => t.status === 'on_trip').length,
          totalEarnings,
        };
      });

      setBrokers(merged);
    } catch {
      setError('Network error — could not load brokers');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchBrokers(); }, [fetchBrokers]);

  const filtered = brokers.filter((b) =>
    !searchTerm ||
    b.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    b.phone?.includes(searchTerm) ||
    b.id.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const totalPages = Math.ceil(filtered.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const paginated = filtered.slice(startIndex, startIndex + itemsPerPage);

  const handleToggleBlock = async (broker) => {
    const nextStatus = broker.status === 'blocked' ? 'active' : 'blocked';
    setActionLoading(broker.id);
    try {
      const res = await api.patch(`/api/admin/users/${broker.id}/status`, { status: nextStatus }, getToken());
      if (res.success) {
        setBrokers((prev) => prev.map((b) => b.id === broker.id ? { ...b, status: nextStatus } : b));
        setSelectedBroker((prev) => prev && prev.id === broker.id ? { ...prev, status: nextStatus } : prev);
        setToast({ message: `${broker.name} ${nextStatus === 'blocked' ? 'suspended' : 'reinstated'} successfully`, type: 'success' });
      } else {
        setToast({ message: res.message || 'Failed to update broker status', type: 'error' });
      }
    } catch {
      setToast({ message: 'Network error — could not update broker status', type: 'error' });
    } finally {
      setActionLoading(null);
    }
  };

  return (
    <div className="space-y-4 animate-fade-in">
      <div>
        <h1 className="text-2xl font-poppins font-bold text-secondary">Brokers</h1>
        <p className="text-sm text-neutral-500 mt-1">Manage registered brokers and their fleet</p>
      </div>

      <div className="card p-4">
        <div className="relative max-w-xs">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-neutral-400" />
          <input
            type="text"
            placeholder="Search brokers..."
            value={searchTerm}
            onChange={(e) => { setSearchTerm(e.target.value); setCurrentPage(1); }}
            className="form-input pl-9"
          />
        </div>
      </div>

      {error && (
        <div className="card p-4 text-sm text-danger flex items-center gap-2">
          <span>{error}</span>
          <button onClick={fetchBrokers} className="underline">Retry</button>
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
                <th>Broker ID</th>
                <th>Name</th>
                <th>Phone</th>
                <th className="text-right">Fleet Size</th>
                <th className="text-right">Active Trucks</th>
                <th className="text-right">Total Earnings</th>
                <th>KYC Status</th>
                <th>Status</th>
                <th className="text-center">Actions</th>
              </tr>
            </thead>
            <tbody>
              {paginated.length === 0 ? (
                <tr><td colSpan={9} className="text-center py-12 text-neutral-400">No data found.</td></tr>
              ) : paginated.map((broker) => (
                <tr key={broker.id}>
                  <td className="font-medium text-neutral-800">{shortId(broker.id)}</td>
                  <td className="font-medium">{broker.name}</td>
                  <td className="whitespace-nowrap">
                    {broker.phone ? (
                      <a href={`tel:${broker.phone}`} onClick={(e) => e.stopPropagation()} className="flex items-center gap-1 text-primary hover:underline">
                        <Phone size={12} /> {broker.phone}
                      </a>
                    ) : '—'}
                  </td>
                  <td className="text-right">{broker.fleetSize}</td>
                  <td className="text-right">{broker.activeTrucks}</td>
                  <td className="text-right font-medium">&#8377;{broker.totalEarnings.toLocaleString('en-IN')}</td>
                  <td><Badge status={KYC_LABEL[broker.kycStatus] || broker.kycStatus} /></td>
                  <td><Badge status={broker.status === 'blocked' ? 'Blocked' : 'Active'} /></td>
                  <td className="text-center">
                    <div className="flex items-center justify-center gap-1">
                      <button onClick={() => setSelectedBroker(broker)} className="p-1.5 text-primary bg-primary/10 rounded-lg hover:bg-primary/20 transition-colors" title="View Details">
                        <Eye size={14} />
                      </button>
                      <button
                        onClick={() => handleToggleBlock(broker)}
                        disabled={actionLoading === broker.id}
                        className="p-1.5 text-danger bg-red-50 rounded-lg hover:bg-red-100 transition-colors disabled:opacity-40"
                        title={broker.status === 'blocked' ? 'Reinstate Broker' : 'Suspend Broker'}
                      >
                        {broker.status === 'blocked' ? <PlayCircle size={14} /> : <PauseCircle size={14} />}
                      </button>
                    </div>
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

      <Modal isOpen={!!selectedBroker} onClose={() => setSelectedBroker(null)} title="Broker Details" size="md">
        {selectedBroker && (
          <div className="space-y-4">
            <div className="flex items-center gap-4">
              <div className="w-14 h-14 bg-primary/10 rounded-xl flex items-center justify-center">
                <Building2 size={24} className="text-primary" />
              </div>
              <div>
                <h3 className="text-lg font-semibold text-secondary">{selectedBroker.name}</h3>
                <div className="flex items-center gap-1.5 mt-1">
                  <Badge status={KYC_LABEL[selectedBroker.kycStatus] || selectedBroker.kycStatus} />
                  <Badge status={selectedBroker.status === 'blocked' ? 'Blocked' : 'Active'} />
                </div>
              </div>
            </div>
            <div className="bg-neutral-50 rounded-lg p-4 space-y-3 text-sm">
              <div className="flex justify-between"><span className="text-neutral-500">Broker ID</span><span className="font-medium">{shortId(selectedBroker.id)}</span></div>
              <div className="flex justify-between"><span className="text-neutral-500">Phone</span>{selectedBroker.phone ? <a href={`tel:${selectedBroker.phone}`} className="font-medium text-primary hover:underline flex items-center gap-1"><Phone size={12} />{selectedBroker.phone}</a> : <span className="font-medium">—</span>}</div>
              <div className="flex justify-between"><span className="text-neutral-500">Fleet Size</span><span className="font-medium">{selectedBroker.fleetSize} trucks</span></div>
              <div className="flex justify-between"><span className="text-neutral-500">Active Trucks</span><span className="font-medium">{selectedBroker.activeTrucks} trucks</span></div>
              <div className="flex justify-between"><span className="text-neutral-500">Total Earnings</span><span className="font-medium">&#8377;{selectedBroker.totalEarnings.toLocaleString('en-IN')}</span></div>
            </div>
            <div className="flex justify-end gap-2">
              <button
                onClick={() => handleToggleBlock(selectedBroker)}
                disabled={actionLoading === selectedBroker.id}
                className={selectedBroker.status === 'blocked' ? 'btn-success disabled:opacity-40' : 'btn-danger disabled:opacity-40'}
              >
                {selectedBroker.status === 'blocked' ? <><PlayCircle size={16} /> Reinstate</> : <><PauseCircle size={16} /> Suspend</>}
              </button>
              <button onClick={() => setSelectedBroker(null)} className="btn-secondary">Close</button>
            </div>
          </div>
        )}
      </Modal>

      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
    </div>
  );
}
