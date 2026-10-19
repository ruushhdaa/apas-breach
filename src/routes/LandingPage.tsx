import React from 'react';
import { Nav } from '../components/landing/Nav';
import { Hero } from '../components/landing/Hero';

export const LandingPage: React.FC = () => {
  return (
    <div className="min-h-screen bg-[#1A1F2E] text-[#E8E0D0] flex flex-col font-mono selection:bg-[#F0A500] selection:text-[#1A1F2E]">
      {/* SECTION 1 — NAV */}
      <Nav />

      {/* SECTION 2 — HERO */}
      <main className="flex-1 w-full">
        <Hero />
      </main>
    </div>
  );
};

export default LandingPage;
