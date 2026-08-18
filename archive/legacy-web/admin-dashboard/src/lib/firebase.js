import { initializeApp } from 'firebase/app';
import { getMessaging, getToken as getFcmToken, isSupported, onMessage } from 'firebase/messaging';

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
};

const VAPID_KEY = import.meta.env.VITE_FIREBASE_VAPID_KEY;

let messagingPromise = null;

// firebase-messaging-sw.js (public/) is a static file Vite doesn't process, so
// it can't read import.meta.env - the config is passed to it via the query
// string at registration time instead (parsed back out in the SW itself).
function backgroundServiceWorkerUrl() {
  return `/firebase-messaging-sw.js?${new URLSearchParams(firebaseConfig).toString()}`;
}

// Push isn't supported in every browser (e.g. Safari < 16, in-app webviews) -
// isSupported() is the SDK's own check. Memoized since it's used by both
// requestFcmToken and onForegroundMessage and the app calls both on login.
function getFirebaseMessaging() {
  if (!messagingPromise) {
    messagingPromise = isSupported().then((supported) => {
      if (!supported) return null;
      return getMessaging(initializeApp(firebaseConfig));
    });
  }
  return messagingPromise;
}

// Call right after login, and again whenever a fresh token is needed (there's
// no onTokenRefresh listener on the web SDK the way there is on
// Android/iOS - getToken() always returns the current valid registration
// token, so re-requesting it on each login/session-start is the web
// equivalent of handling rotation). Returns null if push isn't
// supported or the user denies the permission prompt.
export async function requestFcmToken() {
  const messaging = await getFirebaseMessaging();
  if (!messaging) return null;

  const permission = await Notification.requestPermission();
  if (permission !== 'granted') return null;

  const registration = await navigator.serviceWorker.register(backgroundServiceWorkerUrl());
  return getFcmToken(messaging, { vapidKey: VAPID_KEY, serviceWorkerRegistration: registration });
}

// Foreground push only (app open + tab focused). Background/killed-app push
// is handled entirely by the OS + public/firebase-messaging-sw.js.
// Returns an unsubscribe function (or a no-op if push isn't supported).
export async function onForegroundMessage(callback) {
  const messaging = await getFirebaseMessaging();
  if (!messaging) return () => {};
  return onMessage(messaging, callback);
}
