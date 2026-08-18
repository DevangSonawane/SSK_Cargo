import { useEffect, useState } from "react";
import { Truck, Save, IndianRupee, Package, TrendingUp, Percent, Clock } from "lucide-react";
import Toast from "../components/Toast";
import { api, getToken } from "../services/api";

const CATEGORY_META = {
  small: { label: "Small Truck", color: "#1976FF", tint: "bg-[#1976FF]/10" },
  medium: { label: "Medium Truck", color: "#17D86B", tint: "bg-[#17D86B]/10" },
  large: { label: "Large Truck", color: "#F59E0B", tint: "bg-[#F59E0B]/10" },
};

const DEFAULT_CATEGORY = { baseFare: 0, perKmRate: 0, platformFee: 0, waitingCharge: 0, demandMultiplier: 1 };

const DEFAULT_CONFIG = {
  intraCity: { small: { ...DEFAULT_CATEGORY }, medium: { ...DEFAULT_CATEGORY }, large: { ...DEFAULT_CATEGORY } },
  interCity: { baseRatePerKm: 0, fuelSurcharge: 0, platformFee: 0, tollHandling: "actual", tollFixedAmount: 0 },
  partTruck: { platformFee: 0 },
};

function Spinner({ className = "w-4 h-4 border-2 border-white/30 border-t-white" }) {
  return <div className={`${className} rounded-full animate-spin`} />;
}

function NumberField({ label, value, onChange, prefix, suffix, min = 0 }) {
  return (
    <div>
      <label className="form-label">{label}</label>
      <div className="relative">
        {prefix && <span className="absolute left-3.5 top-1/2 -translate-y-1/2 text-neutral-400 text-sm font-medium">{prefix}</span>}
        <input
          type="number"
          min={min}
          value={value}
          onChange={(e) => onChange(parseFloat(e.target.value) || 0)}
          className={`form-input ${prefix ? "pl-8" : ""} ${suffix ? "pr-10" : ""}`}
        />
        {suffix && <span className="absolute right-3.5 top-1/2 -translate-y-1/2 text-neutral-400 text-sm font-medium">{suffix}</span>}
      </div>
    </div>
  );
}

function DemandSlider({ value, onChange, color }) {
  const pct = Math.max(0, Math.min(100, ((value - 1) / (3 - 1)) * 100));
  return (
    <div>
      <div className="flex items-center justify-between mb-2">
        <label className="form-label !mb-0">Demand Multiplier</label>
        <span
          className="text-xs font-bold px-2 py-0.5 rounded-full text-white"
          style={{ backgroundColor: color }}
        >
          {Number(value).toFixed(1)}x
        </span>
      </div>
      <div className="relative pt-1 pb-1">
        <div className="h-2 rounded-full bg-neutral-100 relative overflow-hidden">
          <div className="h-full rounded-full" style={{ width: `${pct}%`, backgroundColor: color }} />
        </div>
        <input
          type="range"
          min={1}
          max={3}
          step={0.1}
          value={value}
          onChange={(e) => onChange(parseFloat(e.target.value))}
          className="absolute inset-0 w-full h-4 top-0 opacity-0 cursor-pointer"
        />
        <div
          className="absolute top-1/2 w-4 h-4 rounded-full border-2 border-white shadow-md -translate-y-1/2 pointer-events-none"
          style={{ left: `calc(${pct}% - 8px)`, backgroundColor: color }}
        />
      </div>
      <div className="flex justify-between text-[10px] text-neutral-400 mt-1">
        <span>1.0x (off-peak)</span>
        <span>3.0x (peak surge)</span>
      </div>
    </div>
  );
}

