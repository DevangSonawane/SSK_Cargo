import { useEffect, useMemo, useState, useCallback } from "react";
import { Search, Eye, CheckCircle, ChevronLeft, ChevronRight, AlertTriangle, Wrench, Phone } from "lucide-react";
import Badge from "../components/Badge";
import Modal from "../components/Modal";
import Toast from "../components/Toast";
import { api, getToken } from "../services/api";

const REASON_LABELS = {
  accident: "Accident",
  breakdown: "Breakdown",
  traffic_block: "Traffic Block",
  medical: "Medical",
  other: "Other",
};

const STATUS_LABELS = {
  reported: "Reported",
  acknowledged: "Acknowledged",
  resolved: "Resolved",
};

const MECHANIC_STATUS_LABELS = {
  requested: "Mechanic Requested",
  mechanic_assigned: "Mechanic Assigned",
  in_progress: "Mechanic In Progress",
  resolved: "Resolved",
};

function shortId(id) {
  return id ? `#${id.slice(0, 8)}` : "—";
}

function bookingRef(incident) {
  return incident?.bookingNumber || shortId(incident?.bookingId);
}

export default function Incidents() {
  const [searchTerm, setSearchTerm] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const [selectedIncident, setSelectedIncident] = useState(null);
  const [resolveModal, setResolveModal] = useState(null);
  const [resolutionNotes, setResolutionNotes] = useState("");
  const [toast, setToast] = useState(null);
  const [incidentData, setIncidentData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const itemsPerPage = 10;

  const fetchIncidents = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const response = await api.get("/api/admin/incidents?limit=100", getToken());
      if (response.success) {
        setIncidentData(response.data?.incidents || []);
      } else {
        setError(response.message || "Failed to load incidents");
      }
    } catch {
      setError("Network error — could not load incidents");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchIncidents(); }, [fetchIncidents]);

  const filtered = useMemo(() => incidentData.filter((incident) => (
    !searchTerm
    || String(incident.bookingNumber || "").toLowerCase().includes(searchTerm.toLowerCase())
    || String(incident.driverName || "").toLowerCase().includes(searchTerm.toLowerCase())
    || String(incident.brokerName || "").toLowerCase().includes(searchTerm.toLowerCase())
    || String(incident.reason || "").toLowerCase().includes(searchTerm.toLowerCase())
  )), [incidentData, searchTerm]);

  const totalPages = Math.ceil(filtered.length / itemsPerPage) || 1;
  const startIndex = (currentPage - 1) * itemsPerPage;
  const paginated = filtered.slice(startIndex, startIndex + itemsPerPage);

  const handleResolve = async (incident) => {
    if (!resolutionNotes.trim()) return;
    try {
      const response = await api.patch(`/api/trips/${incident.tripId}/incidents/${incident.id}/resolve`, { resolution: resolutionNotes }, getToken());
      if (!response.success) throw new Error(response.message || "Failed to resolve incident");
      setIncidentData((current) => current.filter((item) => item.id !== incident.id));
      setToast({ message: "Incident resolved successfully", type: "success" });
      setResolveModal(null);
      setResolutionNotes("");
    } catch (err) {
      setToast({ message: err.message || "Failed to resolve incident", type: "error" });
    }
  };

  return (
    <div className="space-y-4 animate-fade-in">
      <div>
        <h1 className="text-2xl font-poppins font-bold text-secondary">Incidents</h1>
        <p className="text-sm text-neutral-500 mt-1">Open trip incidents reported by drivers, platform-wide</p>
      </div>

      <div className="card p-4">
        <div className="relative max-w-xs">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-neutral-400" />
          <input
            type="text"
            placeholder="Search by booking, driver, broker, reason..."
            value={searchTerm}
            onChange={(event) => { setSearchTerm(event.target.value); setCurrentPage(1); }}
            className="form-input pl-9"
          />
        </div>
      </div>

      {error && (
        <div className="card p-4 text-sm text-danger flex items-center gap-2">
          <span>{error}</span>
          <button onClick={fetchIncidents} className="underline">Retry</button>
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
                <th>Booking</th>
                <th>Reason</th>
                <th>Notes</th>
                <th>Driver</th>
                <th>Broker</th>
                <th>Reported</th>
                <th>Status</th>
                <th className="text-center">Actions</th>
              </tr>
            </thead>
            <tbody>
              {paginated.map((incident) => (
                <tr key={incident.id}>
                  <td className="font-medium text-neutral-800">{bookingRef(incident)}</td>
                  <td>
                    {REASON_LABELS[incident.reason] || incident.reason}
                    {incident.mechanicRequest && (
                      <div className="flex items-center gap-1 text-[11px] text-amber-600 mt-0.5">
                        <Wrench size={11} /> {MECHANIC_STATUS_LABELS[incident.mechanicRequest.status] || incident.mechanicRequest.status}
                      </div>
                    )}
                  </td>
                  <td className="max-w-xs truncate">{incident.notes || "—"}</td>
                  <td>{incident.driverName || "—"}</td>
                  <td>{incident.brokerName || "—"}</td>
                  <td>{new Date(incident.reportedAt).toLocaleString("en-IN")}</td>
                  <td><Badge status={STATUS_LABELS[incident.status] || incident.status} /></td>
                  <td className="text-center">
                    <div className="flex items-center justify-center gap-1">
                      <button onClick={() => setSelectedIncident(incident)} className="p-1.5 text-primary bg-primary/10 rounded-lg hover:bg-primary/20 transition-colors" title="View Details">
                        <Eye size={14} />
                      </button>
                      <button onClick={() => setResolveModal(incident)} className="p-1.5 text-tertiary bg-green-50 rounded-lg hover:bg-green-100 transition-colors" title="Resolve">
                        <CheckCircle size={14} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
              {paginated.length === 0 && (
                <tr><td colSpan={8} className="text-center py-12 text-neutral-400">No open incidents. Everything's running smoothly.</td></tr>
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

      <Modal isOpen={!!selectedIncident} onClose={() => setSelectedIncident(null)} title="Incident Details" size="md">
        {selectedIncident && (
          <div className="space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-red-50 rounded-lg flex items-center justify-center">
                <AlertTriangle size={18} className="text-danger" />
              </div>
              <div>
                <h3 className="font-semibold text-secondary">{REASON_LABELS[selectedIncident.reason] || selectedIncident.reason}</h3>
                <p className="text-xs text-neutral-500">{bookingRef(selectedIncident)}</p>
              </div>
            </div>
            <div className="bg-neutral-50 rounded-lg p-4 space-y-3 text-sm">
              <div><span className="text-neutral-500">Notes</span><p className="mt-1 text-neutral-700">{selectedIncident.notes || "No additional notes provided."}</p></div>
              <div className="flex justify-between"><span className="text-neutral-500">Driver</span><span className="font-medium">{selectedIncident.driverName || "—"}{selectedIncident.driverPhone && <a href={`tel:${selectedIncident.driverPhone}`} className="ml-2 text-primary hover:underline">{selectedIncident.driverPhone}</a>}</span></div>
              <div className="flex justify-between"><span className="text-neutral-500">Broker</span><span className="font-medium">{selectedIncident.brokerName || "—"}{selectedIncident.brokerPhone && <a href={`tel:${selectedIncident.brokerPhone}`} className="ml-2 text-primary hover:underline">{selectedIncident.brokerPhone}</a>}</span></div>
              <div className="flex justify-between"><span className="text-neutral-500">Reported At</span><span className="font-medium">{new Date(selectedIncident.reportedAt).toLocaleString("en-IN")}</span></div>
              <div className="flex justify-between"><span className="text-neutral-500">Status</span><Badge status={STATUS_LABELS[selectedIncident.status] || selectedIncident.status} /></div>
            </div>

            {selectedIncident.mechanicRequest && (
              <div className="bg-amber-50 border border-amber-100 rounded-lg p-4 space-y-3 text-sm">
                <div className="flex items-center gap-2">
                  <Wrench size={15} className="text-amber-600" />
                  <h4 className="font-semibold text-amber-800">Mechanic Dispatch</h4>
                </div>
                <div className="flex justify-between"><span className="text-neutral-500">Status</span><span className="font-medium text-amber-700">{MECHANIC_STATUS_LABELS[selectedIncident.mechanicRequest.status] || selectedIncident.mechanicRequest.status}</span></div>
                <div className="flex justify-between"><span className="text-neutral-500">Mechanic</span><span className="font-medium">{selectedIncident.mechanicRequest.mechanicName || "Not yet arranged"}</span></div>
                {selectedIncident.mechanicRequest.mechanicPhone && (
                  <div className="flex justify-between">
                    <span className="text-neutral-500">Phone</span>
                    <a href={`tel:${selectedIncident.mechanicRequest.mechanicPhone}`} className="font-medium text-primary hover:underline flex items-center gap-1"><Phone size={12} />{selectedIncident.mechanicRequest.mechanicPhone}</a>
                  </div>
                )}
                {selectedIncident.mechanicRequest.notes && (
                  <div><span className="text-neutral-500">Dispatch Notes</span><p className="mt-1 text-neutral-700">{selectedIncident.mechanicRequest.notes}</p></div>
                )}
              </div>
            )}

            <div className="flex justify-end gap-2">
              <button onClick={() => setSelectedIncident(null)} className="btn-secondary">Close</button>
            </div>
          </div>
        )}
      </Modal>

      <Modal isOpen={!!resolveModal} onClose={() => { setResolveModal(null); setResolutionNotes(""); }} title="Resolve Incident" size="md">
        {resolveModal && (
          <div className="space-y-4">
            <div className="bg-blue-50 border border-blue-100 rounded-lg p-3">
              <p className="text-sm text-blue-800"><strong>{REASON_LABELS[resolveModal.reason] || resolveModal.reason}</strong> - {bookingRef(resolveModal)}</p>
            </div>
            <div>
              <label className="form-label">Resolution Notes</label>
              <textarea
                value={resolutionNotes}
                onChange={(event) => setResolutionNotes(event.target.value)}
                placeholder="How was this resolved?"
                rows={4}
                className="form-input resize-none"
              />
            </div>
            <div className="flex justify-end gap-2">
              <button onClick={() => { setResolveModal(null); setResolutionNotes(""); }} className="btn-secondary">Cancel</button>
              <button onClick={() => handleResolve(resolveModal)} disabled={!resolutionNotes.trim()} className="btn-primary">
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
