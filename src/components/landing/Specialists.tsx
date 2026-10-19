import React, { useEffect, useRef, useState } from 'react';
import voltImg from '../../assets/characters/volt.png';
import ananyaImg from '../../assets/characters/ananya.png';
import taraImg from '../../assets/characters/tara.png';

interface Specialist {
  name: string;
  role: string;
  accent: string;
  image: string;
  tool: string;
  weakness: string;
  stats: { label: string; value: number }[];
  backdrop: React.ReactNode;
}

const specialistsData: Specialist[] = [
  {
    name: 'KABIR "VOLT" RAO',
    role: 'Senior Power Systems Engineer',
    accent: '#F0A500',
    image: voltImg,
    tool: "Volt can read the facility's power draw in real time. He catches energy spikes before they cascade.",
    weakness: 'He will always protect uptime first. Water is not his problem — until it is.',
    stats: [
      { label: 'Power Analysis', value: 80 },
      { label: 'Water Systems', value: 30 },
      { label: 'Compliance', value: 50 },
      { label: 'Crisis Response', value: 70 },
    ],
    backdrop: (
      /* Server Rack Shapes */
      <svg className="absolute inset-0 w-full h-full pointer-events-none" viewBox="0 0 280 260" fill="none" preserveAspectRatio="none">
        <rect x="20" y="20" width="65" height="220" fill="#252B3B" stroke="#3A4156" strokeWidth="1" />
        <line x1="20" y1="55" x2="85" y2="55" stroke="#3A4156" strokeWidth="1" />
        <line x1="20" y1="90" x2="85" y2="90" stroke="#3A4156" strokeWidth="1" />
        <line x1="20" y1="125" x2="85" y2="125" stroke="#3A4156" strokeWidth="1" />
        <line x1="20" y1="160" x2="85" y2="160" stroke="#3A4156" strokeWidth="1" />
        <line x1="20" y1="195" x2="85" y2="195" stroke="#3A4156" strokeWidth="1" />

        <rect x="105" y="15" width="70" height="230" fill="#252B3B" stroke="#3A4156" strokeWidth="1" />
        <line x1="105" y1="50" x2="175" y2="50" stroke="#3A4156" strokeWidth="1" />
        <line x1="105" y1="85" x2="175" y2="85" stroke="#3A4156" strokeWidth="1" />
        <line x1="105" y1="120" x2="175" y2="120" stroke="#3A4156" strokeWidth="1" />
        <line x1="105" y1="155" x2="175" y2="155" stroke="#3A4156" strokeWidth="1" />
        <line x1="105" y1="190" x2="175" y2="190" stroke="#3A4156" strokeWidth="1" />

        <rect x="195" y="20" width="65" height="220" fill="#252B3B" stroke="#3A4156" strokeWidth="1" />
        <line x1="195" y1="55" x2="260" y2="55" stroke="#3A4156" strokeWidth="1" />
        <line x1="195" y1="90" x2="260" y2="90" stroke="#3A4156" strokeWidth="1" />
        <line x1="195" y1="125" x2="260" y2="125" stroke="#3A4156" strokeWidth="1" />
        <line x1="195" y1="160" x2="260" y2="160" stroke="#3A4156" strokeWidth="1" />
        <line x1="195" y1="195" x2="260" y2="195" stroke="#3A4156" strokeWidth="1" />
      </svg>
    ),
  },
  {
    name: 'DR. ANANYA SEN',
    role: 'Environmental Compliance Officer',
    accent: '#4A6B7A',
    image: ananyaImg,
    tool: 'Ananya has access to the creek monitoring network. She can see what the facility is doing to the water before the regulator does.',
    weakness: 'She has no authority over operations. She can only advise. You decide.',
    stats: [
      { label: 'Power Analysis', value: 20 },
      { label: 'Water Systems', value: 90 },
      { label: 'Compliance', value: 80 },
      { label: 'Crisis Response', value: 50 },
    ],
    backdrop: (
      /* Horizontal Pipe Shapes with Valve Shapes */
      <svg className="absolute inset-0 w-full h-full pointer-events-none" viewBox="0 0 280 260" fill="none" preserveAspectRatio="none">
        <rect x="0" y="45" width="280" height="26" fill="#252B3B" stroke="#3A4156" strokeWidth="1" />
        <circle cx="70" cy="58" r="16" fill="#252B3B" stroke="#3A4156" strokeWidth="1" />
        <circle cx="70" cy="58" r="7" fill="#1A1F2E" stroke="#3A4156" strokeWidth="1" />

        <rect x="0" y="115" width="280" height="34" fill="#252B3B" stroke="#3A4156" strokeWidth="1" />
        <circle cx="210" cy="132" r="20" fill="#252B3B" stroke="#3A4156" strokeWidth="1" />
        <circle cx="210" cy="132" r="8" fill="#1A1F2E" stroke="#3A4156" strokeWidth="1" />

        <rect x="0" y="185" width="280" height="22" fill="#252B3B" stroke="#3A4156" strokeWidth="1" />
        <circle cx="130" cy="196" r="14" fill="#252B3B" stroke="#3A4156" strokeWidth="1" />

        <line x1="140" y1="10" x2="140" y2="250" stroke="#3A4156" strokeWidth="6" strokeDasharray="16 6" />
      </svg>
    ),
  },
  {
    name: "TARA \"ZERO\" D'SOUZA",
    role: 'Water Use Efficiency Lead',
    accent: '#4A7C59',
    image: taraImg,
    tool: 'Tara controls the recirculation ratios. She can stretch the water budget further than anyone else — but not forever.',
    weakness: 'Her optimisations take time to kick in. In a fast crisis, she is always one step behind.',
    stats: [
      { label: 'Power Analysis', value: 40 },
      { label: 'Water Systems', value: 80 },
      { label: 'Compliance', value: 60 },
      { label: 'Crisis Response', value: 40 },
    ],
    backdrop: (
      /* SCADA Screen Rectangle with Flat Grid Lines */
      <svg className="absolute inset-0 w-full h-full pointer-events-none" viewBox="0 0 280 260" fill="none" preserveAspectRatio="none">
        <rect x="15" y="25" width="250" height="210" fill="#252B3B" stroke="#3A4156" strokeWidth="1" />
        <line x1="15" y1="65" x2="265" y2="65" stroke="#3A4156" strokeWidth="1" />
        <line x1="15" y1="105" x2="265" y2="105" stroke="#3A4156" strokeWidth="1" />
        <line x1="15" y1="145" x2="265" y2="145" stroke="#3A4156" strokeWidth="1" />
        <line x1="15" y1="185" x2="265" y2="185" stroke="#3A4156" strokeWidth="1" />
        <line x1="65" y1="25" x2="65" y2="235" stroke="#3A4156" strokeWidth="1" />
        <line x1="115" y1="25" x2="115" y2="235" stroke="#3A4156" strokeWidth="1" />
        <line x1="165" y1="25" x2="165" y2="235" stroke="#3A4156" strokeWidth="1" />
        <line x1="215" y1="25" x2="215" y2="235" stroke="#3A4156" strokeWidth="1" />
      </svg>
    ),
  },
];

