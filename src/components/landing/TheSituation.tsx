import React, { useEffect, useRef, useState } from 'react';

interface TimelineNode {
  time: string;
  title: string;
  desc: string;
}

const timelineData: TimelineNode[] = [
  {
    time: '16:30',
    title: 'SHIFT START',
    desc: 'The cooling towers are running hot. Someone pulled the overflow valve.',
  },
  {
    time: '21:00',
    title: 'FIRST ALARM',
    desc: 'Creek temperature: 4°C above baseline. Regulator is watching.',
  },
  {
    time: '02:00',
    title: 'CRISIS POINT',
    desc: 'Power or water. You cannot save both.',
  },
  {
    time: '05:00',
    title: 'THE DECISION',
    desc: 'One system gets shut down. You choose which one.',
  },
  {
    time: 'SUNRISE',
    title: 'OUTCOME',
    desc: 'What you built tonight is what the city wakes up to.',
  },
];

export const TheSituation: React.FC = () => {
  const [visibleNodes, setVisibleNodes] = useState<number>(0);
  const sectionRef = useRef<HTMLElement>(null);

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting) {
          // Stagger nodes in with 200ms delay
          timelineData.forEach((_, index) => {
            setTimeout(() => {
              setVisibleNodes((prev) => Math.max(prev, index + 1));
            }, index * 200);
          });
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
      id="the-situation"
      className="relative w-full bg-[#1A1F2E] py-28 px-4 sm:px-8 border-t border-[#3A4156] overflow-hidden"
    >
      <div className="vignette" />
      <div className="film-grain" />

      <div className="relative z-10 max-w-6xl mx-auto flex flex-col items-center">
        {/* Top Label */}
        <p className="font-mono text-[11px] text-[#F0A500] tracking-[0.3em] uppercase text-center mb-16 select-none">
          ONE NIGHT. FIVE LEVELS. ONE FACILITY.
        </p>

        {/* Timeline Desktop / Mobile */}
        <div className="w-full relative mb-20">
          {/* Desktop Connecting Line */}
          <div className="hidden lg:block absolute top-[6px] left-[5%] right-[5%] h-[2px] bg-[#3A4156] z-0" />

          {/* Desktop Layout */}
          <div className="hidden lg:grid grid-cols-5 gap-6 relative z-10">
            {timelineData.map((node, i) => {
              const isLit = i < visibleNodes;
              const isEven = i % 2 === 0;

              return (
                <div
                  key={node.time}
                  className={`flex flex-col items-center transition-all duration-500 ${
                    isLit ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4'
                  }`}
                >
                  {/* Node Circle */}
                  <div
                    className={`w-3 h-3 rounded-full border-2 border-[#F0A500] bg-[#1A1F2E] transition-all duration-300 ${
                      isLit ? 'shadow-[0_0_8px_rgba(240,165,0,0.8)] scale-110' : 'opacity-40'
                    }`}
                  />

                  {/* Content below node */}
                  <div className={`mt-6 text-center flex flex-col items-center ${isEven ? 'lg:mt-6' : 'lg:mt-8'}`}>
                    <span className="font-mono text-xs text-[#F0A500] tracking-wider mb-1">
                      {node.time}
                    </span>
                    <h3 className="font-heading text-lg text-[#E8E0D0] tracking-wide mb-2">
                      {node.title}
                    </h3>
                    <p className="font-mono text-[13px] text-[#8A8FA8] leading-relaxed max-w-[210px]">
                      {node.desc}
                    </p>
                  </div>
                </div>
              );
            })}
          </div>

          {/* Mobile Vertical Layout */}
          <div className="lg:hidden relative pl-6 border-l-2 border-[#3A4156] space-y-10 ml-4 sm:ml-8">
            {timelineData.map((node, i) => {
              const isLit = i < visibleNodes;
              return (
                <div
                  key={node.time}
                  className={`relative transition-all duration-500 ${
                    isLit ? 'opacity-100 translate-x-0' : 'opacity-0 -translate-x-4'
                  }`}
                >
                  {/* Left node circle on line */}
                  <div
                    className={`absolute -left-[31px] top-1.5 w-3 h-3 rounded-full border-2 border-[#F0A500] bg-[#1A1F2E] transition-all duration-300 ${
                      isLit ? 'shadow-[0_0_8px_rgba(240,165,0,0.8)] scale-110' : 'opacity-40'
                    }`}
                  />
                  <div>
                    <span className="font-mono text-xs text-[#F0A500] tracking-wider block mb-1">
                      {node.time}
                    </span>
                    <h3 className="font-heading text-base text-[#E8E0D0] tracking-wide mb-1">
                      {node.title}
                    </h3>
                    <p className="font-mono text-[13px] text-[#8A8FA8] leading-relaxed">
                      {node.desc}
                    </p>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Body Text */}
        <p className="font-mono text-[15px] text-[#8A8FA8] leading-[1.8] text-center max-w-[640px] px-4">
          Aqua Processing and Auditing System: BREACH puts you inside a hyperscale data centre facility on the night everything goes wrong. You are the auditor. The meters are live. The river doesn't care about your uptime SLA.
        </p>
      </div>
    </section>
  );
};
