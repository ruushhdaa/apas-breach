import React, { useState, useMemo } from 'react';

interface TierData {
  tierName: string;
  tierColor: string;
  skyGradient: string;
  fogOpacity: number;
  steamCount: number;
  creekColor: string;
  desc: string;
}

export const WorldSection: React.FC = () => {
  const [hhi, setHhi] = useState<number>(85); // Default Restored

  const currentTier: TierData = useMemo(() => {
    if (hhi <= 19) {
      return {
        tierName: 'COLLAPSE',
        tierColor: '#CC2200',
        skyGradient: 'linear-gradient(to bottom, #0A0800, #1A1400)',
        fogOpacity: 0.65,
        steamCount: 30,
        creekColor: '#0A0800',
        desc: 'The creek is black. The street is empty. You failed the facility and everything downstream.',
      };
    } else if (hhi <= 39) {
      return {
        tierName: 'BREACH',
        tierColor: '#F0A500',
        skyGradient: 'linear-gradient(to bottom, #1A0A00, #3A1005)',
        fogOpacity: 0.5,
        steamCount: 24,
        creekColor: '#2A1008',
        desc: 'Alarms. Steam pressure critical. The regulator has been notified.',
      };
    } else if (hhi <= 59) {
      return {
        tierName: 'CRITICAL',
        tierColor: '#F0A500',
        skyGradient: 'linear-gradient(to bottom, #2E2010, #4A3018)',
        fogOpacity: 0.38,
        steamCount: 18,
        creekColor: '#4A3020',
        desc: 'Heat stress on the cooling loop. You have maybe two decisions left.',
      };
    } else if (hhi <= 79) {
      return {
        tierName: 'STRESSED',
        tierColor: '#E8E0D0',
        skyGradient: 'linear-gradient(to bottom, #3D3A2A, #5A543A)',
        fogOpacity: 0.25,
        steamCount: 12,
        creekColor: '#5A5A4A',
        desc: 'The numbers are bad but recoverable. Every choice costs more than it should.',
      };
    } else {
      return {
        tierName: 'RESTORED',
        tierColor: '#4A7C59',
        skyGradient: 'linear-gradient(to bottom, #2B4A7A, #F0A500)',
        fogOpacity: 0.1,
        steamCount: 5,
        creekColor: '#3A6B9C',
        desc: 'The creek is blue. The towers are quiet. You bought the city one more night.',
      };
    }
  }, [hhi]);

  return (
    <section
      id="world"
      className="relative w-full bg-[#1A1F2E] py-28 px-4 sm:px-8 border-t border-[#3A4156] overflow-hidden"
    >
      <div className="vignette" />
      <div className="film-grain" />

      <div className="relative z-10 max-w-6xl mx-auto flex flex-col items-center">
        {/* Heading */}
        <h2 className="font-heading text-3xl sm:text-5xl text-[#E8E0D0] text-center tracking-tight">
          EVERY CHOICE CHANGES THE WORLD
        </h2>

        {/* Subheading */}
        <p className="mt-4 font-mono text-[15px] text-[#8A8FA8] text-center max-w-2xl mb-16 leading-relaxed">
          The sky. The steam. The creek. The street outside. Nothing in this facility is cosmetic.
        </p>

        {/* Interactive World Scene Container */}
        <div className="w-full h-[280px] sm:h-[400px] border-2 border-[#3A4156] relative overflow-hidden comic-shadow mb-10 transition-colors duration-700">
          {/* Dynamic Sky Background */}
          <div
            className="absolute inset-0 transition-all duration-700 ease-in-out"
            style={{ background: currentTier.skyGradient }}
          />

          {/* Dynamic Fog Overlay */}
          <div
            className="absolute inset-0 bg-[#3A4156] pointer-events-none transition-opacity duration-700"
            style={{ opacity: currentTier.fogOpacity }}
          />

          {/* Steam Particles (Warm Off-white #F5F0E8) */}
          <div className="absolute inset-0 pointer-events-none overflow-hidden z-10">
            {Array.from({ length: currentTier.steamCount }).map((_, i) => (
              <div
                key={i}
                className="absolute rounded-full blur-md opacity-30 animate-pulse"
                style={{
                  left: `${20 + (i * 7) % 65}%`,
                  bottom: `${30 + (i * 9) % 50}%`,
                  width: `${20 + (i * 4) % 35}px`,
                  height: `${20 + (i * 4) % 35}px`,
                  backgroundColor: '#F5F0E8',
                }}
              />
            ))}
          </div>

          {/* Cooling Tower Silhouettes (Inked SVG #252B3B) */}
          <div className="absolute bottom-10 left-0 right-0 z-20 pointer-events-none flex justify-center">
            <svg
              viewBox="0 0 1000 240"
              className="w-full h-auto max-h-[220px]"
              preserveAspectRatio="xMidYMax meet"
            >
              {/* Skyline bar */}
              <rect x="0" y="200" width="1000" height="40" fill="#252B3B" stroke="#3A4156" strokeWidth="2.5" />
              {/* Tower 1 */}
              <path
                d="M150,200 C160,130 180,60 190,30 L270,30 C280,60 300,130 310,200 Z"
                fill="#252B3B"
                stroke="#3A4156"
                strokeWidth="2.5"
              />
              <ellipse cx="230" cy="30" rx="40" ry="5" fill="#1A1F2E" stroke="#3A4156" strokeWidth="2" />
              {/* Tower 2 */}
              <path
                d="M380,200 C390,120 415,50 425,20 L515,20 C525,50 550,120 560,200 Z"
                fill="#252B3B"
                stroke="#3A4156"
                strokeWidth="3"
              />
              <ellipse cx="470" cy="20" rx="45" ry="6" fill="#1A1F2E" stroke="#3A4156" strokeWidth="2" />
              {/* Tower 3 */}
              <path
                d="M630,200 C640,130 660,60 670,30 L750,30 C760,60 780,130 790,200 Z"
                fill="#252B3B"
                stroke="#3A4156"
                strokeWidth="2.5"
              />
              <ellipse cx="710" cy="30" rx="40" ry="5" fill="#1A1F2E" stroke="#3A4156" strokeWidth="2" />
            </svg>
          </div>

          {/* Creek Strip at Bottom */}
          <div
            className="absolute bottom-0 left-0 right-0 h-10 border-t-2 border-[#1A1F2E] z-30 transition-colors duration-700"
            style={{ backgroundColor: currentTier.creekColor }}
          >
            {/* Creek ripple line */}
            <div className="w-full h-full opacity-20 bg-[repeating-linear-gradient(90deg,transparent,transparent_20px,rgba(240,165,0,0.4)_20px,rgba(240,165,0,0.4)_40px)]" />
          </div>
        </div>

        {/* HHI Slider Controls */}
        <div className="w-full max-w-2xl px-4 flex flex-col items-center">
          <div className="w-full flex justify-between font-mono text-[11px] mb-2 select-none">
            <span className="text-[#CC2200] font-bold">&larr; COLLAPSE</span>
            <span className="text-[#8A8FA8] font-bold">HHI: {hhi} / 100</span>
            <span className="text-[#4A7C59] font-bold">RESTORED &rarr;</span>
          </div>

          {/* Range Slider */}
          <input
            type="range"
            min="0"
            max="100"
            value={hhi}
            onChange={(e) => setHhi(Number(e.target.value))}
            className="w-full h-3 rounded-none appearance-none cursor-pointer border border-[#3A4156] accent-[#F0A500]"
            style={{
              background: 'linear-gradient(to right, #CC2200, #F0A500 50%, #4A7C59 100%)',
            }}
            aria-label="Hydro Health Index slider"
          />

          {/* Tier Status Card */}
          <div className="mt-8 text-center flex flex-col items-center max-w-lg">
            <h3
              className="font-heading text-3xl tracking-wide transition-colors duration-300"
              style={{ color: currentTier.tierColor }}
            >
              {currentTier.tierName}
            </h3>
            <p className="mt-2 font-mono text-sm text-[#8A8FA8] leading-relaxed">
              {currentTier.desc}
            </p>
          </div>

          {/* Body Text Below Slider */}
          <p className="mt-12 font-mono text-sm text-[#8A8FA8] text-center max-w-md leading-relaxed border-t border-[#3A4156]/50 pt-6">
            The Hydro Health Index runs from 0 to 100. It drives everything you can see and hear. There is no cheat code. There is no autosave.
          </p>
        </div>
      </div>
    </section>
  );
};
