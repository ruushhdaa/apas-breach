import React, { useState, useMemo, useRef } from 'react';

interface TierData {
  tierName: string;
  tierColor: string;
  skyTop: string;
  skyHorizon: string;
  cityColor: string;
  creekColor: string;
  creekHighlight: string;
  steamPuffCount: number;
  steamScale: number;
  desc: string;
}

export const WorldSection: React.FC = () => {
  const [hhi, setHhi] = useState<number>(85); // Default Restored
  const [mousePos, setMousePos] = useState<{ x: number; y: number }>({ x: 0, y: 0 });
  const containerRef = useRef<HTMLDivElement>(null);

  // Parallax on mouse move
  const handleMouseMove = (e: React.MouseEvent<HTMLDivElement>) => {
    if (!containerRef.current) return;
    const rect = containerRef.current.getBoundingClientRect();
    const x = ((e.clientX - rect.left) / rect.width - 0.5) * 2; // -1 to 1
    const y = ((e.clientY - rect.top) / rect.height - 0.5) * 2;
    setMousePos({ x, y });
  };

  const handleMouseLeave = () => {
    setMousePos({ x: 0, y: 0 });
  };

  // Tier Data mapped to GTA III illustrated dusk palette
  const currentTier: TierData = useMemo(() => {
    if (hhi <= 19) {
      return {
        tierName: 'COLLAPSE',
        tierColor: '#CC2200',
        skyTop: '#0A0800',
        skyHorizon: '#2A1500',
        cityColor: '#080600',
        creekColor: '#212121',
        creekHighlight: '#333333',
        steamPuffCount: 5,
        steamScale: 1.6,
        desc: 'The creek is black. The street is empty. You failed the facility and everything downstream.',
      };
    } else if (hhi <= 39) {
      return {
        tierName: 'BREACH',
        tierColor: '#F0A500',
        skyTop: '#1A0A00',
        skyHorizon: '#6A2000',
        cityColor: '#120800',
        creekColor: '#4E342E',
        creekHighlight: '#6D4C41',
        steamPuffCount: 4,
        steamScale: 1.35,
        desc: 'Alarms. Steam pressure critical. The regulator has been notified.',
      };
    } else if (hhi <= 59) {
      return {
        tierName: 'CRITICAL',
        tierColor: '#F0A500',
        skyTop: '#2E2010',
        skyHorizon: '#8A4A00',
        cityColor: '#1E1408',
        creekColor: '#795548',
        creekHighlight: '#8D6E63',
        steamPuffCount: 4,
        steamScale: 1.15,
        desc: 'Heat stress on the cooling loop. You have maybe two decisions left.',
      };
    } else if (hhi <= 79) {
      return {
        tierName: 'STRESSED',
        tierColor: '#E8E0D0',
        skyTop: '#3D3A2A',
        skyHorizon: '#C17F24',
        cityColor: '#25231A',
        creekColor: '#546E7A',
        creekHighlight: '#78909C',
        steamPuffCount: 3,
        steamScale: 0.95,
        desc: 'The numbers are bad but recoverable. Every choice costs more than it should.',
      };
    } else {
      return {
        tierName: 'RESTORED',
        tierColor: '#4A7C59',
        skyTop: '#2B4A7A', // Blue-grey at top
        skyHorizon: '#F0A500', // Amber at horizon (Hazy Mumbai dusk)
        cityColor: '#182438',
        creekColor: '#2196F3',
        creekHighlight: '#90CAF9',
        steamPuffCount: 2,
        steamScale: 0.75,
        desc: 'The creek is blue. The towers are quiet. You bought the city one more night.',
      };
    }
  }, [hhi]);

  return (
    <section
      id="world"
      className="relative w-full bg-[#1A1F2E] py-28 px-4 sm:px-8 border-t border-[#3A4156] overflow-hidden select-none"
    >
      <div className="vignette" />
      <div className="film-grain" />

      <div className="relative z-10 max-w-6xl mx-auto flex flex-col items-center">
        {/* Section Heading */}
        <h2 className="font-heading text-3xl sm:text-5xl text-[#E8E0D0] text-center tracking-tight">
          EVERY CHOICE CHANGES THE WORLD
        </h2>

        {/* Subheading */}
        <p className="mt-4 font-mono text-[15px] text-[#8A8FA8] text-center max-w-2xl mb-14 leading-relaxed">
          The sky. The steam. The creek. The street outside. Nothing in this facility is cosmetic.
        </p>

        {/* Dynamic World Canvas Scene */}
        <div
          ref={containerRef}
          onMouseMove={handleMouseMove}
          onMouseLeave={handleMouseLeave}
          className="w-full h-[300px] sm:h-[420px] border-2 border-[#3A4156] relative overflow-hidden comic-shadow mb-10 group cursor-crosshair"
        >
          {/* SVG World Art matching GTA III menu screen illustration style */}
          <svg
            viewBox="0 0 1200 400"
            className="w-full h-full object-cover transition-transform duration-300 ease-out"
            preserveAspectRatio="none"
          >
            <defs>
              {/* 1. SKY GRADIENT: Smooth warm blend from top to horizon amber */}
              <linearGradient id="skyDuskGradient" x1="0%" y1="0%" x2="0%" y2="100%">
                <stop offset="0%" stopColor={currentTier.skyTop} />
                <stop offset="55%" stopColor={currentTier.skyTop} stopOpacity="0.85" />
                <stop offset="85%" stopColor={currentTier.skyHorizon} />
              </linearGradient>

              {/* 5. HAZARD STRIPES PATTERN for facility gate barrier */}
              <pattern
                id="hazardStripes"
                width="24"
                height="24"
                patternUnits="userSpaceOnUse"
                patternTransform="rotate(45)"
              >
                <rect width="12" height="24" fill="#F0A500" />
                <rect x="12" width="12" height="24" fill="#1A1F2E" />
              </pattern>

              {/* Steam keyframe animations */}
              <style>{`
                @keyframes organicBillow1 {
                  0% { transform: translate(0px, 0px) scale(0.7); opacity: 0; }
                  20% { opacity: 0.75; }
                  60% { opacity: 0.45; }
                  100% { transform: translate(12px, -70px) scale(1.35); opacity: 0; }
                }
                @keyframes organicBillow2 {
                  0% { transform: translate(0px, 0px) scale(0.8); opacity: 0; }
                  25% { opacity: 0.8; }
                  70% { opacity: 0.5; }
                  100% { transform: translate(-15px, -85px) scale(1.45); opacity: 0; }
                }
                @keyframes organicBillow3 {
                  0% { transform: translate(0px, 0px) scale(0.65); opacity: 0; }
                  30% { opacity: 0.7; }
                  80% { opacity: 0.35; }
                  100% { transform: translate(18px, -95px) scale(1.55); opacity: 0; }
                }
                .billow-puff-1 { animation: organicBillow1 3.4s infinite ease-out; }
                .billow-puff-2 { animation: organicBillow2 4.1s infinite ease-out 1.2s; }
                .billow-puff-3 { animation: organicBillow3 4.8s infinite ease-out 2.3s; }
              `}</style>
            </defs>

            {/* LAYER 1: SKY (Smooth warm dusk gradient) */}
            <rect x="0" y="0" width="1200" height="330" fill="url(#skyDuskGradient)" />

            {/* LAYER 2: CITY SILHOUETTE (Single dark graphic building path on horizon) */}
            <g
              style={{
                transform: `translate3d(${mousePos.x * 6}px, ${mousePos.y * 3}px, 0)`,
                transition: 'transform 0.15s ease-out',
              }}
            >
              <path
                d="M0,270 L25,270 L25,245 L40,245 L40,270 L65,270 L65,230 L85,230 L85,215 L92,215 L92,270 L130,270 L145,255 L160,270 L290,270 L300,240 L315,240 L315,270 L480,270 L500,225 L505,200 L510,225 L525,225 L525,270 L600,270 L615,240 L645,240 L655,270 L800,270 L815,230 L840,230 L840,270 L870,270 L885,218 L890,218 L905,270 L1020,270 L1035,235 L1060,235 L1060,270 L1200,270 L1200,330 L0,330 Z"
                fill={currentTier.cityColor}
                stroke="#1A1F2E"
                strokeWidth="1.5"
              />
            </g>

            {/* LAYER 4: STEAM (Organic irregular rising puffs above cooling towers) */}
            {/* Tower 1 Steam (Center at x=230, top rim y=145) */}
            <g
              transform="translate(230, 145)"
              style={{
                transform: `translate3d(${230 + mousePos.x * 12}px, ${145 + mousePos.y * 6}px, 0)`,
              }}
            >
              <path
                className="billow-puff-1"
                d="M -15,0 C -30,-8 -25,-26 -10,-30 C -2,-40 22,-36 28,-22 C 40,-16 36,2 22,6 C 8,10 -8,8 -15,0 Z"
                fill="#F5F0E8"
                transform={`scale(${currentTier.steamScale})`}
              />
              {currentTier.steamPuffCount >= 3 && (
                <path
                  className="billow-puff-2"
                  d="M -12,-5 C -24,-14 -18,-32 -4,-34 C 4,-44 26,-38 30,-26 C 42,-22 35,-2 20,4 C 6,8 -6,6 -12,-5 Z"
                  fill="#F5F0E8"
                  transform={`scale(${currentTier.steamScale * 1.1})`}
                />
              )}
            </g>

            {/* Tower 2 Steam (Center at x=450, top rim y=165) */}
            <g
              transform="translate(450, 165)"
              style={{
                transform: `translate3d(${450 + mousePos.x * 12}px, ${165 + mousePos.y * 6}px, 0)`,
              }}
            >
              <path
                className="billow-puff-2"
                d="M -16,2 C -28,-6 -24,-24 -8,-28 C 0,-38 24,-34 28,-20 C 38,-14 34,4 20,8 C 6,12 -8,10 -16,2 Z"
                fill="#F5F0E8"
                transform={`scale(${currentTier.steamScale * 0.95})`}
              />
              {currentTier.steamPuffCount >= 4 && (
                <path
                  className="billow-puff-3"
                  d="M -10,-4 C -22,-12 -16,-30 -2,-32 C 6,-42 28,-36 32,-24 C 44,-20 37,0 22,6 C 8,10 -4,8 -10,-4 Z"
                  fill="#F5F0E8"
                  transform={`scale(${currentTier.steamScale * 1.15})`}
                />
              )}
            </g>

            {/* Tower 3 Steam (Center at x=750, top rim y=150) */}
            <g
              transform="translate(750, 150)"
              style={{
                transform: `translate3d(${750 + mousePos.x * 12}px, ${150 + mousePos.y * 6}px, 0)`,
              }}
            >
              <path
                className="billow-puff-3"
                d="M -14,-2 C -26,-10 -22,-28 -8,-30 C 2,-42 26,-36 30,-22 C 40,-16 35,4 20,8 C 8,12 -6,8 -14,-2 Z"
                fill="#F5F0E8"
                transform={`scale(${currentTier.steamScale})`}
              />
              {currentTier.steamPuffCount >= 3 && (
                <path
                  className="billow-puff-1"
                  d="M -16,2 C -30,-6 -24,-26 -10,-28 C -2,-38 20,-34 26,-20 C 36,-14 32,4 18,8 C 6,12 -8,10 -16,2 Z"
                  fill="#F5F0E8"
                  transform={`scale(${currentTier.steamScale * 1.1})`}
                />
              )}
            </g>

            {/* Tower 4 Steam (Center at x=980, top rim y=170) */}
            <g
              transform="translate(980, 170)"
              style={{
                transform: `translate3d(${980 + mousePos.x * 12}px, ${170 + mousePos.y * 6}px, 0)`,
              }}
            >
              <path
                className="billow-puff-1"
                d="M -12,0 C -24,-8 -20,-24 -6,-28 C 2,-36 22,-32 26,-18 C 36,-12 30,4 18,8 C 6,10 -6,8 -12,0 Z"
                fill="#F5F0E8"
                transform={`scale(${currentTier.steamScale * 0.9})`}
              />
              {currentTier.steamPuffCount >= 4 && (
                <path
                  className="billow-puff-2"
                  d="M -14,-4 C -26,-12 -20,-30 -6,-32 C 4,-42 26,-36 30,-24 C 40,-20 34,2 20,6 C 8,10 -4,8 -14,-4 Z"
                  fill="#F5F0E8"
                  transform={`scale(${currentTier.steamScale * 1.2})`}
                />
              )}
            </g>

            {/* LAYER 3: COOLING TOWERS with smooth Bezier hyperboloid curves */}
            <g
              style={{
                transform: `translate3d(${mousePos.x * 14}px, ${mousePos.y * 8}px, 0)`,
                transition: 'transform 0.15s ease-out',
              }}
            >
              {/* TOWER 1 (Tallest: xBase 170..290, top 200..260, yTop 145) */}
              <g>
                <path
                  d="M 170 330 C 185 260, 205 190, 200 145 L 260 145 C 255 190, 275 260, 290 330 Z"
                  fill="#2A3142"
                  stroke="#1A1F2E"
                  strokeWidth="2.5"
                  strokeLinejoin="round"
                />
                {/* Left Highlight Strip with matching Bezier */}
                <path
                  d="M 170 330 C 185 260, 205 190, 200 145 L 210 145 C 215 190, 195 260, 182 330 Z"
                  fill="#3A4156"
                />
                {/* Inked Rim */}
                <ellipse cx="230" cy="145" rx="30" ry="5" fill="#1A1F2E" stroke="#1A1F2E" strokeWidth="2" />
                {/* Catwalk Ring */}
                <path d="M 184 250 Q 230 258 276 250" fill="none" stroke="#1A1F2E" strokeWidth="1.8" strokeDasharray="6 3" />
              </g>

              {/* TOWER 2 (xBase 390..495, top 420..475, yTop 165) */}
              <g>
                <path
                  d="M 390 330 C 405 265, 422 205, 420 165 L 475 165 C 472 205, 488 265, 500 330 Z"
                  fill="#2A3142"
                  stroke="#1A1F2E"
                  strokeWidth="2.5"
                  strokeLinejoin="round"
                />
                <path
                  d="M 390 330 C 405 265, 422 205, 420 165 L 429 165 C 431 205, 415 265, 402 330 Z"
                  fill="#3A4156"
                />
                <ellipse cx="447" cy="165" rx="27" ry="4.5" fill="#1A1F2E" stroke="#1A1F2E" strokeWidth="2" />
                <path d="M 402 262 Q 447 270 490 262" fill="none" stroke="#1A1F2E" strokeWidth="1.8" strokeDasharray="6 3" />
              </g>

              {/* TOWER 3 (xBase 690..810, top 720..780, yTop 150) */}
              <g>
                <path
                  d="M 690 330 C 705 260, 725 195, 720 150 L 780 150 C 775 195, 795 260, 810 330 Z"
                  fill="#2A3142"
                  stroke="#1A1F2E"
                  strokeWidth="2.5"
                  strokeLinejoin="round"
                />
                <path
                  d="M 690 330 C 705 260, 725 195, 720 150 L 730 150 C 735 195, 715 260, 702 330 Z"
                  fill="#3A4156"
                />
                <ellipse cx="750" cy="150" rx="30" ry="5" fill="#1A1F2E" stroke="#1A1F2E" strokeWidth="2" />
                <path d="M 704 252 Q 750 260 796 252" fill="none" stroke="#1A1F2E" strokeWidth="1.8" strokeDasharray="6 3" />
              </g>

              {/* TOWER 4 (xBase 930..1030, top 955..1005, yTop 170) */}
              <g>
                <path
                  d="M 930 330 C 942 270, 957 210, 955 170 L 1005 170 C 1002 210, 1017 270, 1030 330 Z"
                  fill="#2A3142"
                  stroke="#1A1F2E"
                  strokeWidth="2.5"
                  strokeLinejoin="round"
                />
                <path
                  d="M 930 330 C 942 270, 957 210, 955 170 L 963 170 C 965 210, 950 270, 940 330 Z"
                  fill="#3A4156"
                />
                <ellipse cx="980" cy="170" rx="25" ry="4" fill="#1A1F2E" stroke="#1A1F2E" strokeWidth="2" />
                <path d="M 942 264 Q 980 272 1018 264" fill="none" stroke="#1A1F2E" strokeWidth="1.8" strokeDasharray="6 3" />
              </g>
            </g>

            {/* LAYER 5: GROUND — Dark asphalt strip with diagonal hazard stripes */}
            {/* Dark asphalt base (y=330 to 400) */}
            <rect x="0" y="330" width="1200" height="70" fill="#2A2018" stroke="#1A1F2E" strokeWidth="2.5" />

            {/* Facility Gate Barrier Strip with Repeating Diagonal Hazard Stripes */}
            <rect x="0" y="330" width="1200" height="16" fill="url(#hazardStripes)" stroke="#1A1F2E" strokeWidth="2" />

            {/* Inked curb line */}
            <line x1="0" y1="346" x2="1200" y2="346" stroke="#1A1F2E" strokeWidth="2.5" />

            {/* LAYER 6: CREEK — Thin diagonal strip bottom-right, angled slightly */}
            <polygon
              points="880,400 1200,350 1200,400"
              fill={currentTier.creekColor}
              stroke="#1A1F2E"
              strokeWidth="2.5"
              className="transition-colors duration-500"
            />
            {/* Water edge highlight line */}
            <line
              x1="880"
              y1="400"
              x2="1200"
              y2="350"
              stroke={currentTier.creekHighlight}
              strokeWidth="3.5"
              strokeLinecap="round"
              className="transition-colors duration-500"
            />

            {/* LAYER 7: VIGNETTE — Dark edges across canvas rgba(0,0,0,0.35) */}
            <rect
              x="0"
              y="0"
              width="1200"
              height="400"
              fill="black"
              opacity="0.35"
              style={{
                maskImage: 'radial-gradient(ellipse at center, transparent 45%, black 100%)',
                WebkitMaskImage: 'radial-gradient(ellipse at center, transparent 45%, black 100%)',
              }}
              pointerEvents="none"
            />
          </svg>

          {/* CRT Scanline effect overlay on scene */}
          <div className="absolute inset-0 scanlines pointer-events-none opacity-40" />

          {/* HUD Target / Telemetry Reticle in corner */}
          <div className="absolute top-4 left-4 font-mono text-[10px] text-[#F0A500] bg-[#1A1F2E]/80 border border-[#3A4156] px-2.5 py-1 tracking-widest pointer-events-none">
            SCADA CAM 04 &middot; LIVE
          </div>
        </div>

        {/* HHI Slider Controls */}
        <div className="w-full max-w-2xl px-4 flex flex-col items-center">
          <div className="w-full flex justify-between font-mono text-[11px] mb-2 select-none">
            <span className="text-[#CC2200] font-bold tracking-wider">&larr; COLLAPSE</span>
            <span className="text-[#F0A500] font-bold tracking-widest bg-[#252B3B] px-3 py-1 border border-[#3A4156]">
              HHI: {hhi} / 100
            </span>
            <span className="text-[#4A7C59] font-bold tracking-wider">RESTORED &rarr;</span>
          </div>

          {/* Range Slider */}
          <input
            type="range"
            min="0"
            max="100"
            value={hhi}
            onChange={(e) => setHhi(Number(e.target.value))}
            className="w-full h-3 rounded-none appearance-none cursor-pointer border-2 border-[#1A1F2E] accent-[#F0A500]"
            style={{
              background: 'linear-gradient(to right, #CC2200 0%, #F0A500 50%, #4A7C59 100%)',
            }}
            aria-label="Hydro Health Index slider"
          />

          {/* Tier Status Card */}
          <div className="mt-8 text-center flex flex-col items-center max-w-lg">
            <h3
              className="font-heading text-3xl sm:text-4xl tracking-wide transition-colors duration-300"
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
