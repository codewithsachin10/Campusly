import React from 'react';

export default function Unauthorized({ onReturnToLogin }) {
  return (
    <div className="flex flex-col items-center justify-center min-h-screen p-6 bg-slate-50">
      <div className="w-full max-w-[400px] bg-white border border-slate-200 rounded-xl p-8 shadow-sm text-center space-y-6 animate-fade-in">
        
        {/* Lock Icon */}
        <div className="w-16 h-16 mx-auto rounded-full bg-red-50 text-red-600 flex items-center justify-center border border-red-100">
          <span className="material-symbols-outlined text-[32px]">block</span>
        </div>

        {/* Text */}
        <div className="space-y-2">
          <h1 className="text-xl font-bold text-slate-900 tracking-tight">Unauthorized Access</h1>
          <p className="text-sm text-slate-500 leading-relaxed">
            This account is not authorized to access the Campusly Admin Dashboard.
          </p>
        </div>

        {/* Action Button */}
        <button 
          onClick={onReturnToLogin}
          className="w-full py-3 bg-slate-900 hover:bg-slate-800 text-white font-semibold rounded-lg text-sm transition-all duration-150 cursor-pointer shadow-sm active:scale-[0.98]"
        >
          Return to Login
        </button>

      </div>
    </div>
  );
}
