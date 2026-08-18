const BASE = import.meta.env.VITE_API_URL || 'http://localhost:5000';

const request = async (method, path, body, token) => {
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token && { Authorization: `Bearer ${token}` }),
    },
    ...(body && { body: JSON.stringify(body) }),
  });
  return res.json();
};

// Fetches a protected file (e.g. a KYC document) as a blob. Plain <a href> tags can't
// carry the Authorization header, so the file-serving endpoint would 401 without this —
// fetch it here instead and hand back an object URL the browser can open/render.
const getFileBlobUrl = async (url, token) => {
  const res = await fetch(url, { headers: { ...(token && { Authorization: `Bearer ${token}` }) } });
  if (!res.ok) throw new Error(`Failed to load document (${res.status})`);
  const blob = await res.blob();
  return URL.createObjectURL(blob);
};

export const api = {
  post:   (path, body, token) => request('POST',   path, body, token),
  get:    (path, token)       => request('GET',    path, null, token),
  put:    (path, body, token) => request('PUT',    path, body, token),
  patch:  (path, body, token) => request('PATCH',  path, body, token),
  delete: (path, token, body) => request('DELETE', path, body, token),
  getFileBlobUrl,
};

export const getStoredAuth = () => {
  try { return JSON.parse(localStorage.getItem('ssk_admin_auth')); } catch { return null; }
};

export const getToken = () => getStoredAuth()?.tokens?.access_token || null;
