// Background/killed-app push handler. Static file (not processed by Vite),
// so the Firebase config can't come from import.meta.env - it's passed in the
// registration URL's query string instead (see src/lib/firebase.js) and read
// back out below. These are client-safe config values, not secrets.
importScripts('https://www.gstatic.com/firebasejs/12.17.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/12.17.1/firebase-messaging-compat.js');

const params = new URLSearchParams(self.location.search);
firebase.initializeApp({
  apiKey: params.get('apiKey'),
  authDomain: params.get('authDomain'),
  projectId: params.get('projectId'),
  storageBucket: params.get('storageBucket'),
  messagingSenderId: params.get('messagingSenderId'),
  appId: params.get('appId'),
});

const messaging = firebase.messaging();

// The browser only auto-renders a tray notification for background push when
// the payload has no `data`-only shape; showing it ourselves here (instead of
// relying on that default) lets us attach `data` to the notification object,
// which notificationclick below needs for the deep link.
messaging.onBackgroundMessage((payload) => {
  const { notification = {}, data = {} } = payload;
  self.registration.showNotification(notification.title || 'GadiDost', {
    body: notification.body,
    icon: '/gadidost-logo.png',
    data,
  });
});

// Tap on the tray notification - deep-link using data.booking_id / data.type,
// focusing an existing tab if one's open instead of always opening a new one.
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const data = event.notification.data || {};
  const url = data.type === 'booking' && data.booking_id
    ? `/bookings?bookingId=${data.booking_id}`
    : '/';

  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientsArr) => {
      const existing = clientsArr.find((c) => 'focus' in c);
      if (existing) {
        if ('navigate' in existing) existing.navigate(url);
        return existing.focus();
      }
      return self.clients.openWindow(url);
    })
  );
});
