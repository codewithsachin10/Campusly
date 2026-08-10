const { initializeApp } = require("firebase/app");
const { getFirestore, collection, getDocs } = require("firebase/firestore");

const firebaseConfig = {
  apiKey: "AIzaSyBTegv3BzW9RTiuZcy-5-ElcUVMtG5IZEk",
  appId: "1:1144756968:web:6dc2d5ec3256f4fe5a075d",
  messagingSenderId: "1144756968",
  projectId: "campusly-app-2026",
  authDomain: "campusly-app-2026.firebaseapp.com",
  storageBucket: "campusly-app-2026.firebasestorage.app",
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function main() {
  const snapshot = await getDocs(collection(db, "classes/section-b/schedule"));
  console.log("Found", snapshot.docs.length, "docs in classes/section-b/schedule");
  snapshot.docs.forEach((d) => {
    console.log(d.id, d.data());
  });
}

main().catch(console.error);