function IntraCityCard({ category, data, onChange }) {
  const meta = CATEGORY_META[category];
  const set = (field) => (val) => onChange(category, { ...data, [field]: val });

  return (
    <div className="card overflow-hidden">
      <div className="flex items-center gap-3 px-5 py-4" style={{ backgroundColor: `${meta.color}14` }}>
        <div className="w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0" style={{ backgroundColor: meta.color }}>
          <Truck size={18} className="text-white" />
        </div>
        <h4 className="font-poppins font-semibold text-secondary text-sm">{meta.label}</h4>
      </div>
      <div className="p-5 space-y-4">
        <div className="grid grid-cols-2 gap-3">
          <NumberField label="Base Fare" prefix="₹" value={data.baseFare} onChange={set("baseFare")} />
          <NumberField label="Per KM Rate" prefix="₹" value={data.perKmRate} onChange={set("perKmRate")} />
        </div>
        <div className="grid grid-cols-2 gap-3">
          <NumberField label="Platform Fee" suffix="%" value={data.platformFee} onChange={set("platformFee")} />
          <NumberField label="Waiting/hr" prefix="₹" value={data.waitingCharge} onChange={set("waitingCharge")} />
        </div>
        <DemandSlider value={data.demandMultiplier} onChange={set("demandMultiplier")} color={meta.color} />
      </div>
    </div>
  );
}

function SectionShell({ icon: Icon, title, subtitle, children }) {
  return (
    <div className="card">
      <div className="card-header">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-xl bg-primary/10 flex items-center justify-center flex-shrink-0">
            <Icon size={17} className="text-primary" />
          </div>
          <div>
            <h3 className="card-title">{title}</h3>
            {subtitle && <p className="text-xs text-neutral-400 mt-0.5">{subtitle}</p>}
          </div>
        </div>
      </div>
      <div className="p-5">{children}</div>
    </div>
  );
}

