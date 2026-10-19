import React from 'react';
import { Nav } from '../components/landing/Nav';
import { Footer } from '../components/landing/Footer';

export const CreditsPage: React.FC = () => {
  return (
    <div className="min-h-screen bg-[#1A1F2E] text-[#E8E0D0] flex flex-col font-mono selection:bg-[#F0A500] selection:text-[#1A1F2E]">
      <Nav />

      <main className="flex-1 max-w-4xl mx-auto w-full py-28 px-6 sm:px-8">
        <h1 className="font-heading text-3xl sm:text-5xl text-[#E8E0D0] mb-16 tracking-tight">
          CREDITS &amp; LICENCES
        </h1>

        <div className="space-y-12">
          {/* Section 1 */}
          <div>
            <h2 className="font-heading text-lg sm:text-xl text-[#F0A500] tracking-wider mb-3">
              BUILT WITH
            </h2>
            <p className="font-mono text-sm text-[#8A8FA8] leading-relaxed">
              React &middot; TypeScript &middot; Vite &middot; Three.js &middot; React Three Fiber &middot; Tailwind CSS &middot; Zustand &middot; Web Audio API
            </p>
          </div>

          {/* Section 2 */}
          <div>
            <h2 className="font-heading text-lg sm:text-xl text-[#F0A500] tracking-wider mb-3">
              FONTS
            </h2>
            <p className="font-mono text-sm text-[#8A8FA8] leading-relaxed">
              Rubik Mono One &mdash; SIL Open Font Licence
              <br />
              Space Mono &mdash; SIL Open Font Licence
            </p>
          </div>

          {/* Section 3 */}
          <div>
            <h2 className="font-heading text-lg sm:text-xl text-[#F0A500] tracking-wider mb-3">
              AUDIO
            </h2>
            <p className="font-mono text-sm text-[#8A8FA8] leading-relaxed">
              All audio is synthesised in-browser via Web Audio API. No audio samples or licensed tracks were used.
            </p>
          </div>

          {/* Section 4 */}
          <div>
            <h2 className="font-heading text-lg sm:text-xl text-[#F0A500] tracking-wider mb-3">
              ASSETS
            </h2>
            <p className="font-mono text-sm text-[#8A8FA8] leading-relaxed">
              No third-party images, textures or models were used. All visual elements are generated in code.
            </p>
          </div>

          {/* Section 5 */}
          <div>
            <h2 className="font-heading text-lg sm:text-xl text-[#F0A500] tracking-wider mb-3">
              DATA &amp; FACTS
            </h2>
            <p className="font-mono text-sm text-[#8A8FA8] leading-relaxed">
              Field Notes facts are sourced from publicly available research. Numbers used in simulation are model assumptions for illustrative purposes and are labelled as such in-game.
            </p>
          </div>

          {/* Section 6 */}
          <div>
            <h2 className="font-heading text-lg sm:text-xl text-[#F0A500] tracking-wider mb-3">
              REFERENCE INSPIRATION
            </h2>
            <p className="font-mono text-sm text-[#8A8FA8] leading-relaxed">
              Visual tone inspired by early 2000s open-world games. No assets, characters, maps, fonts, music or trademarks from any commercial game were used or reproduced.
            </p>
          </div>
        </div>
      </main>

      <Footer />
    </div>
  );
};

export default CreditsPage;
