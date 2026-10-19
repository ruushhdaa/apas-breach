import React from 'react';

const fieldNotesCards = [
  {
    label: 'WATER USE',
    fact: 'A hyperscale data centre can consume between 1 and 5 litres of water per kilowatt-hour of compute, depending on cooling method and climate.',
    source: 'SOURCE — [TODO_VERIFY]',
  },
  {
    label: 'COOLING SYSTEMS',
    fact: 'Evaporative cooling towers are significantly more water-intensive than air-cooled systems, but they consume far less electricity to achieve the same heat rejection.',
    source: 'SOURCE — [TODO_VERIFY]',
  },
  {
    label: 'THERMAL DISCHARGE',
    fact: 'Warm water discharged into natural waterways raises ambient temperature, reduces dissolved oxygen, and disrupts aquatic ecosystems — a process called thermal pollution.',
    source: 'SOURCE — [TODO_VERIFY]',
  },
];

export const FieldNotes: React.FC = () => {
  return (
    <section
      id="field-notes"
      className="relative w-full bg-[#1A1F2E] py-28 px-4 sm:px-8 border-t border-[#3A4156] overflow-hidden"
    >
      <div className="vignette" />
      <div className="film-grain" />

      <div className="relative z-10 max-w-6xl mx-auto flex flex-col items-center">
        {/* Heading */}
        <h2 className="font-heading text-3xl sm:text-5xl text-[#E8E0D0] text-center tracking-tight">
          FIELD NOTES
        </h2>

        {/* Subheading */}
        <p className="mt-4 font-mono text-[15px] text-[#8A8FA8] text-center max-w-xl mb-16 leading-relaxed">
          The facts behind the fiction. Real data. Real systems. Real consequences.
        </p>

        {/* Three Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 w-full mb-14">
          {fieldNotesCards.map((card) => (
            <div
              key={card.label}
              className="bg-[#252B3B] border-l-4 border-l-[#F0A500] border-y border-r border-[#3A4156] p-6 sm:p-7 flex flex-col justify-between comic-shadow"
            >
              <div>
                <span className="font-mono text-[11px] text-[#F0A500] uppercase tracking-[0.2em] block mb-3 font-bold">
                  {card.label}
                </span>
                <p className="font-mono text-sm text-[#E8E0D0] leading-[1.7] mb-6">
                  {card.fact}
                </p>
              </div>
              <div className="font-mono text-xs text-[#8A8FA8] pt-3 border-t border-[#3A4156]/40">
                {card.source}
              </div>
            </div>
          ))}
        </div>

        {/* VIEW ALL SOURCES button */}
        <button
          type="button"
          onClick={() => window.open('https://github.com/ruushhdaa/apas-breach/blob/main/docs/SPEC.md', '_blank')}
          className="font-mono text-xs uppercase tracking-wider border border-[#3A4156] bg-transparent text-[#8A8FA8] px-7 py-3 hover:border-[#F0A500] hover:text-[#E8E0D0] transition-colors duration-150"
        >
          VIEW ALL SOURCES
        </button>
      </div>
    </section>
  );
};
