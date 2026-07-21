import React from 'react';

export default function Unauthorized({ user, onSignOut, onReturnToLogin }) {
  return (
    <div className="bg-background font-body-md text-on-background overflow-hidden min-h-screen relative flex flex-col items-center justify-center px-6 py-12">
      {/* Background Decorative Elements */}
      <div className="fixed inset-0 z-0 overflow-hidden pointer-events-none">
        <div className="absolute -top-[10%] -left-[10%] w-[40%] h-[40%] bg-surface-container-highest rounded-full blur-[120px] opacity-40"></div>
        <div className="absolute bottom-[5%] right-[5%] w-[30%] h-[30%] bg-secondary-fixed-dim rounded-full blur-[100px] opacity-30"></div>
      </div>

      {/* Main Content Canvas */}
      <main className="relative z-10 flex flex-col items-center justify-center w-full">
        {/* Logo Branding */}
        <div className="mb-12 flex items-center gap-3">
          <div className="w-10 h-10 bg-primary rounded-lg flex items-center justify-center shadow-lg">
            <span className="material-symbols-outlined text-on-primary text-[24px]">school</span>
          </div>
          <span className="font-headline-lg text-headline-lg font-black tracking-tight text-on-surface">Campusly</span>
        </div>

        {/* Bento-style Alert Card */}
        <div className="max-w-2xl w-full grid grid-cols-1 md:grid-cols-12 gap-4">
          {/* Main Content Card */}
          <div className="md:col-span-12 bg-white/70 backdrop-blur-md border border-slate-200/80 rounded-xl p-8 md:p-12 shadow-2xl flex flex-col items-center text-center">
            <div className="w-20 h-20 bg-error-container rounded-full flex items-center justify-center mb-8 animate-pulse">
              <span className="material-symbols-outlined text-error text-[40px]" style={{ fontVariationSettings: "'FILL' 1" }}>gpp_maybe</span>
            </div>
            <h1 className="font-display-lg text-display-lg text-error mb-4">Unauthorized Access</h1>
            <p className="font-body-lg text-body-lg text-on-surface-variant max-w-md mb-10 leading-relaxed">
              This account (<strong>{user?.email}</strong>) does not have administrator permissions for Campusly. Access is restricted to authorized personnel only.
            </p>

            {/* Action Cluster */}
            <div className="flex flex-col sm:flex-row items-center gap-4 w-full justify-center">
              <button 
                onClick={onSignOut}
                className="w-full sm:w-auto px-8 py-3 bg-primary text-on-primary font-label-md text-label-md rounded-lg hover:opacity-90 active:scale-95 transition-all shadow-md flex items-center justify-center gap-2 cursor-pointer"
              >
                <span className="material-symbols-outlined text-[20px]">logout</span>
                Sign Out
              </button>
              <button 
                onClick={onReturnToLogin}
                className="w-full sm:w-auto px-8 py-3 bg-surface-container-lowest text-on-surface border border-outline-variant font-label-md text-label-md rounded-lg hover:bg-surface-container-low active:scale-95 transition-all flex items-center justify-center gap-2 cursor-pointer"
              >
                <span className="material-symbols-outlined text-[20px]">arrow_back</span>
                Return to Login
              </button>
            </div>
          </div>

          {/* Bottom Detail Cards */}
          <div className="md:col-span-7 bg-white/70 backdrop-blur-md border border-slate-200/80 rounded-xl p-6 flex items-start gap-4 shadow-sm">
            <div className="p-2 bg-surface-container-high rounded-lg flex-shrink-0">
              <span className="material-symbols-outlined text-secondary text-[24px]">contact_support</span>
            </div>
            <div>
              <h3 className="font-title-lg text-title-lg text-on-surface mb-1">Need access?</h3>
              <p className="text-label-md text-on-surface-variant leading-tight">
                Please contact the system administrator to whitelist this email ID for backend console authorization.
              </p>
            </div>
          </div>

          <div className="md:col-span-5 bg-white/70 backdrop-blur-md border border-slate-200/80 rounded-xl p-6 flex items-start gap-4 shadow-sm">
            <div className="p-2 bg-surface-container-high rounded-lg flex-shrink-0">
              <span className="material-symbols-outlined text-secondary text-[24px]">security</span>
            </div>
            <div>
              <h3 className="font-title-lg text-title-lg text-on-surface mb-1">Security Policy</h3>
              <p className="text-label-md text-on-surface-variant leading-tight">
                All login attempts and authorization breaches are securely logged for audit checks.
              </p>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
