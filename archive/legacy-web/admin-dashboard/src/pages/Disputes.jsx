import { useEffect, useMemo, useState, useCallback } from "react";
import { Search, Eye, CheckCircle, ChevronLeft, ChevronRight, AlertTriangle, Phone } from "lucide-react";
import Badge from "../components/Badge";
import Modal from "../components/Modal";
import Toast from "../components/Toast";
import { api, getToken } from "../services/api";

const STATUS_LABELS = {
  open: "Open",
  under_review: "Under Review",
  resolved: "Resolved",
};

function shortId(id) {
  return id ? `#${id.slice(0, 8)}` : "—";
}

// Older disputes seeded before dispute_number existed fall back to a shortened UUID.
function disputeRef(dispute) {
  return dispute?.disputeNumber || shortId(dispute?.id);
}

function bookingRef(dispute) {
  return dispute?.bookingNumber || shortId(dispute?.bookingId);
}

export default function Disputes() {
  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState("All");
  const [currentPage, setCurrentPage] = useState(1);
  const [selectedDispute, setSelectedDispute] = useState(null);
  const [resolveModal, setResolveModal] = useState(null);
  const [resolutionNotes, setResolutionNotes] = useState("");
  const [toast, setToast] = useState(null);
  const [disputeData, setDisputeData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const itemsPerPage = 10;

  const fetchDisputes = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const response = await api.get("/api/disputes?limit=100", getToken());
      if (response.success) {
        setDisputeData(response.data?.disputes || []);
      } else {
        setError(response.message || "Failed to load disputes");
      }
    } catch {
      setError("Network error — could not load disputes");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchDisputes(); }, [fetchDisputes]);

  const filtered = useMemo(() => disputeData.filter((dispute) => {
    const uiStatus = STATUS_LABELS[dispute.status] || dispute.status;
    const matchStatus = statusFilter === "All" || uiStatus === statusFilter;
    const matchSearch = !searchTerm
      || dispute.id.toLowerCase().includes(searchTerm.toLowerCase())
      || String(dispute.disputeNumber || "").toLowerCase().includes(searchTerm.toLowerCase())
      || String(dispute.bookingId || "").toLowerCase().includes(searchTerm.toLowerCase())
      || String(dispute.bookingNumber || "").toLowerCase().includes(searchTerm.toLowerCase())
      || String(dispute.issueType || "").toLowerCase().includes(searchTerm.toLowerCase());
    return matchStatus && matchSearch;
  }), [disputeData, searchTerm, statusFilter]);

  const totalPages = Math.ceil(filtered.length / itemsPerPage) || 1;
  const startIndex = (currentPage - 1) * itemsPerPage;
  const paginated = filtered.slice(startIndex, startIndex + itemsPerPage);

  const handleResolve = async (disputeId) => {
    if (!resolutionNotes.trim()) return;
    try {
      await api.patch(`/api/disputes/${disputeId}/resolve`, { resolution: resolutionNotes }, getToken());
      setDisputeData((current) => current.map((dispute) => (
        dispute.id === disputeId
          ? { ...dispute, status: "resolved", resolution: resolutionNotes }
          : dispute
      )));
      setToast({ message: "Dispute resolved successfully", type: "success" });
      setResolveModal(null);
      setResolutionNotes("");
    } catch {
      setToast({ message: "Failed to resolve dispute", type: "error" });
    }
  };

  return (
    <div className="space-y-4 animate-fade-in">
      <div>
        <h1 className="text-2xl font-poppins font-bold text-secondary">Disputes</h1>
        <p className="text-sm text-neutral-500 mt-1">Manage and resolve booking disputes</p>
      </div>

      <div className="card p-4">
        <div className="flex flex-wrap gap-3 items-end">
          <div className="relative max-w-xs flex-1">
            <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-neutral-400" />
            <input
              type="text"
              placeholder="Search disputes..."
              value={searchTerm}
              onChange={(event) => { setSearchTerm(event.target.value); setCurrentPage(1); }}
              className="form-input pl-9"
            />
          </div>
          <div>
            <label className="form-label">Status</label>
            <select value={statusFilter} onChange={(event) => { setStatusFilter(event.target.value); setCurrentPage(1); }} className="form-select min-w-[140px]">
              <option value="All">All Statuses</option>
              <option value="Open">Open</option>
              <option value="Under Review">Under Review</option>
              <option value="Resolved">Resolved</option>
            </select>
          </div>
        </div>
      </div>

      {error && (
        <div className="card p-4 text-sm text-danger flex items-center gap-2">
          <span>{error}</span>
          <button onClick={fetchDisputes} className="underline">Retry</button>
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
                <th>Dispute ID</th>
                <th>Booking ID</th>
                <th>Raised By</th>
                <th>Issue Type</th>
                <th>Description</th>
                <th>Status</th>
                <th>Date</th>
                <th className="text-center">Actions</th>
              </tr>
            </thead>
            <tbody>
              {paginated.map((dispute) => (
                <tr key={dispute.id}>
                  <td className="font-medium text-neutral-800">{disputeRef(dispute)}</td>
                  <td>{bookingRef(dispute)}</td>
                  <td>{dispute.raisedByName || dispute.raisedBy}</td>
                  <td>{dispute.issueType}</td>
                  <td className="max-w-xs truncate">{dispute.description}</td>
                  <td><Badge status={STATUS_LABELS[dispute.status] || dispute.status} /></td>
                  <td>{new Date(dispute.date).toLocaleDateString("en-IN")}</td>
                  <td className="text-center">
                    <div className="flex items-center justify-center gap-1">
                      <button onClick={() => setSelectedDispute(dispute)} className="p-1.5 text-primary bg-primary/10 rounded-lg hover:bg-primary/20 transition-colors" title="View Details">
                        <Eye size={14} />
                      </button>
                      {dispute.status !== "resolved" && (
                        <button onClick={() => setResolveModal(dispute)} className="p-1.5 text-tertiary bg-green-50 rounded-lg hover:bg-green-100 transition-colors" title="Resolve">
                          <CheckCircle size={14} />
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
              {paginated.length === 0 && (
                <tr><td colSpan={8} className="text-center py-12 text-neutral-400">No disputes found.</td></tr>
              )}
            </tbody>
          </table>
        </div>

        {totalPages > 1 && (
          <div className="flex items-center justify-between px-4 py-3 border-t border-neutral-100">
            <p className="text-sm text-neutral-500">Showing {startIndex + 1} to {Math.min(startIndex + itemsPerPage, filtered.length)} of {filtered.length} entries</p>
            <div className="flex items-center gap-1">
              <button onClick={() => setCurrentPage((page) => Math.max(1, page - 1))} disabled={currentPage === 1} className="p-1.5 rounded-lg border border-neutral-200 hover:bg-neutral-50 disabled:opacity-40 transition-colors"><ChevronLeft size={16} /></button>
              {Array.from({ length: totalPages }, (_, index) => index + 1).map((page) => (
                <button key={page} onClick={() => setCurrentPage(page)} className={`w-8 h-8 rounded-lg text-sm font-medium transition-colors ${currentPage === page ? "bg-primary text-white" : "text-neutral-600 hover:bg-neutral-100"}`}>{page}</button>
              ))}
              <button onClick={() => setCurrentPage((page) => Math.min(totalPages, page + 1))} disabled={currentPage === totalPages} className="p-1.5 rounded-lg border border-neutral-200 hover:bg-neutral-50 disabled:opacity-40 transition-colors"><ChevronRight size={16} /></button>
            </div>
          </div>
        )}
      </div>
      )}

      <Modal isOpen={!!selectedDispute} onClose={() => setSelectedDispute(null)} title="Dispute Details" size="md">
        {selectedDispute && (
          <div className="space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-red-50 rounded-lg flex items-center justify-center">
                <AlertTriangle size={18} className="text-danger" />
              </div>
              <div>
                <h3 className="font-semibold text-secondary">{selectedDispute.issueType}</h3>
                <p className="text-xs text-neutral-500">{disputeRef(selectedDispute)} • {bookingRef(selectedDispute)}</p>
              </div>
            </div>
            <div className="bg-neutral-50 rounded-lg p-4 space-y-3 text-sm">
              <div><span className="text-neutral-500">Description</span><p className="mt-1 text-neutral-700">{selectedDispute.description}</p></div>
              <div className="flex justify-between">
                <span className="text-neutral-500">Raised By</span>
                <span className="font-medium flex items-center gap-1.5">
                  {selectedDispute.raisedByName || selectedDispute.raisedBy}
                  {selectedDispute.raisedByPhone && <a href={`tel:${selectedDispute.raisedByPhone}`} className="text-primary hover:underline flex items-center gap-1"><Phone size={12} />{selectedDispute.raisedByPhone}</a>}
                </span>
              </div>
              <div className="flex justify-between"><span className="text-neutral-500">Date</span><span className="font-medium">{new Date(selectedDispute.date).toLocaleString("en-IN")}</span></div>
              <div className="flex justify-between"><span className="text-neutral-500">Status</span><Badge status={STATUS_LABELS[selectedDispute.status] || selectedDispute.status} /></div>
              {selectedDispute.resolution && (
                <div><span className="text-neutral-500">Resolution</span><p className="mt-1 text-neutral-700">{selectedDispute.resolution}</p></div>
              )}
            </div>

            {/* Every party on the booking — not just whoever raised the dispute — so admin can
                call any of them without hopping over to Bookings/Drivers/Brokers mid-dispute. */}
            {(selectedDispute.clientPhone || selectedDispute.brokerPhone || selectedDispute.driverPhone) && (
              <div className="bg-neutral-50 rounded-lg p-4 space-y-2.5 text-sm">
                <h4 className="text-xs font-semibold text-neutral-500 uppercase tracking-wide">Booking Contacts</h4>
                {selectedDispute.clientPhone && (
                  <div className="flex justify-between"><span className="text-neutral-500">Client{selectedDispute.clientName ? ` (${selectedDispute.clientName})` : ""}</span><a href={`tel:${selectedDispute.clientPhone}`} className="font-medium text-primary hover:underline flex items-center gap-1"><Phone size={12} />{selectedDispute.clientPhone}</a></div>
                )}
                {selectedDispute.brokerPhone && (
                  <div className="flex justify-between"><span className="text-neutral-500">Broker{selectedDispute.brokerName ? ` (${selectedDispute.brokerName})` : ""}</span><a href={`tel:${selectedDispute.brokerPhone}`} className="font-medium text-primary hover:underline flex items-center gap-1"><Phone size={12} />{selectedDispute.brokerPhone}</a></div>
                )}
                {selectedDispute.driverPhone && (
                  <div className="flex justify-between"><span className="text-neutral-500">Driver{selectedDispute.driverName ? ` (${selectedDispute.driverName})` : ""}</span><a href={`tel:${selectedDispute.driverPhone}`} className="font-medium text-primary hover:underline flex items-center gap-1"><Phone size={12} />{selectedDispute.driverPhone}</a></div>
                )}
              </div>
            )}

            <div className="flex justify-end gap-2">
              <button onClick={() => setSelectedDispute(null)} className="btn-secondary">Close</button>
            </div>
          </div>
        )}
      </Modal>

      <Modal isOpen={!!resolveModal} onClose={() => { setResolveModal(null); setResolutionNotes(""); }} title="Resolve Dispute" size="md">
        {resolveModal && (
          <div className="space-y-4">
            <div className="bg-blue-50 border border-blue-100 rounded-lg p-3">
              <p className="text-sm text-blue-800"><strong>{resolveModal.issueType}</strong> - {bookingRef(resolveModal)}</p>
            </div>
            <div>
              <label className="form-label">Resolution Notes</label>
              <textarea
                value={resolutionNotes}
                onChange={(event) => setResolutionNotes(event.target.value)}
                placeholder="Enter resolution details..."
                rows={4}
                className="form-input resize-none"
              />
            </div>
            <div className="flex justify-end gap-2">
              <button onClick={() => { setResolveModal(null); setResolutionNotes(""); }} className="btn-secondary">Cancel</button>
              <button onClick={() => handleResolve(resolveModal.id)} disabled={!resolutionNotes.trim()} className="btn-primary">
                <CheckCircle size={16} /> Resolve
              </button>
            </div>
          </div>
        )}
      </Modal>

      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
    </div>
  );
}
