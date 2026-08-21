// 🔧 YOUR_* değerlerini Firebase Console → Project Settings → Web app'ten al
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyBE1A1VkNdylEMClP5KlIlu-vdPRTt_a24",
  authDomain: "asker-nobet-sistemi.firebaseapp.com",
  projectId: "asker-nobet-sistemi",
  storageBucket: "asker-nobet-sistemi.firebasestorage.app",
  messagingSenderId: "897670122048",
  appId: "1:897670122048:web:bd5ad001f64c15a2a92da5",
  measurementId: "G-1WKBK58BGP"
});

const messaging = firebase.messaging();

const titleFor = (type) => {
  switch (type) {
    case 'leave_approved':   return 'İzin Onaylandı';
    case 'leave_rejected':   return 'İzin Reddedildi';
    case 'swap_request':     return 'Nöbet Değişim Talebi';
    case 'swap_approved':    return 'Değişim Onaylandı';
    case 'swap_rejected':    return 'Değişim Reddedildi';
    case 'duty_reminder':    return 'Nöbet Hatırlatması';
    case 'duty_today':       return 'Bugün Nöbetsiniz';
    default:                 return 'Nöbet Sistemi';
  }
};

// Uygulama kapalı/arka planda iken gelen FCM mesajları burada işlenir
messaging.onBackgroundMessage((payload) => {
  const type  = payload.data?.type ?? '';
  const title = payload.notification?.title ?? titleFor(type);
  const body  = payload.notification?.body  ?? '';

  return self.registration.showNotification(title, {
    body,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data,
    tag: type,
  });
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(clients.openWindow('/'));
});
