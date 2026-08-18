import { useState, useEffect, useCallback } from "react";
import {
  Save, Globe, Bell, Shield, User, Lock,
  Camera, Eye, EyeOff, Mail, Phone, IndianRupee, UserPlus,
} from "lucide-react";
import Toast from "../components/Toast";
import { api, getStoredAuth, getToken } from "../services/api";

const DEFAULT_SETTINGS = {
  platformName: "SSK Logistics",
  contactEmail: "",
  commissionRate: 10,
  emailAlerts: true,
  smsAlerts: true,
  pushNotifications: true,
};

const tabs = [
  { id: "profile", label: "My Profile", icon: User },
  { id: "platform", label: "Platform", icon: Globe },
  { id: "commission", label: "Commission", icon: IndianRupee },
  { id: "notifications", label: "Notifications", icon: Bell },
  { id: "security", label: "Security", icon: Shield },
  { id: "team", label: "Team", icon: UserPlus },
];

const EMPTY_NEW_ADMIN = { name: "", phone: "", email: "", password: "" };

function Toggle({ enabled, onChange, label, description }) {
  return (
    <div className="flex items-center justify-between py-3.5">
      <div className="flex-1 pr-6">
        <p className="text-sm font-semibold text-neutral-800">{label}</p>
        {description && <p className="text-xs text-neutral-400 mt-0.5 leading-relaxed">{description}</p>}
      </div>
      <button
        onClick={onChange}
        className={`relative w-11 h-6 rounded-full transition-colors duration-200 flex-shrink-0 focus:outline-none ${enabled ? "bg-primary" : "bg-neutral-200"}`}
      >
        <span className={`absolute top-0.5 w-5 h-5 bg-white rounded-full shadow-sm transition-transform duration-200 ${enabled ? "translate-x-[22px]" : "translate-x-0.5"}`} />
      </button>
    </div>
  );
}

function Field({ label, description, children }) {
  return (
    <div>
      <label className="form-label">{label}</label>
      {children}
      {description && <p className="text-xs text-neutral-400 mt-1">{description}</p>}
    </div>
  );
}

function PwField({ label, value, show, onToggleShow, onChange, placeholder }) {
  return (
    <div className="max-w-sm">
      <label className="form-label">{label}</label>
      <div className="relative">
        <Lock size={15} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-neutral-400" />
        <input
          type={show ? "text" : "password"}
          value={value}
          onChange={(event) => onChange(event.target.value)}
          placeholder={placeholder}
          className="form-input pl-10 pr-10"
        />
        <button
          type="button"
          onClick={onToggleShow}
          className="absolute right-3.5 top-1/2 -translate-y-1/2 text-neutral-400 hover:text-neutral-600 transition-colors"
        >
          {show ? <EyeOff size={15} /> : <Eye size={15} />}
        </button>
      </div>
    </div>
  );
}