export const Specialists: React.FC = () => {
  const [animateBars, setAnimateBars] = useState<boolean>(false);
  const sectionRef = useRef<HTMLElement>(null);

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting) {
          setAnimateBars(true);
        }
      },
      { threshold: 0.2 }
    );

    if (sectionRef.current) {
      observer.observe(sectionRef.current);
    }

    return () => observer.disconnect();
  }, []);

  return (
    <section
      ref={sectionRef}
      id="specialists"
      className="relative w-full bg-[#252B3B] py-28 px-4 sm:px-8 border-t border-[#3A4156] overflow-hidden"
    >
      <div className="vignette" />
      <div className="film-grain" />

      <div className="relative z-10 max-w-7xl mx-auto flex flex-col items-center">
        {/* Section Heading */}
        <h2 className="font-heading text-3xl sm:text-5xl text-[#E8E0D0] text-center tracking-tight">
          CHOOSE YOUR SPECIALIST
        </h2>

        {/* Subheading */}
        <p className="mt-4 font-mono text-[15px] text-[#8A8FA8] text-center max-w-2xl mb-16 leading-relaxed">
          Each specialist sees the facility differently. Each one gives you a different edge — and a different blind spot.
        </p>

        {/* Cards Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 w-full justify-items-center">
          {specialistsData.map((spec) => (
            <div
              key={spec.name}
              className="w-full max-w-[340px] bg-[#1A1F2E] border border-[#3A4156] hover:border-[#F0A500] transition-colors duration-200 comic-shadow flex flex-col justify-between overflow-hidden"
            >
              {/* TOP 55%: Character Visual with Backdrop Silhouette */}
              <div className="relative w-full h-[270px] bg-[#1A1F2E] flex items-center justify-center overflow-hidden border-b border-[#3A4156]/60">
                {/* Backdrop Silhouette Shapes */}
                {spec.backdrop}

                {/* Hand-drawn Character Art PNG */}
                <img
                  src={spec.image}
                  alt={spec.name}
                  className="relative z-10 w-full h-full object-contain pointer-events-none select-none"
                />
              </div>

              {/* BOTTOM 45%: Information & Stats */}
              <div className="p-6 sm:p-7 flex-1 flex flex-col justify-between">
                <div>
                  {/* Name */}
                  <h3
                    className="font-heading text-[21px] sm:text-[22px] tracking-wide mb-1"
                    style={{ color: spec.accent }}
                  >
                    {spec.name}
                  </h3>

                  {/* Role */}
                  <p className="font-mono text-[11px] text-[#8A8FA8] uppercase tracking-[0.2em] mb-3">
                    {spec.role}
                  </p>

                  {/* Tool text */}
                  <p className="font-mono text-[13px] text-[#E8E0D0] leading-relaxed mt-3 mb-3">
                    {spec.tool}
                  </p>

                  {/* Blind Spot / Weakness */}
                  <p className="font-mono text-[12px] text-[#8A8FA8] leading-relaxed mb-6">
                    <span className="text-[#CC2200] font-bold">BLIND SPOT — </span>
                    {spec.weakness}
                  </p>
                </div>

                {/* 4 Stat Bars */}
                <div className="space-y-3 pt-4 border-t border-[#3A4156]">
                  {spec.stats.map((stat) => (
                    <div key={stat.label}>
                      <div className="flex justify-between font-mono text-[10px] text-[#8A8FA8] mb-1">
                        <span>{stat.label}</span>
                        <span>{stat.value}</span>
                      </div>
                      <div className="w-full h-1 bg-[#3A4156] overflow-hidden">
                        <div
                          className="h-full transition-all duration-1000 ease-out"
                          style={{
                            backgroundColor: spec.accent,
                            width: animateBars ? `${stat.value}%` : '0%',
                          }}
                        />
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};
