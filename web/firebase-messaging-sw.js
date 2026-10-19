importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyBKmeY5AoMI3sE9CUhQTQqeDC5biwagX8A",
  authDomain: "order-gaza.firebaseapp.com",
  projectId: "order-gaza",
  storageBucket: "order-gaza.firebasestorage.app",
  messagingSenderId: "103107852998",
  appId: "1:103107852998:web:bb0b90580a88eb63f8f5c7",
  measurementId: "G-BXEB8PFCBH"
});

const messaging = firebase.messaging();

// Optional: Background message handler
messaging.onBackgroundMessage(function(payload) {
  console.log('Received background message ', payload);
});
