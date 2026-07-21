import React, { useState, useEffect } from 'react';
import { onAuthStateChanged, signOut } from 'firebase/auth';
import { auth } from './firebase';
import Login from './components/Login';
import Dashboard from './components/Dashboard';

const ADMIN_EMAIL = 'codewithsachin10@gmail.com';

function App() {
  const [user, setUser] = useState(null);
  const [initializing, setInitializing] = useState(true);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (currentUser) => {
      if (currentUser) {
        if (currentUser.email === ADMIN_EMAIL) {
          setUser(currentUser);
        } else {
          // Force sign out non-admins
          await signOut(auth);
          setUser(null);
        }
      } else {
        setUser(null);
      }
      setInitializing(false);
    });

    return () => unsubscribe();
  }, []);

  if (initializing) {
    return (
      <div 
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          minHeight: '100vh',
          background: '#0b0f19',
          color: '#f3f4f6',
          fontFamily: 'system-ui'
        }}
      >
        <div style={{ textAlign: 'center' }}>
          <h2 style={{ letterSpacing: '1px', marginBottom: '8px' }}>CAMPUSLY</h2>
          <p style={{ color: '#9ca3af', fontSize: '14px' }}>Loading admin credentials...</p>
        </div>
      </div>
    );
  }

  return (
    <div>
      {user ? (
        <Dashboard user={user} onLogout={() => setUser(null)} />
      ) : (
        <Login onLoginSuccess={(loggedInUser) => setUser(loggedInUser)} />
      )}
    </div>
  );
}

export default App;
