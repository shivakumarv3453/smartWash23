importScripts("https://www.gstatic.com/firebasejs/10.8.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.8.1/firebase-messaging-compat.js");

firebase.initializeApp({
    apiKey: "AIzaSyDBXwnO8b0OYrc7d8ndv0J28bDNC6aZlNw",
    authDomain: "fir-auth-f1931.firebaseapp.com",
    projectId: "fir-auth-f1931",
    storageBucket: "fir-auth-f1931.firebasestorage.app",
    messagingSenderId: "760988528329",
    appId: "1:760988528329:web:5f2e69aa3d4eec67512718"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("[Firebase Messaging] Received background message: ", payload);

  self.registration.showNotification(payload.notification.title, {
    body: payload.notification.body,
    icon: "/icons/icon-192x192.png",
  });
});
