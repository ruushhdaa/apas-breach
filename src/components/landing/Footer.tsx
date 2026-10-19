import React from 'react';
import { Link } from 'react-router-dom';

export const Footer: React.FC = () => {
  return (
    <footer className="relative w-full bg-[#1A1F2E] border-t border-[#3A4156] py-8 px-6 sm:px-12 z-20">
      <div className="max-w-7xl mx-auto flex flex-col md:flex-row items-center justify-between gap-6 text-center md:text-left font-mono">
        {/* Left */}
        <div className="text-xs text-[#8A8FA8] uppercase tracking-wider">
          APAS : BREACH
        </div>

        {/* Centre */}
        <div className="flex flex-wrap items-center justify-center gap-4 text-xs text-[#8A8FA8]">
          <a href="#the-situation" className="hover:text-[#E8E0D0] transition-colors">
            Game
          </a>
          <span>|</span>
          <a href="#specialists" className="hover:text-[#E8E0D0] transition-colors">
            Specialists
          </a>
          <span>|</span>
          <a href="#world" className="hover:text-[#E8E0D0] transition-colors">
            World
          </a>
          <span>|</span>
          <a href="#field-notes" className="hover:text-[#E8E0D0] transition-colors">
            Field Notes
          </a>
          <span>|</span>
          <Link to="/credits" className="hover:text-[#E8E0D0] transition-colors">
            Credits
          </Link>
        </div>

        {/* Right */}
        <div className="text-[11px] text-[#8A8FA8] md:text-right leading-relaxed max-w-xs">
          <p>&copy; 2026 &mdash; All audio synthesised.</p>
          <p>No copyrighted assets used.</p>
          <p>Built with React, Three.js, Web Audio API.</p>
        </div>
      </div>
    </footer>
  );
};