export default function Pricing() {
  const [config, setConfig] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [savingSection, setSavingSection] = useState(null);
  const [toast, setToast] = useState(null);

  const fetchConfig = async () => {
    setLoading(true);
    setError("");
    try {
      const res = await api.get("/api/admin/pricing", getToken());
      if (res.success) {
        const remote = res.data?.config || res.data || {};
        setConfig({
          intraCity: {
            small: { ...DEFAULT_CATEGORY, ...(remote.intraCity?.small || {}) },
            medium: { ...DEFAULT_CATEGORY, ...(remote.intraCity?.medium || {}) },
            large: { ...DEFAULT_CATEGORY, ...(remote.intraCity?.large || {}) },
          },
          interCity: { ...DEFAULT_CONFIG.interCity, ...(remote.interCity || {}) },
          partTruck: { ...DEFAULT_CONFIG.partTruck, ...(remote.partTruck || {}) },
        });
      } else {
        setError(res.message || "Failed to load pricing configuration");
      }
    } catch {
      setError("Network error — could not load pricing configuration");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchConfig(); }, []);

  const save = async (sectionLabel) => {
    if (!config) return;
    setSavingSection(sectionLabel);
    try {
      const res = await api.put("/api/admin/pricing", config, getToken());
      if (res.success === false) {
        setToast({ message: res.message || "Failed to save pricing", type: "error" });
      } else {
        setToast({ message: "Pricing saved successfully", type: "success" });
      }
    } catch {
      setToast({ message: "Network error — could not save pricing", type: "error" });
    } finally {
      setSavingSection(null);
    }
  };

  const updateIntraCity = (category, next) => {
    setConfig((current) => ({
      ...current,
      intraCity: { ...current.intraCity, [category]: next },
    }));
  };

  const updateInterCity = (field, value) => {
    setConfig((current) => ({ ...current, interCity: { ...current.interCity, [field]: value } }));
  };

  const updatePartTruck = (field, value) => {
    setConfig((current) => ({ ...current, partTruck: { ...current.partTruck, [field]: value } }));
  };

  if (loading) {
    return (
      <div className="space-y-6 animate-fade-in">
        <div>
          <h1 className="text-2xl font-poppins font-bold text-secondary">Pricing Management</h1>
          <p className="text-sm text-neutral-500 mt-1">Configure pricing rules for different service types</p>
        </div>
        <div className="card p-10 flex justify-center">
          <div className="w-6 h-6 border-2 border-primary/20 border-t-primary rounded-full animate-spin" />
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="space-y-6 animate-fade-in">
        <div>
          <h1 className="text-2xl font-poppins font-bold text-secondary">Pricing Management</h1>
          <p className="text-sm text-neutral-500 mt-1">Configure pricing rules for different service types</p>
        </div>
        <div className="card p-4 text-sm text-danger flex items-center gap-2">
          <span>{error}</span>
          <button onClick={fetchConfig} className="underline">Retry</button>
        </div>
      </div>
    );
  }

  if (!config) return null;

  return (
    <div className="space-y-6 animate-fade-in">
      <div>
        <h1 className="text-2xl font-poppins font-bold text-secondary">Pricing Management</h1>
        <p className="text-sm text-neutral-500 mt-1">Configure pricing rules for different service types</p>
      </div>

      {/* Intra-City */}
      <SectionShell icon={IndianRupee} title="Intra-City Pricing" subtitle="Per truck-category fare rules for same-city bookings">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
          {["small", "medium", "large"].map((cat) => (
            <IntraCityCard key={cat} category={cat} data={config.intraCity[cat]} onChange={updateIntraCity} />
          ))}
        </div>
        <div className="flex justify-end pt-5 mt-5 border-t border-neutral-100">
          <button onClick={() => save("intraCity")} disabled={savingSection === "intraCity"} className="btn-primary">
            {savingSection === "intraCity" ? <><Spinner />Saving...</> : <><Save size={15} />Save Changes</>}
          </button>
        </div>
      </SectionShell>

      {/* Inter-City */}
      <SectionShell icon={TrendingUp} title="Inter-City Pricing" subtitle="Distance-based fare rules for cross-city bookings">
        <div className="space-y-6">
          <div>
            <p className="flex items-center gap-1.5 text-xs font-bold uppercase tracking-wide text-neutral-400 mb-3">
              <Percent size={12} /> Rate &amp; Fees
            </p>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <NumberField label="Base Rate / KM" prefix="₹" value={config.interCity.baseRatePerKm} onChange={(v) => updateInterCity("baseRatePerKm", v)} />
              <NumberField label="Fuel Surcharge" suffix="%" value={config.interCity.fuelSurcharge} onChange={(v) => updateInterCity("fuelSurcharge", v)} />
              <NumberField label="Platform Fee" suffix="%" value={config.interCity.platformFee} onChange={(v) => updateInterCity("platformFee", v)} />
            </div>
          </div>

          <div>
            <p className="flex items-center gap-1.5 text-xs font-bold uppercase tracking-wide text-neutral-400 mb-3">
              <Clock size={12} /> Toll Handling
            </p>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div>
                <label className="form-label">Toll Charging Method</label>
                <select
                  value={config.interCity.tollHandling}
                  onChange={(e) => updateInterCity("tollHandling", e.target.value)}
                  className="form-select"
                >
                  <option value="actual">Actual</option>
                  <option value="fixed">Fixed</option>
                </select>
              </div>
              {config.interCity.tollHandling === "fixed" && (
                <NumberField label="Fixed Toll Amount" prefix="₹" value={config.interCity.tollFixedAmount} onChange={(v) => updateInterCity("tollFixedAmount", v)} />
              )}
            </div>
          </div>
        </div>
        <div className="flex justify-end pt-5 mt-5 border-t border-neutral-100">
          <button onClick={() => save("interCity")} disabled={savingSection === "interCity"} className="btn-primary">
            {savingSection === "interCity" ? <><Spinner />Saving...</> : <><Save size={15} />Save Changes</>}
          </button>
        </div>
      </SectionShell>

      {/* Part Truck */}
      <SectionShell icon={Package} title="Part Truck Pricing" subtitle="Shared-load bookings billed by capacity used">
        <div className="space-y-5">
          <div className="border border-neutral-200 rounded-xl p-4">
            <p className="text-sm font-medium text-neutral-700 mb-1">Pricing Formula</p>
            <p className="text-sm font-mono font-semibold text-primary">Cost = Total Truck Cost x Capacity Used %</p>
          </div>
          <div className="max-w-xs">
            <NumberField label="Platform Fee" suffix="%" value={config.partTruck.platformFee} onChange={(v) => updatePartTruck("platformFee", v)} />
          </div>
        </div>
        <div className="flex justify-end pt-5 mt-5 border-t border-neutral-100">
          <button onClick={() => save("partTruck")} disabled={savingSection === "partTruck"} className="btn-primary">
            {savingSection === "partTruck" ? <><Spinner />Saving...</> : <><Save size={15} />Save Changes</>}
          </button>
        </div>
      </SectionShell>

      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
    </div>
  );
}
