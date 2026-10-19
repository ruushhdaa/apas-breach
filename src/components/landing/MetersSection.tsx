import React, { useState, useEffect } from 'react';

interface MeterData {
  id: string;
  name: string;
  unit: string;
  color: string;
  baseVal: number;
  format: (v: number) => string;
  range: number;
  desc: string;
}

const metersList: MeterData[] = [
  {
    id: 'water-use',
    name: 'WATER USE',
    unit: 'L per kWh',
    color: '#F0A500',
    baseVal: 3.42,
    range: 0.15,
    format: (v) => v.toFixed(2),
    desc: 'How much water the facility burns per unit of compute. Let this climb and the creek pays the price.',
  },
  {
    id: 'power-draw',
    name: 'POWER DRAW',
    unit: 'kW',
    color: '#F0A500',
    baseVal: 84200,
    range: 350,
    format: (v) => Math.round(v).toLocaleString(),
    desc: 'Total electrical load across all systems. Cut power wrong and you lose the whole stack.',
  },
  {
    id: 'heat-index',
    name: 'HEAT INDEX',
    unit: '°C delta',
    color: '#CC2200',
    baseVal: 14.8,
    range: 0.3,
    format: (v) => `+${v.toFixed(1)}`,
    desc: 'Temperature difference between intake and discharge. Above threshold: regulatory breach. Above critical: system failure.',
  },
  {
    id: 'creek-health',
    name: 'CREEK HEALTH',
    unit: '% baseline',
    color: '#4A7C59',
    baseVal: 64,
    range: 1.5,
    format: (v) => `${Math.round(v)}%`,
    desc: 'What the water downstream looks like right now. This is the number the regulator checks first.',
  },
  {
    id: 'community-trust',
    name: 'COMMUNITY TRUST',
    unit: '0–100',
    color: '#E8E0D0',
    baseVal: 42,
    range: 1,
    format: (v) => `${Math.round(v)}`,
    desc: 'What the neighbourhood outside the fence knows. Once this hits zero, no decision matters anymore.',
  },
  {
    id: 'uptime',
    name: 'UPTIME',
    unit: '%',
    color: '#F0A500',
    baseVal: 99.982,
    range: 0.005,
    format: (v) => `${v.toFixed(2)}%`,
    desc: "The facility's core obligation. Everything else is negotiable. This one almost isn't.",
  },
];

export const MetersSection: React.FC = () => {
  const [hoveredId, setHoveredId] = useState<string | null>(null);
  const [liveValues, setLiveValues] = useState<Record<string, number>>(() => {
    const init: Record<string, number> = {};
    metersList.forEach((m) => {
      init[m.id] = m.baseVal;
    });
    return init;
  });

  // Ticking effect on hover
  useEffect(() => {
    if (!hoveredId) return;

    const interval = setInterval(() => {
      setLiveValues((prev) => {
        const meter = metersList.find((m) => m.id === hoveredId);
        if (!meter) return prev;
        const delta = (Math.random() - 0.5) * 2 * meter.range;
        return {
          ...prev,
          [hoveredId]: meter.baseVal + delta,
        };
      });
    }, 120);

    return () => clearInterval(interval);
  }, [hoveredId]);

  return (
    <section
      id="meters"
      className="relative w-full bg-[#252B3B] py-28 px-4 sm:px-8 border-t border-[#3A4156] overflow-hidden"
    >
      <div className="vignette" />
      <div className="film-grain" />

      <div className="relative z-10 max-w-7xl mx-auto flex flex-col items-center">
        {/* Heading */}
        <h2 className="font-heading text-3xl sm:text-5xl text-[#E8E0D0] text-center tracking-tight">
          SIX NUMBERS. ONE FACILITY.
        </h2>

        {/* Subheading */}
        <p className="mt-4 font-mono text-sm text-[#8A8FA8] text-center max-w-xl mb-16 leading-relaxed">
          Hover a meter to see what it controls.
        </p>

        {/* 3x2 Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 w-full">
          {metersList.map((m) => {
            const isHovered = hoveredId === m.id;
            const currentVal = liveValues[m.id] ?? m.baseVal;

            return (
              <div
                key={m.id}
                onMouseEnter={() => setHoveredId(m.id)}
                onMouseLeave={() => {
                  setHoveredId(null);
                  setLiveValues((prev) => ({ ...prev, [m.id]: m.baseVal }));
                }}
                className={`bg-[#1A1F2E] border-2 p-6 flex flex-col justify-between transition-all duration-200 comic-shadow min-h-[220px] ${
                  isHovered ? 'border-[#F0A500]' : 'border-[#3A4156]'
                }`}
              >
                <div>
                  <div className="flex justify-between items-baseline mb-2">
                    <h3 className="font-heading text-lg sm:text-xl text-[#E8E0D0] tracking-wide">
                      {m.name}
                    </h3>
                    <span className="font-mono text-[11px] text-[#8A8FA8]">
                      {m.unit}
                    </span>
                  </div>

                  {/* Number display */}
                  <div
                    className="font-mono text-3xl sm:text-4xl font-bold tracking-tight my-3"
                    style={{ color: m.color }}
                  >
                    {m.format(currentVal)}
                  </div>
                </div>

                {/* Description on hover */}
                <div
                  className={`transition-opacity duration-300 font-mono text-xs text-[#8A8FA8] leading-relaxed pt-3 border-t border-[#3A4156]/40 ${
                    isHovered ? 'opacity-100' : 'opacity-0'
                  }`}
                >
                  {m.desc}
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
};
