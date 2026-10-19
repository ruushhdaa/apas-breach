import React from 'react';
import { useNavigate } from 'react-router-dom';

export const FinalCTA: React.FC = () => {
  const navigate = useNavigate();

  return (
    <section className="relative w-full bg-gradient-to-b from-[#1A1F2E] to-[#252B3B] py-36 px-4 sm:px-8 border-t border-[#3A4156] overflow-hidden">
      <div className="vignette" />
      <div className="film-grain" />

      <div className="relative z-10 max-w-4xl mx-auto flex flex-col items-center text-center">
        {/* Heading */}
        <h2 className="font-heading text-4xl sm:text-6xl md:text-7xl lg:text-8xl text-[#E8E0D0] leading-[1.05] tracking-tight">
          <span>ONE SHIFT.</span>
          <br />
          <span>MAKE IT COUNT.</span>
        </h2>

        {/* Subheading */}
        <div className="mt-6 font-mono text-sm sm:text-base text-[#8A8FA8] leading-[2] max-w-md">
          <p>The facility is running.</p>
          <p>The creek is watching.</p>
          <p>The regulator is on call.</p>
        </div>

        {/* PLAY NOW button */}
        <button
          type="button"
          onClick={() => navigate('/play')}
          className="mt-12 font-heading text-lg sm:text-2xl tracking-wider bg-[#F0A500] text-[#1A1F2E] px-10 sm:px-14 py-4 sm:py-5 border-2 border-[#1A1F2E] comic-shadow animate-amber-pulse hover:bg-[#C17F24] transition-colors focus:outline-none"
        >
          PLAY NOW &rarr;
        </button>

        {/* Small text */}
        <p className="mt-5 font-mono text-xs text-[#8A8FA8] leading-relaxed max-w-xs">
          Runs in your browser. No install. No account.
          <br />
          Best experienced with headphones.
        </p>
      </div>
    </section>
  );
};
