import React, { useState, useEffect } from 'react';
import { onAuthStateChanged, signOut } from 'firebase/auth';
import { auth } from './firebase';
import Login from './components/Login';
import Dashboard from './components/Dashboard';
import Unauthorized from './components/Unauthorized';

const ADMIN_EMAIL = 'codewithsachin10@gmail.com';

function App() {
  const [user, setUser] = useState(null);
  const [unauthorizedUser, setUnauthorizedUser] = useState(null);
  const [initializing, setInitializing] = useState(true);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (currentUser) => {
      if (currentUser) {
        if (currentUser.email === ADMIN_EMAIL) {
          setUser(currentUser);
          setUnauthorizedUser(null);
        } else {
          setUnauthorizedUser(currentUser);
          setUser(null);
        }
      } else {
        setUser(null);
        setUnauthorizedUser(null);
      }
      setInitializing(false);
    });

    return () => unsubscribe();
  }, []);

  const handleSignOut = async () => {
    await signOut(auth);
    setUser(null);
    setUnauthorizedUser(null);
  };

  if (initializing) {
    return (
      <div 
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          minHeight: '100vh',
          background: '#f8f9ff',
          color: '#0d1c2f',
          fontFamily: 'system-ui'
        }}
      >
        <div style={{ textAlign: 'center' }}>
          <h2 style={{ letterSpacing: '1px', marginBottom: '8px', fontWeight: 'bold' }}>CAMPUSLY</h2>
          <p style={{ color: '#45464d', fontSize: '14px' }}>Loading admin credentials...</p>
        </div>
      </div>
    );
  }

  if (unauthorizedUser) {
    return (
      <Unauthorized 
        user={unauthorizedUser} 
        onSignOut={handleSignOut} 
        onReturnToLogin={handleSignOut}
      />
    );
  }

  return (
    <div>
      {user ? (
        <Dashboard user={user} onLogout={handleSignOut} />
      ) : (
        <Login 
          onLoginSuccess={(loggedInUser) => {
            setUser(loggedInUser);
            setUnauthorizedUser(null);
          }} 
          onUnauthorizedAttempt={(failedUser) => {
            setUnauthorizedUser(failedUser);
            setUser(null);
          }}
        />
      )}
    </div>
  );
}

export default App;
