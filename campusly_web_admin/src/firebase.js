import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: "AIzaSyBTegv3BzW9RTiuZcy-5-ElcUVMtG5IZEk",
  authDomain: "campusly-app-2026.firebaseapp.com",
  projectId: "campusly-app-2026",
  storageBucket: "campusly-app-2026.firebasestorage.app",
  messagingSenderId: "1144756968",
  appId: "1:1144756968:web:6dc2d5ec3256f4fe5a075d"
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
