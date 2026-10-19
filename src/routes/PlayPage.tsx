import React from 'react';
import { useNavigate } from 'react-router-dom';

export const PlayPage: React.FC = () => {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen w-full bg-[#1A1F2E] flex flex-col items-center justify-center relative p-6 font-mono text-[#E8E0D0]">
      <button
        type="button"
        onClick={() => navigate('/')}
        className="absolute top-6 left-6 font-mono text-xs text-[#8A8FA8] hover:text-[#F0A500] transition-colors uppercase tracking-widest flex items-center gap-2 border border-[#3A4156] px-3 py-1.5 bg-[#252B3B]"
      >
        <span>&larr;</span> BACK TO HOME
      </button>

      <div className="text-center px-4">
        <h1 className="font-heading text-2xl sm:text-4xl md:text-5xl text-[#E8E0D0] tracking-wide animate-pulse">
          LOADING FACILITY...
        </h1>
        <div className="mt-4 font-mono text-xs text-[#8A8FA8] tracking-widest">
          INITIALIZING SCADA METERS &middot; HHI CALIBRATION
        </div>
      </div>
    </div>
  );
};

export default PlayPage;
