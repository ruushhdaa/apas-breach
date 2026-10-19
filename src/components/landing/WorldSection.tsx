import React, { useState, useMemo } from 'react';

interface TierData {
  tierName: string;
  tierColor: string;
  skyTop: string;
  skyMid: string;
  skyBottom: string;
  cityColor: string;
  creekColor: string;
  creekHighlight: string;
  puffsCount: number;
  puffsScale: number;
  puffsOpacity: number;
  desc: string;
}

export const WorldSection: React.FC = () => {
  const [hhi, setHhi] = useState<number>(85); // Default Restored

  const currentTier: TierData = useMemo(() => {
    if (hhi <= 19) {
      return {
        tierName: 'COLLAPSE',
        tierColor: '#CC2200',
        skyTop: '#0A0800',
        skyMid: '#100A00',
        skyBottom: '#2A1500',
        cityColor: '#1A1408',
        creekColor: '#212121',
        creekHighlight: '#333333',
        puffsCount: 3,
        puffsScale: 1.5,
        puffsOpacity: 0.85,
        desc: 'The creek is black. The street is empty. You failed the facility and everything downstream.',
      };
    } else if (hhi <= 39) {
      return {
        tierName: 'BREACH',
        tierColor: '#F0A500',
        skyTop: '#1A0A00',
        skyMid: '#2A1000',
        skyBottom: '#6A2000',
        cityColor: '#3A1808',
        creekColor: '#4E342E',
        creekHighlight: '#6D4C41',
        puffsCount: 3,
        puffsScale: 1.3,
        puffsOpacity: 0.75,
        desc: 'Alarms. Steam pressure critical. The regulator has been notified.',
      };
    } else if (hhi <= 59) {
      return {
        tierName: 'CRITICAL',
        tierColor: '#F0A500',
        skyTop: '#2E2010',
        skyMid: '#3A2A10',
        skyBottom: '#8A4A00',
        cityColor: '#4A3418',
        creekColor: '#795548',
        creekHighlight: '#8D6E63',
        puffsCount: 3,
        puffsScale: 1.1,
        puffsOpacity: 0.65,
        desc: 'Heat stress on the cooling loop. You have maybe two decisions left.',
      };
    } else if (hhi <= 79) {
      return {
        tierName: 'STRESSED',
        tierColor: '#E8E0D0',
        skyTop: '#3D3A2A',
        skyMid: '#4A4030',
        skyBottom: '#C17F24',
        cityColor: '#524E38',
        creekColor: '#546E7A',
        creekHighlight: '#78909C',
        puffsCount: 2,
        puffsScale: 0.9,
        puffsOpacity: 0.55,
        desc: 'The numbers are bad but recoverable. Every choice costs more than it should.',
      };
    } else {
      return {
        tierName: 'RESTORED',
        tierColor: '#4A7C59',
        skyTop: '#2B4A7A',
        skyMid: '#3A5A8A',
        skyBottom: '#C17F24',
        cityColor: '#385C91',
        creekColor: '#2196F3',
        creekHighlight: '#64B5F6',
        puffsCount: 1,
        puffsScale: 0.75,
        puffsOpacity: 0.45,
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

        {/* Interactive World Scene SVG (viewBox="0 0 1200 400") */}
        <div className="w-full h-[280px] sm:h-[400px] border-2 border-[#3A4156] relative overflow-hidden comic-shadow mb-10 select-none">
          <svg
            viewBox="0 0 1200 400"
            className="w-full h-full object-cover"
            preserveAspectRatio="none"
          >
            {/* LAYER 1 — SKY: 3 horizontal flat color bands with semi-hard edges */}
            <rect x="0" y="0" width="1200" height="110" fill={currentTier.skyTop} />
            <rect x="0" y="110" width="1200" height="100" fill={currentTier.skyMid} />
            <rect x="0" y="210" width="1200" height="130" fill={currentTier.skyBottom} />

            {/* LAYER 2 — FAR CITY SILHOUETTE (y=200 to y=260) */}
            <g fill={currentTier.cityColor}>
              <rect x="40" y="220" width="35" height="40" />
              <rect x="80" y="210" width="25" height="50" />
              <rect x="110" y="230" width="45" height="30" />
              <rect x="320" y="215" width="30" height="45" />
              <rect x="355" y="205" width="20" height="55" />
              <rect x="520" y="218" width="55" height="42" />
              <rect x="580" y="210" width="40" height="50" />
              <rect x="625" y="225" width="28" height="35" />
              <rect x="850" y="208" width="32" height="52" />
              <rect x="886" y="218" width="46" height="42" />
              <rect x="1070" y="215" width="38" height="45" />
              <rect x="1115" y="222" width="50" height="38" />
              <line x1="0" y1="260" x2="1200" y2="260" stroke="#1A1F2E" strokeWidth="1" />
            </g>

            {/* LAYER 4 — STEAM PUFFS (Placed over tower tops with flat hard-edged ovals) */}
            {/* Tower 1 Steam (x=180, top y=150, top center=250) */}
            <g transform="translate(250, 150)">
              {currentTier.puffsCount >= 1 && (
                <ellipse cx="0" cy="-14" rx={35 * currentTier.puffsScale} ry={12 * currentTier.puffsScale} fill="#F5F0E8" opacity={0.7 * currentTier.puffsOpacity} />
              )}
              {currentTier.puffsCount >= 2 && (
                <ellipse cx="8" cy="-36" rx={28 * currentTier.puffsScale} ry={10 * currentTier.puffsScale} fill="#F5F0E8" opacity={0.45 * currentTier.puffsOpacity} />
              )}
              {currentTier.puffsCount >= 3 && (
                <ellipse cx="-4" cy="-56" rx={20 * currentTier.puffsScale} ry={8 * currentTier.puffsScale} fill="#F5F0E8" opacity={0.25 * currentTier.puffsOpacity} />
              )}
            </g>

            {/* Tower 2 Steam (x=380, top y=170, top center=440) */}
            <g transform="translate(440, 170)">
              {currentTier.puffsCount >= 1 && (
                <ellipse cx="0" cy="-12" rx={30 * currentTier.puffsScale} ry={10 * currentTier.puffsScale} fill="#F5F0E8" opacity={0.7 * currentTier.puffsOpacity} />
              )}
              {currentTier.puffsCount >= 2 && (
                <ellipse cx="-6" cy="-30" rx={24 * currentTier.puffsScale} ry={9 * currentTier.puffsScale} fill="#F5F0E8" opacity={0.45 * currentTier.puffsOpacity} />
              )}
              {currentTier.puffsCount >= 3 && (
                <ellipse cx="6" cy="-48" rx={18 * currentTier.puffsScale} ry={7 * currentTier.puffsScale} fill="#F5F0E8" opacity={0.25 * currentTier.puffsOpacity} />
              )}
            </g>

            {/* Tower 3 Steam (x=700, top y=160, top center=765) */}
            <g transform="translate(765, 160)">
              {currentTier.puffsCount >= 1 && (
                <ellipse cx="0" cy="-14" rx={32 * currentTier.puffsScale} ry={11 * currentTier.puffsScale} fill="#F5F0E8" opacity={0.7 * currentTier.puffsOpacity} />
              )}
              {currentTier.puffsCount >= 2 && (
                <ellipse cx="6" cy="-34" rx={26 * currentTier.puffsScale} ry={9 * currentTier.puffsScale} fill="#F5F0E8" opacity={0.45 * currentTier.puffsOpacity} />
              )}
              {currentTier.puffsCount >= 3 && (
                <ellipse cx="-5" cy="-52" rx={19 * currentTier.puffsScale} ry={7 * currentTier.puffsScale} fill="#F5F0E8" opacity={0.25 * currentTier.puffsOpacity} />
              )}
            </g>

            {/* Tower 4 Steam (x=940, top y=175, top center=995) */}
            <g transform="translate(995, 175)">
              {currentTier.puffsCount >= 1 && (
                <ellipse cx="0" cy="-10" rx={28 * currentTier.puffsScale} ry={9 * currentTier.puffsScale} fill="#F5F0E8" opacity={0.7 * currentTier.puffsOpacity} />
              )}
              {currentTier.puffsCount >= 2 && (
                <ellipse cx="-4" cy="-26" rx={22 * currentTier.puffsScale} ry={8 * currentTier.puffsScale} fill="#F5F0E8" opacity={0.45 * currentTier.puffsOpacity} />
              )}
              {currentTier.puffsCount >= 3 && (
                <ellipse cx="5" cy="-44" rx={16 * currentTier.puffsScale} ry={6 * currentTier.puffsScale} fill="#F5F0E8" opacity={0.25 * currentTier.puffsOpacity} />
              )}
            </g>

            {/* LAYER 3 — COOLING TOWERS (Trapezoidal hyperboloid towers with highlight and shadow strips) */}
            {/* Tower 1: x=180, y=150, width=140, height=190 (bottom y=340) */}
            <g>
              {/* Main Body */}
              <polygon points="215,150 285,150 320,340 180,340" fill="#252B3B" stroke="#1A1F2E" strokeWidth="2" strokeLinejoin="round" />
              {/* Left Highlight Strip (15% width) */}
              <polygon points="215,150 225,150 201,340 180,340" fill="#3A4156" />
              {/* Right Shadow Strip (10% width) */}
              <polygon points="278,150 285,150 320,340 306,340" fill="#1A1F2E" />
              {/* Rim */}
              <ellipse cx="250" cy="150" rx="35" ry="5" fill="#1A1F2E" stroke="#1A1F2E" strokeWidth="2" />
            </g>

            {/* Tower 2: x=380, y=170, width=120, height=170 */}
            <g>
              <polygon points="410,170 470,170 500,340 380,340" fill="#252B3B" stroke="#1A1F2E" strokeWidth="2" strokeLinejoin="round" />
              <polygon points="410,170 419,170 398,340 380,340" fill="#3A4156" />
              <polygon points="464,170 470,170 500,340 488,340" fill="#1A1F2E" />
              <ellipse cx="440" cy="170" rx="30" ry="4" fill="#1A1F2E" stroke="#1A1F2E" strokeWidth="2" />
            </g>

            {/* Tower 3: x=700, y=160, width=130, height=180 */}
            <g>
              <polygon points="732,160 798,160 830,340 700,340" fill="#252B3B" stroke="#1A1F2E" strokeWidth="2" strokeLinejoin="round" />
              <polygon points="732,160 742,160 719,340 700,340" fill="#3A4156" />
              <polygon points="791,160 798,160 830,340 817,340" fill="#1A1F2E" />
              <ellipse cx="765" cy="160" rx="33" ry="5" fill="#1A1F2E" stroke="#1A1F2E" strokeWidth="2" />
            </g>

            {/* Tower 4: x=940, y=175, width=110, height=165 */}
            <g>
              <polygon points="967,175 1023,175 1050,340 940,340" fill="#252B3B" stroke="#1A1F2E" strokeWidth="2" strokeLinejoin="round" />
              <polygon points="967,175 975,175 956,340 940,340" fill="#3A4156" />
              <polygon points="1017,175 1023,175 1050,340 1039,340" fill="#1A1F2E" />
              <ellipse cx="995" cy="175" rx="28" ry="4" fill="#1A1F2E" stroke="#1A1F2E" strokeWidth="2" />
            </g>

            {/* LAYER 5 — GROUND (Flat horizontal strip: full width, y=340 to y=370, #2A2018) */}
            <rect x="0" y="340" width="1200" height="30" fill="#2A2018" stroke="#1A1F2E" strokeWidth="2" />

            {/* LAYER 6 — CREEK (Flat horizontal strip: right third of scene x=800 to 1200, y=360 to 400) */}
            <rect x="0" y="370" width="800" height="30" fill="#1A1F2E" stroke="#1A1F2E" strokeWidth="1" />
            <rect x="800" y="360" width="400" height="40" fill={currentTier.creekColor} stroke="#1A1F2E" strokeWidth="2" />
            {/* Creek Top Highlight Line */}
            <line x1="800" y1="361" x2="1200" y2="361" stroke={currentTier.creekHighlight} strokeWidth="2" />
          </svg>
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
