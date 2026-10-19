import React from 'react';
import { useNavigate } from 'react-router-dom';

export const CreditsPage: React.FC = () => {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-[#1A1F2E] text-[#E8E0D0] flex flex-col font-mono selection:bg-[#F0A500] selection:text-[#1A1F2E] relative">
      <div className="vignette" />
      <div className="film-grain" />

      {/* Header bar */}
      <header className="relative z-10 w-full border-b border-[#3A4156] bg-[#1A1F2E]/90 px-6 py-4 flex justify-between items-center">
        <span className="font-heading text-lg text-[#F0A500]">APAS : BREACH</span>
        <button
          type="button"
          onClick={() => navigate('/')}
          className="font-mono text-xs text-[#F0A500] hover:text-[#E8E0D0] border border-[#3A4156] px-4 py-2 bg-[#252B3B] cursor-crosshair transition-colors"
        >
          &larr; BACK TO TITLE
        </button>
      </header>

      <main className="relative z-10 flex-1 max-w-4xl mx-auto w-full py-16 px-6 sm:px-8">
        <h1 className="font-heading text-3xl sm:text-5xl text-[#E8E0D0] mb-12 tracking-tight">
          CREDITS &amp; LICENCES
        </h1>

        <div className="space-y-10">
          <div>
            <h2 className="font-heading text-base sm:text-lg text-[#F0A500] tracking-wider mb-2">
              BUILT WITH
            </h2>
            <p className="font-mono text-xs sm:text-sm text-[#8A8FA8] leading-relaxed">
              React &middot; TypeScript &middot; Vite &middot; Three.js &middot; Tailwind CSS &middot; Zustand &middot; Web Audio API
            </p>
          </div>

          <div>
            <h2 className="font-heading text-base sm:text-lg text-[#F0A500] tracking-wider mb-2">
              FONTS
            </h2>
            <p className="font-mono text-xs sm:text-sm text-[#8A8FA8] leading-relaxed">
              Rubik Mono One &mdash; SIL Open Font Licence
              <br />
              Space Mono &mdash; SIL Open Font Licence
            </p>
          </div>

          <div>
            <h2 className="font-heading text-base sm:text-lg text-[#F0A500] tracking-wider mb-2">
              AUDIO
            </h2>
            <p className="font-mono text-xs sm:text-sm text-[#8A8FA8] leading-relaxed">
              All audio is synthesised in-browser via Web Audio API. No audio samples or licensed tracks were used.
            </p>
          </div>

          <div>
            <h2 className="font-heading text-base sm:text-lg text-[#F0A500] tracking-wider mb-2">
              ASSETS
            </h2>
            <p className="font-mono text-xs sm:text-sm text-[#8A8FA8] leading-relaxed">
              Original hand-drawn comic character art. Zero third-party copyrighted assets.
            </p>
          </div>

          <div>
            <h2 className="font-heading text-base sm:text-lg text-[#F0A500] tracking-wider mb-2">
              DATA &amp; FACTS
            </h2>
            <p className="font-mono text-xs sm:text-sm text-[#8A8FA8] leading-relaxed">
              Field Notes facts are sourced from publicly available research. Numbers used in simulation are model assumptions for illustrative purposes.
            </p>
          </div>
        </div>
      </main>

      <footer className="relative z-10 w-full border-t border-[#3A4156] py-6 text-center text-xs text-[#8A8FA8]">
        APAS : BREACH &middot; ONE NIGHT OVERNIGHT &middot; 2001 RETRO 3D
      </footer>
    </div>
  );
};

export default CreditsPage;
