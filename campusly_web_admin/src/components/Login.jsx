import React, { useState } from 'react';
import { signInWithPopup, GoogleAuthProvider, signOut } from 'firebase/auth';
import { auth } from '../firebase';

const ADMIN_EMAIL = 'codewithsachin10@gmail.com';

export default function Login({ onLoginSuccess, onUnauthorizedAttempt }) {
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleGoogleSignIn = async () => {
    setError('');
    setLoading(true);

    try {
      const provider = new GoogleAuthProvider();
      const result = await signInWithPopup(auth, provider);
      const user = result.user;

      if (user.email === ADMIN_EMAIL) {
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

  return (
    <div className="flex items-center justify-center min-h-screen p-6 bg-background relative overflow-hidden">
      {/* Floating Background Blobs */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none -z-10">
        <div className="absolute top-[-10%] left-[-5%] w-[400px] h-[400px] rounded-full bg-surface-container-high opacity-40 blur-[80px]"></div>
        <div className="absolute bottom-[-10%] right-[-5%] w-[500px] h-[500px] rounded-full bg-surface-container-high opacity-40 blur-[100px]"></div>
      </div>

      <main className="w-full max-w-md relative z-10">
        <div className="flex flex-col items-center mb-8">
          <div className="w-16 h-16 mb-4 rounded-xl bg-secondary flex items-center justify-center text-white shadow-soft">
            <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <path d="M22 10v6M2 10l10-5 10 5-10 5z"/>
              <path d="M6 12v5c0 2 2 3 6 3s6-1 6-3v-5"/>
            </svg>
          </div>
          <h1 className="font-brand text-headline-lg font-bold text-on-surface tracking-tight">Campusly</h1>
        </div>

        {/* Login Card */}
        <div className="login-card bg-surface-container-lowest border border-outline-variant p-10 rounded-xl">
          <div className="text-center mb-10">
            <h2 className="font-headline-md text-headline-md text-on-surface mb-2">Welcome back, Admin</h2>
            <p className="font-body-md text-body-md text-on-surface-variant">Sign in to manage the Campusly ecosystem.</p>
          </div>

          {error && (
            <div className="error-message bg-error-container/40 border border-error/20 text-error p-4 rounded-lg text-sm mb-6 flex items-center gap-2">
              <span className="material-symbols-outlined text-[20px]">warning</span>
              <span>{error}</span>
            </div>
          )}

          {/* Sign In Button */}
          <button 
            onClick={handleGoogleSignIn}
            disabled={loading}
            className="btn-google w-full flex items-center justify-center gap-3 py-3.5 px-6 bg-surface-container-lowest border border-outline-variant rounded-lg font-title-lg text-on-surface hover:bg-surface-bright active:scale-[0.98] transition-all cursor-pointer"
          >
            <svg height="20" viewBox="0 0 24 24" width="20" xmlns="http://www.w3.org/2000/svg">
              <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"></path>
              <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"></path>
              <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l3.66-2.84z" fill="#FBBC05"></path>
              <path d="M12 5.38c1.62 0 3.06.56 4.21 1.66l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"></path>
            </svg>
            <span className="font-medium text-body-lg">{loading ? 'Connecting...' : 'Continue with Google'}</span>
          </button>

          {/* Divider */}
          <div className="relative my-8">
            <div aria-hidden="true" className="absolute inset-0 flex items-center">
              <div className="w-full border-t border-outline-variant"></div>
            </div>
            <div className="relative flex justify-center text-label-md">
              <span className="px-3 bg-surface-container-lowest text-outline uppercase tracking-widest text-[10px]">Institutional Access</span>
            </div>
          </div>

          {/* SSO Info Box */}
          <div className="flex items-start gap-3 p-4 bg-surface-container rounded-lg border border-transparent">
            <span className="material-symbols-outlined text-secondary text-[20px] mt-0.5" data-icon="verified_user">verified_user</span>
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
