import { useCallback, useEffect, useMemo, useState } from 'react';
import { Search, Download, Eye, ChevronLeft, ChevronRight, Receipt } from 'lucide-react';
import Badge from '../components/Badge';
import { api, getToken } from '../services/api';

const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:5000';

function money(v) {
  return `₹${Number(v || 0).toLocaleString('en-IN')}`;
}

function shortId(id) {
  return id ? `#${id.slice(0, 8)}` : '—';
}

function bookingRef(booking) {
  return booking?.bookingNumber || shortId(booking?.id);
}

const PAYMENT_STATUS_LABEL = { paid: 'Paid', pending: 'Pending', refunded: 'Refunded' };

export default function Invoices() {
  const [bookings, setBookings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [busyId, setBusyId] = useState(null);
  const itemsPerPage = 10;

  const fetchBookings = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const res = await api.get('/api/bookings?limit=200', getToken());
      if (res.success) {
        setBookings(res.data?.bookings || []);
      } else {
        setError(res.message || 'Failed to load bookings');
      }
    } catch {
      setError('Network error — could not load bookings');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchBookings(); }, [fetchBookings]);
  useEffect(() => { setCurrentPage(1); }, [searchTerm]);

  const filtered = useMemo(() => bookings.filter((booking) => {
    if (!searchTerm) return true;
    const q = searchTerm.toLowerCase();
    return (
      String(booking.bookingNumber || '').toLowerCase().includes(q) ||
      String(booking.client || '').toLowerCase().includes(q) ||
      String(booking.broker || '').toLowerCase().includes(q) ||
      String(booking.driver?.name || '').toLowerCase().includes(q)
    );
  }), [bookings, searchTerm]);

  const totalPages = Math.ceil(filtered.length / itemsPerPage) || 1;
  const startIndex = (currentPage - 1) * itemsPerPage;
  const paginated = filtered.slice(startIndex, startIndex + itemsPerPage);

  const handleView = async (booking) => {
    setBusyId(`view-${booking.id}`);
    try {
      const blobUrl = await api.getFileBlobUrl(`${API_BASE}/api/bookings/${booking.id}/invoice`, getToken());
      window.open(blobUrl, '_blank');
    } catch {
      setError('Failed to load invoice for this booking.');
    } finally {
      setBusyId(null);
    }
  };

  const handleDownload = async (booking) => {
    setBusyId(`download-${booking.id}`);
    try {
      const blobUrl = await api.getFileBlobUrl(`${API_BASE}/api/bookings/${booking.id}/invoice`, getToken());
      const a = document.createElement('a');
      a.href = blobUrl;
      a.download = `invoice-${bookingRef(booking)}.pdf`;
      a.click();
      URL.revokeObjectURL(blobUrl);
    } catch {
      setError('Failed to download invoice for this booking.');
    } finally {
      setBusyId(null);
    }
  };

  return (
    <div className="space-y-4 animate-fade-in">
      <div>
        <h1 className="text-2xl font-poppins font-bold text-secondary">Invoices &amp; Receipts</h1>
        <p className="text-sm text-neutral-500 mt-1">View and download the generated invoice for any booking.</p>
      </div>

      <div className="card p-4">
        <div className="relative max-w-sm">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-neutral-400" />
          <input
            type="text"
            placeholder="Search by booking ID, client, broker, driver..."
            value={searchTerm}
            onChange={(event) => setSearchTerm(event.target.value)}
            className="form-input pl-9"
          />
        </div>
      </div>

      {error && (
        <div className="card p-4 text-sm text-danger flex items-center gap-2">
          <span>{error}</span>
          <button onClick={fetchBookings} className="underline">Retry</button>
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
                  <th>Booking ID</th>
                  <th>Client</th>
                  <th>Broker</th>
                  <th>Driver</th>
                  <th>Route</th>
                  <th className="text-right">Amount</th>
                  <th>Payment</th>
                  <th>Date</th>
                  <th className="text-center">Actions</th>
                </tr>
              </thead>
              <tbody>
                {paginated.map((booking) => (
                  <tr key={booking.id}>
                    <td className="font-medium text-neutral-800 whitespace-nowrap">{bookingRef(booking)}</td>
                    <td>{booking.client || '-'}</td>
                    <td className="whitespace-nowrap">{booking.broker || '-'}</td>
                    <td className="whitespace-nowrap">{booking.driver?.name || '-'}</td>
                    <td className="max-w-[220px] truncate" title={`${booking.pickup} → ${booking.drop}`}>{booking.pickup} → {booking.drop}</td>
                    <td className="text-right font-medium whitespace-nowrap">{money(booking.amount)}</td>
                    <td><Badge status={PAYMENT_STATUS_LABEL[booking.paymentStatus] || booking.paymentStatus} /></td>
                    <td className="whitespace-nowrap">{booking.createdAt ? new Date(booking.createdAt).toLocaleDateString('en-IN') : '-'}</td>
                    <td className="text-center whitespace-nowrap">
                      <button
                        onClick={() => handleView(booking)}
                        disabled={busyId === `view-${booking.id}`}
                        className="inline-flex items-center gap-1 px-2.5 py-1.5 text-xs font-medium text-primary bg-primary/10 rounded-lg hover:bg-primary/20 transition-colors disabled:opacity-50 mr-1.5"
                      >
                        <Eye size={13} /> View
                      </button>
                      <button
                        onClick={() => handleDownload(booking)}
                        disabled={busyId === `download-${booking.id}`}
                        className="inline-flex items-center gap-1 px-2.5 py-1.5 text-xs font-medium text-neutral-600 bg-neutral-100 rounded-lg hover:bg-neutral-200 transition-colors disabled:opacity-50"
                      >
                        <Download size={13} /> Download
                      </button>
                    </td>
                  </tr>
                ))}
                {paginated.length === 0 && (
                  <tr>
                    <td colSpan={9} className="text-center py-12 text-neutral-400">
                      <Receipt size={22} className="mx-auto mb-2 text-neutral-300" />
                      No bookings found matching your search.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>

          {totalPages > 1 && (
            <div className="flex items-center justify-between px-4 py-3 border-t border-neutral-100">
              <p className="text-sm text-neutral-500">Showing {startIndex + 1} to {Math.min(startIndex + itemsPerPage, filtered.length)} of {filtered.length} entries</p>
              <div className="flex items-center gap-1">
                <button onClick={() => setCurrentPage((page) => Math.max(1, page - 1))} disabled={currentPage === 1} className="p-1.5 rounded-lg border border-neutral-200 hover:bg-neutral-50 disabled:opacity-40 transition-colors"><ChevronLeft size={16} /></button>
                <button onClick={() => setCurrentPage((page) => Math.min(totalPages, page + 1))} disabled={currentPage === totalPages} className="p-1.5 rounded-lg border border-neutral-200 hover:bg-neutral-50 disabled:opacity-40 transition-colors"><ChevronRight size={16} /></button>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
