import React from 'react';
import { Nav } from '../components/landing/Nav';
import { Hero } from '../components/landing/Hero';
import { TheSituation } from '../components/landing/TheSituation';
import { Specialists } from '../components/landing/Specialists';
import { WorldSection } from '../components/landing/WorldSection';
import { MetersSection } from '../components/landing/MetersSection';
import { FieldNotes } from '../components/landing/FieldNotes';
import { FinalCTA } from '../components/landing/FinalCTA';
import { Footer } from '../components/landing/Footer';

export const LandingPage: React.FC = () => {
  return (
    <div className="min-h-screen bg-[#1A1F2E] text-[#E8E0D0] flex flex-col font-mono selection:bg-[#F0A500] selection:text-[#1A1F2E]">
      {/* 1. NAV */}
      <Nav />

      {/* 2. HERO */}
      <main className="flex-1 w-full">
        <Hero />

        {/* 3. THE SITUATION */}
        <TheSituation />

        {/* 4. SPECIALISTS */}
        <Specialists />

        {/* 5. WORLD */}
        <WorldSection />

        {/* 6. METERS */}
        <MetersSection />

        {/* 7. FIELD NOTES */}
        <FieldNotes />

        {/* 8. FINAL CTA */}
        <FinalCTA />
      </main>

      {/* 9. FOOTER */}
      <Footer />
    </div>
  );
};

export default LandingPage;