export default function Settings() {
  const [activeTab, setActiveTab] = useState("profile");
  const [toast, setToast] = useState(null);
  const [saving, setSaving] = useState(false);
  const [profileLoading, setProfileLoading] = useState(true);
  const [settings, setSettings] = useState(DEFAULT_SETTINGS);
  const [profile, setProfile] = useState({
    name: "",
    email: "",
    phone: "",
    address: "",
    company_name: "",
    role: "Super Admin",
    joined: "",
  });
  const [passwords, setPasswords] = useState({ current: "", next: "", confirm: "" });
  const [showPw, setShowPw] = useState({ current: false, next: false, confirm: false });
  const [newAdmin, setNewAdmin] = useState(EMPTY_NEW_ADMIN);
  const [newAdminErrors, setNewAdminErrors] = useState({});
  const [showNewAdminPw, setShowNewAdminPw] = useState(false);
  const [creatingAdmin, setCreatingAdmin] = useState(false);

  const loadToken = useCallback(() => getToken(), []);

  useEffect(() => {
    const fetchData = async () => {
      const token = loadToken();
      if (!token) {
        setProfileLoading(false);
        return;
      }

      try {
        const [profileRes, settingsRes] = await Promise.all([
          api.get("/api/users/profile", token),
          api.get("/api/admin/settings", token),
        ]);

        const user = profileRes.data?.user || profileRes.data || {};
        setProfile({
          name: user.name || "",
          email: user.email || "",
          phone: user.phone ? `+91 ${user.phone}` : "",
          address: user.address || "",
          company_name: user.company_name || "",
          role: user.role === "admin" ? "Super Admin" : user.role || "Super Admin",
          joined: user.created_at
            ? new Date(user.created_at).toLocaleDateString("en-US", { month: "long", year: "numeric" })
            : "",
        });

        const remoteSettings = settingsRes.data || {};
        setSettings({
          platformName: remoteSettings.platformName || DEFAULT_SETTINGS.platformName,
          contactEmail: remoteSettings.contactEmail || DEFAULT_SETTINGS.contactEmail,
          commissionRate: Number(remoteSettings.commissionRate ?? DEFAULT_SETTINGS.commissionRate),
          emailAlerts: Boolean(remoteSettings.emailAlerts ?? DEFAULT_SETTINGS.emailAlerts),
          smsAlerts: Boolean(remoteSettings.smsAlerts ?? DEFAULT_SETTINGS.smsAlerts),
          pushNotifications: Boolean(remoteSettings.pushNotifications ?? DEFAULT_SETTINGS.pushNotifications),
        });
      } catch {
        setToast({ message: "Failed to load settings", type: "error" });
      } finally {
        setProfileLoading(false);
      }
    };

    fetchData();
  }, [loadToken]);

  const saveProfile = async () => {
    const token = loadToken();
    if (!token) return;

    setSaving(true);
    try {
      const data = await api.patch("/api/users/profile", {
        name: profile.name,
        email: profile.email,
        address: profile.address,
        company_name: profile.company_name,
      }, token);

      if (!data.success) {
        setToast({ message: data.message || "Failed to save profile", type: "error" });
        return;
      }

      const stored = getStoredAuth();
      if (stored) {
        stored.user = {
          ...stored.user,
          name: profile.name,
          email: profile.email,
          address: profile.address,
          company_name: profile.company_name,
        };
        localStorage.setItem("ssk_admin_auth", JSON.stringify(stored));
      }

      setToast({ message: "Profile saved successfully", type: "success" });
    } catch {
      setToast({ message: "Network error. Please try again.", type: "error" });
    } finally {
      setSaving(false);
    }
  };

  const saveSettings = async (sectionLabel) => {
    const token = loadToken();
    if (!token) return;

    setSaving(true);
    try {
      const data = await api.put("/api/admin/settings", {
        platform_name: settings.platformName,
        contact_email: settings.contactEmail,
        commission_rate: Number(settings.commissionRate || 0),
        email_alerts: settings.emailAlerts,
        sms_alerts: settings.smsAlerts,
        push_notifications: settings.pushNotifications,
      }, token);

      if (!data.success) {
        setToast({ message: data.message || `Failed to save ${sectionLabel}`, type: "error" });
        return;
      }

      setToast({ message: `${sectionLabel} saved successfully`, type: "success" });
    } catch {
      setToast({ message: "Network error. Please try again.", type: "error" });
    } finally {
      setSaving(false);
    }
  };

  const handlePasswordChange = async () => {
    if (!passwords.current || !passwords.next || !passwords.confirm) {
      setToast({ message: "Please fill all password fields", type: "error" });
      return;
    }
    if (passwords.next !== passwords.confirm) {
      setToast({ message: "New passwords do not match", type: "error" });
      return;
    }
    if (passwords.next.length < 6) {
      setToast({ message: "Password must be at least 6 characters", type: "error" });
      return;
    }

    const token = loadToken();
    if (!token) return;

    setSaving(true);
    try {
      const data = await api.patch("/api/users/change-password", {
        current_password: passwords.current,
        new_password: passwords.next,
      }, token);

      if (!data.success) {
        setToast({ message: data.message || "Failed to change password", type: "error" });
        return;
      }

      setPasswords({ current: "", next: "", confirm: "" });
      setToast({ message: "Password updated successfully", type: "success" });
    } catch {
      setToast({ message: "Network error. Please try again.", type: "error" });
    } finally {
      setSaving(false);
    }
  };

  const validateNewAdmin = () => {
    const next = {};
    if (!newAdmin.name.trim()) next.name = "Name is required.";
    if (!/^\d{10}$/.test(newAdmin.phone.replace(/\D/g, ""))) next.phone = "Enter a valid 10-digit phone number.";
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(newAdmin.email.trim())) next.email = "Enter a valid email address.";
    if (newAdmin.password.length < 8) next.password = "Password must be at least 8 characters.";
    setNewAdminErrors(next);
    return Object.keys(next).length === 0;
  };

  const handleCreateAdmin = async () => {
    if (!validateNewAdmin()) return;
    const token = loadToken();
    if (!token) return;

    setCreatingAdmin(true);
    try {
      const data = await api.post("/api/auth/admin/register", {
        name: newAdmin.name.trim(),
        phone: newAdmin.phone.replace(/\D/g, ""),
        email: newAdmin.email.trim(),
        password: newAdmin.password,
      }, token);

      if (!data.success) {
        setToast({ message: data.message || "Failed to create admin account", type: "error" });
        return;
      }

      setToast({ message: `Admin account created for ${newAdmin.name.trim()}`, type: "success" });
      setNewAdmin(EMPTY_NEW_ADMIN);
      setNewAdminErrors({});
    } catch {
      setToast({ message: "Network error. Please try again.", type: "error" });
    } finally {
      setCreatingAdmin(false);
    }
  };

  const initials = profile.name
    ? profile.name.split(" ").map((name) => name[0]).join("").toUpperCase().slice(0, 2)
    : "AU";

  return (
    <div className="space-y-5 animate-fade-in">
      <div>
        <h1 className="text-2xl font-poppins font-bold text-secondary">Settings</h1>
        <p className="text-sm text-neutral-500 mt-0.5">Manage your account, platform configuration, and preferences</p>
      </div>

      <div className="flex flex-col lg:flex-row gap-5 items-start">
        <div className="w-full lg:w-52 flex-shrink-0">
          <div className="card p-2">
            {tabs.map((tab) => {
              const Icon = tab.icon;
              const active = activeTab === tab.id;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all duration-150 text-left ${
                    active ? "bg-primary text-white shadow-sm" : "text-neutral-600 hover:bg-neutral-50 hover:text-neutral-900"
                  }`}
                >
                  <Icon size={16} className="flex-shrink-0" />
                  {tab.label}
                </button>
              );
            })}
          </div>
        </div>

        <div className="flex-1 min-w-0">
          {activeTab === "profile" && (
            <div className="card">
              <div className="card-header">
                <h3 className="card-title">My Profile</h3>
                <span className="text-xs font-semibold text-primary bg-primary/10 px-2.5 py-1 rounded-full">{profile.role}</span>
              </div>
              <div className="p-6 space-y-6">
                {profileLoading ? (
                  <div className="flex items-center justify-center py-12">
                    <div className="w-8 h-8 border-2 border-primary/20 border-t-primary rounded-full animate-spin" />
                  </div>
                ) : (
                  <>
                    <div className="flex items-center gap-5 p-4 bg-neutral-50 rounded-2xl">
                      <div className="relative flex-shrink-0">
                        <div className="w-20 h-20 bg-primary rounded-2xl flex items-center justify-center shadow-sm">
                          <span className="text-white font-poppins font-bold text-2xl">{initials}</span>
                        </div>
                        <button className="absolute -bottom-1 -right-1 w-7 h-7 bg-secondary rounded-lg flex items-center justify-center border-2 border-white hover:bg-secondary-light transition-colors">
                          <Camera size={12} className="text-white" />
                        </button>
                      </div>
                      <div>
                        <p className="font-poppins font-bold text-secondary text-lg leading-tight">{profile.name}</p>
                        <p className="text-sm text-neutral-500 mt-0.5">{profile.email}</p>
                        {profile.joined && (
                          <p className="text-xs text-neutral-400 mt-2 bg-white border border-neutral-200 rounded-lg px-2.5 py-1 inline-block">
                            Member since {profile.joined}
                          </p>
                        )}
                      </div>
                    </div>

                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                      <Field label="Full Name">
                        <input type="text" value={profile.name} onChange={(event) => setProfile((current) => ({ ...current, name: event.target.value }))} className="form-input" />
                      </Field>
                      <Field label="Role">
                        <input type="text" value={profile.role} readOnly className="form-input bg-neutral-50 text-neutral-400 cursor-not-allowed" />
                      </Field>
                      <Field label="Email Address">
                        <div className="relative">
                          <Mail size={15} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-neutral-400" />
                          <input type="email" value={profile.email} onChange={(event) => setProfile((current) => ({ ...current, email: event.target.value }))} className="form-input pl-10" />
                        </div>
                      </Field>
                      <Field label="Phone Number" description="Contact support to change phone number">
                        <div className="relative">
                          <Phone size={15} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-neutral-400" />
                          <input type="tel" value={profile.phone} readOnly className="form-input pl-10 bg-neutral-50 text-neutral-400 cursor-not-allowed" />
                        </div>
                      </Field>
                      <Field label="Company / Organization">
                        <input type="text" value={profile.company_name} onChange={(event) => setProfile((current) => ({ ...current, company_name: event.target.value }))} placeholder="SSK Logistics" className="form-input" />
                      </Field>
                      <Field label="Office Address">
                        <input type="text" value={profile.address} onChange={(event) => setProfile((current) => ({ ...current, address: event.target.value }))} placeholder="Head office address" className="form-input" />
                      </Field>
                    </div>

                    <div className="flex justify-end pt-2 border-t border-neutral-100">
                      <button onClick={saveProfile} disabled={saving} className="btn-primary">
                        {saving ? <><div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />Saving...</> : <><Save size={15} />Save Profile</>}
                      </button>
                    </div>
                  </>
                )}
              </div>
            </div>
          )}

          {activeTab === "platform" && (
            <div className="card">
              <div className="card-header">
                <h3 className="card-title">Platform Information</h3>
              </div>
              <div className="p-6 space-y-5">
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <Field label="Platform Name">
                    <input type="text" value={settings.platformName} onChange={(event) => setSettings((current) => ({ ...current, platformName: event.target.value }))} className="form-input" />
                  </Field>
                  <Field label="Contact Email">
                    <div className="relative">
                      <Mail size={15} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-neutral-400" />
                      <input type="email" value={settings.contactEmail} onChange={(event) => setSettings((current) => ({ ...current, contactEmail: event.target.value }))} className="form-input pl-10" />
                    </div>
                  </Field>
                </div>

                <Field label="Platform Logo">
                  <div className="flex items-center gap-4 mt-1.5">
                    <div className="w-16 h-16 rounded-2xl border-2 border-neutral-100 flex items-center justify-center overflow-hidden flex-shrink-0 bg-white">
                      <img src="/gadidost-logo.png" alt="Logo" className="w-full h-full object-contain p-1.5" />
                    </div>
                    <div>
                      <button className="btn-secondary text-xs">Upload New Logo</button>
                      <p className="text-xs text-neutral-400 mt-1.5">PNG or SVG · Max 2 MB · Recommended 256 × 256 px</p>
                    </div>
                  </div>
                </Field>

                <div className="flex justify-end pt-2 border-t border-neutral-100">
                  <button onClick={() => saveSettings("Platform settings")} className="btn-primary">
                    <Save size={15} /> Save Changes
                  </button>
                </div>
              </div>
            </div>
          )}

          {activeTab === "commission" && (
            <div className="card">
              <div className="card-header">
                <h3 className="card-title">Commission Settings</h3>
              </div>
              <div className="p-6 space-y-5">
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <Field label="Default Platform Fee (%)" description="Applied automatically to every booking">
                    <div className="relative">
                      <input type="number" min={0} max={50} value={settings.commissionRate} onChange={(event) => setSettings((current) => ({ ...current, commissionRate: parseFloat(event.target.value) || 0 }))} className="form-input pr-10" />
                      <span className="absolute right-3.5 top-1/2 -translate-y-1/2 text-neutral-400 text-sm font-semibold">%</span>
                    </div>
                  </Field>
                  <Field label="Minimum Fare (₹)" description="Bookings below this amount are not accepted">
                    <div className="relative">
                      <span className="absolute left-3.5 top-1/2 -translate-y-1/2 text-neutral-400 text-sm font-medium">₹</span>
                      <input type="number" defaultValue={500} min={0} className="form-input pl-8" />
                    </div>
                  </Field>
                </div>

                <div className="bg-primary/5 border border-primary/15 rounded-2xl p-4">
                  <p className="text-xs font-bold text-primary mb-1.5">How commission is calculated</p>
                  <p className="text-xs text-neutral-600 leading-relaxed">
                    Platform fee is deducted before the remaining amount is paid to the broker/driver.
                    At <span className="font-semibold">{settings.commissionRate}%</span>, a ₹10,000 booking yields{" "}
                    <span className="font-semibold text-tertiary">₹{(10000 * (1 - settings.commissionRate / 100)).toLocaleString("en-IN")}</span> to the driver.
                  </p>
                </div>

                <div className="flex justify-end pt-2 border-t border-neutral-100">
                  <button onClick={() => saveSettings("Commission settings")} className="btn-primary">
                    <Save size={15} /> Save Changes
                  </button>
                </div>
              </div>
            </div>
          )}

          {activeTab === "notifications" && (
            <div className="card">
              <div className="card-header">
                <h3 className="card-title">Notification Preferences</h3>
              </div>
              <div className="p-6">
                <div className="divide-y divide-neutral-100">
                  <Toggle enabled={settings.emailAlerts} onChange={() => setSettings((current) => ({ ...current, emailAlerts: !current.emailAlerts }))} label="Email Alerts" description="Booking confirmations, cancellations, and platform reports via email" />
                  <Toggle enabled={settings.smsAlerts} onChange={() => setSettings((current) => ({ ...current, smsAlerts: !current.smsAlerts }))} label="SMS Alerts" description="Critical alerts and OTPs sent to your registered mobile number" />
                  <Toggle enabled={settings.pushNotifications} onChange={() => setSettings((current) => ({ ...current, pushNotifications: !current.pushNotifications }))} label="Push Notifications" description="Real-time browser notifications for new bookings and open disputes" />
                  <Toggle enabled onChange={() => {}} label="Weekly Summary Report" description="Automated report delivered every Monday at 9 AM IST" />
                </div>
                <div className="flex justify-end pt-4 border-t border-neutral-100 mt-2">
                  <button onClick={() => saveSettings("Notification preferences")} className="btn-primary">
                    <Save size={15} /> Save Preferences
                  </button>
                </div>
              </div>
            </div>
          )}

          {activeTab === "security" && (
            <div className="space-y-5">
              <div className="card">
                <div className="card-header">
                  <h3 className="card-title">Change Password</h3>
                </div>
                <div className="p-6 space-y-4">
                  <PwField label="Current Password" value={passwords.current} show={showPw.current} onToggleShow={() => setShowPw((current) => ({ ...current, current: !current.current }))} onChange={(value) => setPasswords((current) => ({ ...current, current: value }))} placeholder="Enter your current password" />
                  <PwField label="New Password" value={passwords.next} show={showPw.next} onToggleShow={() => setShowPw((current) => ({ ...current, next: !current.next }))} onChange={(value) => setPasswords((current) => ({ ...current, next: value }))} placeholder="Minimum 6 characters" />
                  <PwField label="Confirm New Password" value={passwords.confirm} show={showPw.confirm} onToggleShow={() => setShowPw((current) => ({ ...current, confirm: !current.confirm }))} onChange={(value) => setPasswords((current) => ({ ...current, confirm: value }))} placeholder="Re-enter new password" />
                  <div className="flex justify-end pt-2 border-t border-neutral-100">
                    <button onClick={handlePasswordChange} disabled={saving} className="btn-primary">
                      {saving ? <><div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />Saving...</> : <><Shield size={15} /> Update Password</>}
                    </button>
                  </div>
                </div>
              </div>

              <div className="card">
                <div className="card-header">
                  <h3 className="card-title">Active Session</h3>
                </div>
                <div className="p-6">
                  <div className="flex items-center justify-between p-4 bg-tertiary/5 border border-tertiary/20 rounded-2xl">
                    <div className="flex items-center gap-3">
                      <div className="w-9 h-9 bg-tertiary/10 rounded-xl flex items-center justify-center">
                        <div className="w-2.5 h-2.5 bg-tertiary rounded-full animate-pulse" />
                      </div>
                      <div>
                        <p className="text-sm font-semibold text-neutral-800">Current device</p>
                        <p className="text-xs text-neutral-500 mt-0.5">Windows · Chrome · India</p>
                      </div>
                    </div>
                    <span className="text-xs font-bold text-tertiary bg-tertiary/10 px-3 py-1 rounded-full">
                      Active now
                    </span>
                  </div>
                  <p className="text-xs text-neutral-400 mt-3">Only one session is active at a time. Logging in from a new device will end this session.</p>
                </div>
              </div>
            </div>
          )}

          {activeTab === "team" && (
            <div className="card">
              <div className="card-header">
                <h3 className="card-title">Create Admin Account</h3>
              </div>
              <div className="p-6 space-y-5">
                <p className="text-xs text-neutral-500 -mt-1">
                  Admin accounts are created immediately active and verified — no OTP step. The new admin logs in with their email and the password set here.
                </p>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <Field label="Full Name">
                    <input type="text" value={newAdmin.name} onChange={(event) => setNewAdmin((current) => ({ ...current, name: event.target.value }))} placeholder="Jane Doe" className="form-input" />
                    {newAdminErrors.name && <p className="text-xs text-danger mt-1">{newAdminErrors.name}</p>}
                  </Field>
                  <Field label="Phone Number">
                    <div className="relative">
                      <Phone size={15} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-neutral-400" />
                      <input
                        type="tel"
                        value={newAdmin.phone}
                        onChange={(event) => setNewAdmin((current) => ({ ...current, phone: event.target.value.replace(/\D/g, "").slice(0, 10) }))}
                        placeholder="10-digit phone number"
                        className="form-input pl-10"
                      />
                    </div>
                    {newAdminErrors.phone && <p className="text-xs text-danger mt-1">{newAdminErrors.phone}</p>}
                  </Field>
                  <Field label="Email Address">
                    <div className="relative">
                      <Mail size={15} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-neutral-400" />
                      <input type="email" value={newAdmin.email} onChange={(event) => setNewAdmin((current) => ({ ...current, email: event.target.value }))} placeholder="admin@ssklogistics.in" className="form-input pl-10" />
                    </div>
                    {newAdminErrors.email && <p className="text-xs text-danger mt-1">{newAdminErrors.email}</p>}
                  </Field>
                  <Field label="Password">
                    <div className="relative">
                      <Lock size={15} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-neutral-400" />
                      <input
                        type={showNewAdminPw ? "text" : "password"}
                        value={newAdmin.password}
                        onChange={(event) => setNewAdmin((current) => ({ ...current, password: event.target.value }))}
                        placeholder="Minimum 8 characters"
                        className="form-input pl-10 pr-10"
                      />
                      <button type="button" onClick={() => setShowNewAdminPw((current) => !current)} className="absolute right-3.5 top-1/2 -translate-y-1/2 text-neutral-400 hover:text-neutral-600 transition-colors">
                        {showNewAdminPw ? <EyeOff size={15} /> : <Eye size={15} />}
                      </button>
                    </div>
                    {newAdminErrors.password && <p className="text-xs text-danger mt-1">{newAdminErrors.password}</p>}
                  </Field>
                </div>

                <div className="flex justify-end pt-2 border-t border-neutral-100">
                  <button onClick={handleCreateAdmin} disabled={creatingAdmin} className="btn-primary">
                    {creatingAdmin ? <><div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />Creating...</> : <><UserPlus size={15} />Create Admin</>}
                  </button>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
    </div>
  );
}
