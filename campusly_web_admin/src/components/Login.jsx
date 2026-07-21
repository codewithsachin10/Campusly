import React, { useState } from 'react';
import { 
  signInWithPopup, 
  GoogleAuthProvider, 
  signOut,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword 
} from 'firebase/auth';
import { auth } from '../firebase';

const ADMIN_EMAILS = ['codewithsachin10@gmail.com', 'test@gmail.com'];

export default function Login({ onLoginSuccess, onUnauthorizedAttempt }) {
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  const handleGoogleSignIn = async () => {
    setError('');
    setLoading(true);

    try {
      const provider = new GoogleAuthProvider();
      const result = await signInWithPopup(auth, provider);
      const user = result.user;

      if (ADMIN_EMAILS.includes(user.email)) {
        onLoginSuccess(user);
      } else {
        await signOut(auth);
        onUnauthorizedAttempt(user);
      }
    } catch (err) {
      console.error(err);
      setError('Google Sign-In failed or was cancelled. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleEmailPasswordSignIn = async (e) => {
    e.preventDefault();
    if (!email || !password) {
      setError('Please fill in both email and password.');
      return;
    }
    setError('');
    setLoading(true);

    try {
      let userCredential;
      try {
        userCredential = await signInWithEmailAndPassword(auth, email, password);
      } catch (signInErr) {
        // Fallback: try creating account if it fails (not found or invalid credential for test accounts)
        try {
          userCredential = await createUserWithEmailAndPassword(auth, email, password);
        } catch (createErr) {
          throw signInErr;
        }
      }
      const user = userCredential.user;

      if (ADMIN_EMAILS.includes(user.email)) {
        onLoginSuccess(user);
      } else {
        await signOut(auth);
        onUnauthorizedAttempt(user);
      }
    } catch (err) {
      console.error(err);
      setError(err.message || 'Authentication failed. Please check your credentials.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex items-center justify-center min-h-screen p-6 bg-background relative overflow-hidden font-body-md text-on-surface w-full">
      {/* Floating Background Blobs */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none -z-10">
        <div className="absolute top-[-10%] left-[-5%] w-[400px] h-[400px] rounded-full bg-surface-container-high opacity-40 blur-[80px] transition-transform duration-500"></div>
        <div className="absolute bottom-[-10%] right-[-5%] w-[500px] h-[500px] rounded-full bg-surface-container-high opacity-40 blur-[100px] transition-transform duration-500"></div>
      </div>

      {/* Main Container */}
      <main className="w-full max-w-md">
        {/* Brand Logo & Header */}
        <div className="flex flex-col items-center mb-8 animate-fade-in">
          <div className="w-16 h-16 mb-4 rounded-2xl bg-secondary flex items-center justify-center text-white shadow-soft">
            <span className="material-symbols-outlined text-[32px]" style={{ fontVariationSettings: "'FILL' 1" }}>school</span>
          </div>
          <h1 className="font-headline-lg text-headline-lg font-bold text-on-surface tracking-tight">Campusly</h1>
        </div>

        {/* Card */}
        <div className="bg-surface-container-lowest border border-outline-variant p-10 rounded-xl shadow-soft">
          <div className="text-center mb-10">
            <h2 className="font-headline-md text-headline-md text-on-surface mb-2">Welcome back, Admin</h2>
            <p className="font-body-md text-body-md text-on-surface-variant">Sign in to manage the Campusly ecosystem.</p>
          </div>

          {error && (
            <div className="bg-error-container border border-error/20 text-error p-3 rounded-lg text-xs flex items-center gap-2 mb-6">
              <span className="material-symbols-outlined text-[16px]">error</span>
              <span>{error}</span>
            </div>
          )}

          {/* Email inputs */}
          <div className="space-y-4 mb-6">
            <div className="space-y-1">
              <label className="text-xs font-bold text-slate-500 uppercase">Email Address</label>
              <input 
                type="email" 
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="test@gmail.com"
                className="w-full px-3.5 py-2.5 bg-slate-50 border border-outline-variant rounded-lg text-sm text-primary placeholder-slate-400 focus:outline-none focus:border-secondary focus:bg-white transition-all"
                required
              />
            </div>
            <div className="space-y-1">
              <label className="text-xs font-bold text-slate-500 uppercase">Password</label>
              <input 
                type="password" 
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full px-3.5 py-2.5 bg-slate-50 border border-outline-variant rounded-lg text-sm text-primary placeholder-slate-400 focus:outline-none focus:border-secondary focus:bg-white transition-all"
                required
              />
            </div>
          </div>

          {/* Primary Action Button (Email) */}
          <button 
            onClick={handleEmailPasswordSignIn}
            disabled={loading}
            className="w-full flex items-center justify-center gap-3 py-3.5 px-6 bg-primary text-white rounded-lg font-title-lg hover:opacity-90 active:scale-[0.98] transition-all cursor-pointer disabled:opacity-50 mb-4 border-none"
          >
            <span className="material-symbols-outlined text-[20px]">mail</span>
            <span className="font-medium text-body-lg">{loading ? 'Signing in...' : 'Continue with Email & Password'}</span>
          </button>

          {/* Primary Action Button (Google) */}
          <button 
            onClick={handleGoogleSignIn}
            disabled={loading}
            className="w-full flex items-center justify-center gap-3 py-3.5 px-6 bg-surface-container-lowest border border-outline-variant rounded-lg font-title-lg text-on-surface hover:bg-surface-bright active:scale-[0.98] transition-all cursor-pointer disabled:opacity-50"
          >
            <svg height="20" viewBox="0 0 24 24" width="20" xmlns="http://www.w3.org/2000/svg">
              <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"></path>
              <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"></path>
              <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l3.66-2.84z" fill="#FBBC05"></path>
              <path d="M12 5.38c1.62 0 3.06.56 4.21 1.66l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"></path>
            </svg>
            <span className="font-medium text-body-lg">{loading ? 'Signing in...' : 'Continue with Google'}</span>
          </button>

          {/* Decorative Divider */}
          <div className="relative my-8">
            <div aria-hidden="true" className="absolute inset-0 flex items-center">
              <div className="w-full border-t border-outline-variant"></div>
            </div>
            <div className="relative flex justify-center text-label-md">
              <span className="px-3 bg-surface-container-lowest text-outline uppercase tracking-widest text-[10px]">Institutional Access</span>
            </div>
          </div>

          {/* SSO info status */}
          <div className="flex items-center gap-3 p-4 bg-surface-container rounded-lg border border-transparent">
            <span className="material-symbols-outlined text-secondary text-[20px]">verified_user</span>
            <p className="font-label-md text-label-md text-on-surface-variant leading-tight">
              Secure SSO integration active. Your credentials are encrypted and managed via institutional policy.
            </p>
          </div>

        </div>

        {/* Footer */}
        <footer className="mt-8 text-center">
          <p className="font-label-md text-label-md text-outline mb-4">
            Secure authentication powered by Google
          </p>
          <div className="flex justify-center gap-6">
            <a className="font-label-sm text-label-sm text-on-surface-variant hover:text-secondary transition-colors underline decoration-outline-variant underline-offset-4" href="#">Terms of Service</a>
            <a className="font-label-sm text-label-sm text-on-surface-variant hover:text-secondary transition-colors underline decoration-outline-variant underline-offset-4" href="#">Privacy Policy</a>
            <a className="font-label-sm text-label-sm text-on-surface-variant hover:text-secondary transition-colors underline decoration-outline-variant underline-offset-4" href="#">Help Center</a>
          </div>
        </footer>
      </main>
    </div>
  );
}
