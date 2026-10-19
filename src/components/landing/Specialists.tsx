import React, { useEffect, useRef, useState } from 'react';

interface Specialist {
  name: string;
  role: string;
  accent: string;
  tool: string;
  weakness: string;
  stats: { label: string; value: number }[];
  avatar: React.ReactNode;
}

const specialistsData: Specialist[] = [
  {
    name: 'KABIR "VOLT" RAO',
    role: 'Senior Power Systems Engineer',
    accent: '#F0A500',
    tool: 'Volt can read the facility\'s power draw in real time. He catches energy spikes before they cascade.',
    weakness: 'He will always protect uptime first. Water is not his problem — until it is.',
    stats: [
      { label: 'Power Analysis', value: 80 },
      { label: 'Water Systems', value: 30 },
      { label: 'Compliance', value: 50 },
      { label: 'Crisis Response', value: 70 },
    ],
    avatar: (
      /* Flat 2D Inked Comic Avatar: Volt (Amber vest, stern jaw, crossed arms) */
      <svg viewBox="0 0 120 120" className="w-[120px] h-[120px] border-2 border-[#1A1F2E] bg-[#252B3B]" aria-hidden="true">
        {/* Head & Neck */}
        <polygon points="45,45 75,45 72,70 60,78 48,70" fill="#E8E0D0" stroke="#1A1F2E" strokeWidth="2.5" />
        {/* Hair / Headgear */}
        <polygon points="40,42 45,28 75,28 80,42 70,36 50,36" fill="#1A1F2E" stroke="#1A1F2E" strokeWidth="2.5" />
        {/* Stern Eyebrows & Eyes */}
        <line x1="48" y1="48" x2="56" y2="52" stroke="#1A1F2E" strokeWidth="2.5" />
        <line x1="72" y1="48" x2="64" y2="52" stroke="#1A1F2E" strokeWidth="2.5" />
        <circle cx="53" cy="54" r="1.5" fill="#1A1F2E" />
        <circle cx="67" cy="54" r="1.5" fill="#1A1F2E" />
        {/* Mouth stern line */}
        <line x1="55" y1="66" x2="65" y2="66" stroke="#1A1F2E" strokeWidth="2" />
        {/* Vest Collar / Torso (Amber) */}
        <path d="M35,78 L85,78 L95,120 L25,120 Z" fill="#F0A500" stroke="#1A1F2E" strokeWidth="2.5" />
        {/* Inner Shirt */}
        <polygon points="52,78 68,78 60,95" fill="#3A4156" stroke="#1A1F2E" strokeWidth="2.5" />
        {/* Crossed Arms */}
        <path d="M28,95 L60,110 L92,95 L82,120 L38,120 Z" fill="#C17F24" stroke="#1A1F2E" strokeWidth="2.5" />
        {/* Inked seam accents */}
        <line x1="60" y1="95" x2="60" y2="120" stroke="#1A1F2E" strokeWidth="2" />
      </svg>
    ),
  },
  {
    name: 'DR. ANANYA SEN',
    role: 'Environmental Compliance Officer',
    accent: '#4A6B7A',
    tool: 'Ananya has access to the creek monitoring network. She can see what the facility is doing to the water before the regulator does.',
    weakness: 'She has no authority over operations. She can only advise. You decide.',
    stats: [
      { label: 'Power Analysis', value: 20 },
      { label: 'Water Systems', value: 90 },
      { label: 'Compliance', value: 80 },
      { label: 'Crisis Response', value: 50 },
    ],
    avatar: (
      /* Flat 2D Inked Comic Avatar: Ananya (Teal jacket, focused glasses, clipboard) */
      <svg viewBox="0 0 120 120" className="w-[120px] h-[120px] border-2 border-[#1A1F2E] bg-[#252B3B]" aria-hidden="true">
        {/* Hair */}
        <path d="M38,32 C42,20 78,20 82,32 C86,48 86,60 84,72 L76,68 L78,40 L42,40 L44,68 L36,72 Z" fill="#1A1F2E" stroke="#1A1F2E" strokeWidth="2.5" />
        {/* Face */}
        <polygon points="44,42 76,42 72,70 60,78 48,70" fill="#E8E0D0" stroke="#1A1F2E" strokeWidth="2.5" />
        {/* Glasses */}
        <rect x="46" y="47" width="11" height="9" fill="none" stroke="#4A6B7A" strokeWidth="2.5" />
        <rect x="63" y="47" width="11" height="9" fill="none" stroke="#4A6B7A" strokeWidth="2.5" />
        <line x1="57" y1="51" x2="63" y2="51" stroke="#4A6B7A" strokeWidth="2" />
        <circle cx="51" cy="51" r="1.5" fill="#1A1F2E" />
        <circle cx="68" cy="51" r="1.5" fill="#1A1F2E" />
        {/* Field Jacket (Teal-Grey) */}
        <path d="M30,78 L90,78 L98,120 L22,120 Z" fill="#4A6B7A" stroke="#1A1F2E" strokeWidth="2.5" />
        {/* Clipboard held in hands */}
        <polygon points="45,90 75,90 75,120 45,120" fill="#E8E0D0" stroke="#1A1F2E" strokeWidth="2.5" />
        <line x1="50" y1="98" x2="70" y2="98" stroke="#1A1F2E" strokeWidth="2" />
        <line x1="50" y1="104" x2="68" y2="104" stroke="#1A1F2E" strokeWidth="2" />
        <line x1="50" y1="110" x2="65" y2="110" stroke="#1A1F2E" strokeWidth="2" />
      </svg>
    ),
  },
  {
    name: "TARA \"ZERO\" D'SOUZA",
    role: 'Water Use Efficiency Lead',
    accent: '#4A7C59',
    tool: 'Tara controls the recirculation ratios. She can stretch the water budget further than anyone else — but not forever.',
    weakness: 'Her optimisations take time to kick in. In a fast crisis, she is always one step behind.',
    stats: [
      { label: 'Power Analysis', value: 40 },
      { label: 'Water Systems', value: 80 },
      { label: 'Compliance', value: 60 },
      { label: 'Crisis Response', value: 40 },
    ],
    avatar: (
      /* Flat 2D Inked Comic Avatar: Tara (Olive tones, sharp profile, technical headset) */
      <svg viewBox="0 0 120 120" className="w-[120px] h-[120px] border-2 border-[#1A1F2E] bg-[#252B3B]" aria-hidden="true">
        {/* Head & Neck Profile */}
        <polygon points="48,38 78,38 74,68 62,76 46,72" fill="#E8E0D0" stroke="#1A1F2E" strokeWidth="2.5" />
        {/* Hair - sleek dark cropped */}
        <polygon points="42,36 50,22 82,24 84,42 74,44 64,32 46,36" fill="#1A1F2E" stroke="#1A1F2E" strokeWidth="2.5" />
        {/* Eyes & sharp profile brow */}
        <polygon points="56,46 72,46 66,54" fill="#1A1F2E" />
        <circle cx="64" cy="50" r="1.5" fill="#E8E0D0" />
        {/* Headset arc & earpiece */}
        <path d="M50,26 C68,16 86,28 84,48" fill="none" stroke="#F0A500" strokeWidth="2.5" />
        <rect x="78" y="44" width="8" height="12" fill="#F0A500" stroke="#1A1F2E" strokeWidth="2" />
        <path d="M82,54 L72,62" fill="none" stroke="#F0A500" strokeWidth="2" />
        {/* Olive Uniform & Raised Arm */}
        <path d="M34,76 L86,76 L96,120 L24,120 Z" fill="#4A7C59" stroke="#1A1F2E" strokeWidth="2.5" />
        {/* Pointing Hand Gesture */}
        <polygon points="76,82 94,78 98,92 84,95" fill="#E8E0D0" stroke="#1A1F2E" strokeWidth="2" />
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
      { threshold: 0.25 }
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
        {/* Heading */}
        <h2 className="font-heading text-3xl sm:text-5xl text-[#E8E0D0] text-center tracking-tight">
          CHOOSE YOUR SPECIALIST
        </h2>

        {/* Subheading */}
        <p className="mt-4 font-mono text-[15px] text-[#8A8FA8] text-center max-w-2xl mb-16 leading-relaxed">
          Each specialist sees the facility differently. Each one gives you a different edge — and a different blind spot.
        </p>

        {/* Cards Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 w-full">
          {specialistsData.map((spec) => (
            <div
              key={spec.name}
              className="bg-[#1A1F2E] border-2 border-[#3A4156] p-8 flex flex-col justify-between hover:border-[#F0A500] transition-colors duration-200 comic-shadow group"
            >
              <div>
                {/* Character Avatar */}
                <div className="mb-6 flex justify-center">{spec.avatar}</div>

                {/* Name */}
                <h3
                  className="font-heading text-2xl tracking-wide mb-1"
                  style={{ color: spec.accent }}
                >
                  {spec.name}
                </h3>

                {/* Role */}
                <p className="font-mono text-xs text-[#8A8FA8] uppercase tracking-wider mb-4">
                  {spec.role}
                </p>

                {/* Tool Text */}
                <p className="font-mono text-sm text-[#E8E0D0] leading-relaxed mb-4">
                  {spec.tool}
                </p>

                {/* Weakness */}
                <p className="font-mono text-[13px] text-[#8A8FA8] leading-relaxed mb-8">
                  <span className="text-[#CC2200] font-bold">BLIND SPOT — </span>
                  {spec.weakness}
                </p>
              </div>

              {/* Stat Bars */}
              <div className="space-y-3 pt-4 border-t border-[#3A4156]">
                {spec.stats.map((stat) => (
                  <div key={stat.label}>
                    <div className="flex justify-between font-mono text-[11px] text-[#8A8FA8] mb-1">
                      <span>{stat.label}</span>
                      <span>{stat.value}</span>
                    </div>
                    <div className="w-full h-2 bg-[#3A4156] overflow-hidden">
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
          ))}
        </div>
      </div>
    </section>
  );
};
