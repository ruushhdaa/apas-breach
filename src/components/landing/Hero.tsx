import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';

interface SteamParticle {
  id: number;
  x: number; // percentage
  y: number; // percentage
  size: number;
  speed: number;
  opacity: number;
  drift: number;
}

export const Hero: React.FC = () => {
  const navigate = useNavigate();
  const [parallax, setParallax] = useState<{ x: number; y: number }>({ x: 0, y: 0 });
  const [hasScrolled, setHasScrolled] = useState<boolean>(false);
  const [particles, setParticles] = useState<SteamParticle[]>([]);
  const heroRef = useRef<HTMLDivElement>(null);

  // Parallax tracking
  useEffect(() => {
    const mediaQuery = window.matchMedia('(prefers-reduced-motion: reduce)');
    if (mediaQuery.matches) return;

    const handleMouseMove = (e: MouseEvent) => {
      const { innerWidth, innerHeight } = window;
      const x = (e.clientX / innerWidth - 0.5) * 2; // -1 to 1
      const y = (e.clientY / innerHeight - 0.5) * 2;
      setParallax({ x, y });
    };

    window.addEventListener('mousemove', handleMouseMove);
    return () => window.removeEventListener('mousemove', handleMouseMove);
  }, []);

  // Hide scroll cue on scroll
  useEffect(() => {
    const handleScroll = () => {
      if (window.scrollY > 40) {
        setHasScrolled(true);
      }
    };
    window.addEventListener('scroll', handleScroll, { passive: true });
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  // Steam particles simulation (comic-noir warm tint #F5F0E8)
  useEffect(() => {
    const initialParticles: SteamParticle[] = Array.from({ length: 18 }, (_, i) => ({
      id: i,
      x: 20 + Math.random() * 60,
      y: 35 + Math.random() * 45,
      size: 24 + Math.random() * 48,
      speed: 0.08 + Math.random() * 0.12,
      opacity: 0.04 + Math.random() * 0.06,
      drift: (Math.random() - 0.5) * 0.05,
    }));
    setParticles(initialParticles);

    const interval = setInterval(() => {
      setParticles((prev) =>
        prev.map((p) => {
          let newY = p.y - p.speed;
          let newX = p.x + p.drift;
          let newOpacity = p.opacity;

          // Dissipate as it climbs
          if (newY < 15) {
            newY = 65 + Math.random() * 15;
            newX = 20 + Math.random() * 60;
            newOpacity = 0.04 + Math.random() * 0.06;
          }
          return {
            ...p,
            x: newX,
            y: newY,
            opacity: newOpacity,
          };
        })
      );
    }, 50);

    return () => clearInterval(interval);
  }, []);

  return (
    <section
      ref={heroRef}
      id="hero"
      className="relative min-h-[calc(100vh-65px)] w-full bg-[#1A1F2E] flex flex-col items-center justify-center overflow-hidden px-4 py-16"
    >
      {/* SVG Shimmer Filter Definition */}
      <svg className="absolute w-0 h-0" aria-hidden="true">
        <defs>
          <filter id="heatShimmer" x="-10%" y="-10%" width="120%" height="120%">
            <feTurbulence
              type="turbulence"
              baseFrequency="0.015 0.04"
              numOctaves="2"
              result="turbulence"
            >
              <animate
                attributeName="baseFrequency"
                dur="12s"
                values="0.015 0.04; 0.02 0.07; 0.015 0.04"
                repeatCount="indefinite"
              />
            </feTurbulence>
            <feDisplacementMap in="SourceGraphic" in2="turbulence" scale="7" xChannelSelector="R" yChannelSelector="G" />
          </filter>
        </defs>
      </svg>

      {/* Layer 1 (Back): Flat Inked SVG Cooling Tower Silhouettes (0.3x parallax) */}
      <div
        className="absolute inset-0 pointer-events-none flex items-end justify-center transition-transform duration-300 ease-out z-0"
        style={{
          transform: `translate3d(${parallax.x * 10}px, ${parallax.y * 6}px, 0)`,
        }}
      >
        <svg
          viewBox="0 0 1440 600"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
          className="w-full h-auto max-h-[65vh] object-cover object-bottom"
          preserveAspectRatio="none"
        >
          {/* Background Industrial Skyline Horizon Bar */}
          <rect x="0" y="480" width="1440" height="120" fill="#252B3B" stroke="#3A4156" strokeWidth="2.5" />

          {/* Distant Pylons and Piping */}
          <path d="M120 480 L120 380 L160 380 L160 480" stroke="#3A4156" strokeWidth="2.5" fill="#1A1F2E" />
          <line x1="100" y1="410" x2="180" y2="410" stroke="#3A4156" strokeWidth="2.5" />
          <line x1="110" y1="440" x2="170" y2="440" stroke="#3A4156" strokeWidth="2.5" />

          <path d="M1300 480 L1300 390 L1340 390 L1340 480" stroke="#3A4156" strokeWidth="2.5" fill="#1A1F2E" />
          <line x1="1280" y1="420" x2="1360" y2="420" stroke="#3A4156" strokeWidth="2.5" />

          {/* Cooling Tower 1 (Left-Mid) */}
          <g>
            {/* Tower Body with Inked Hyperboloid */}
            <path
              d="M260 480 C 275 360, 310 240, 320 200 L 440 200 C 450 240, 485 360, 500 480 Z"
              fill="#252B3B"
              stroke="#3A4156"
              strokeWidth="3"
            />
            {/* Top Rim */}
            <ellipse cx="380" cy="200" rx="60" ry="8" fill="#1A1F2E" stroke="#3A4156" strokeWidth="2.5" />
            {/* Inked Panel Seams */}
            <line x1="285" y1="360" x2="475" y2="360" stroke="#3A4156" strokeWidth="2" strokeDasharray="6 4" />
            <line x1="305" y1="280" x2="455" y2="280" stroke="#3A4156" strokeWidth="2" />
          </g>

          {/* Cooling Tower 2 (Center-Left) */}
          <g>
            <path
              d="M540 480 C 555 350, 585 220, 595 170 L 725 170 C 735 220, 765 350, 780 480 Z"
              fill="#252B3B"
              stroke="#3A4156"
              strokeWidth="3.5"
            />
            <ellipse cx="660" cy="170" rx="65" ry="9" fill="#1A1F2E" stroke="#3A4156" strokeWidth="2.5" />
            <line x1="565" y1="350" x2="755" y2="350" stroke="#3A4156" strokeWidth="2" strokeDasharray="8 4" />
            <line x1="585" y1="260" x2="735" y2="260" stroke="#3A4156" strokeWidth="2" />
          </g>

          {/* Cooling Tower 3 (Center-Right) */}
          <g>
            <path
              d="M820 480 C 835 350, 865 220, 875 180 L 1005 180 C 1015 220, 1045 350, 1060 480 Z"
              fill="#252B3B"
              stroke="#3A4156"
              strokeWidth="3.5"
            />
            <ellipse cx="940" cy="180" rx="65" ry="9" fill="#1A1F2E" stroke="#3A4156" strokeWidth="2.5" />
            <line x1="845" y1="350" x2="1035" y2="350" stroke="#3A4156" strokeWidth="2" strokeDasharray="8 4" />
            <line x1="865" y1="270" x2="1015" y2="270" stroke="#3A4156" strokeWidth="2" />
          </g>

          {/* Cooling Tower 4 (Far Right) */}
          <g>
            <path
              d="M1100 480 C 1115 370, 1145 250, 1155 210 L 1265 210 C 1275 250, 1305 370, 1320 480 Z"
              fill="#252B3B"
              stroke="#3A4156"
              strokeWidth="3"
            />
            <ellipse cx="1210" cy="210" rx="55" ry="7" fill="#1A1F2E" stroke="#3A4156" strokeWidth="2.5" />
            <line x1="1125" y1="370" x2="1295" y2="370" stroke="#3A4156" strokeWidth="2" strokeDasharray="6 4" />
          </g>
        </svg>
      </div>

      {/* Layer 2 (Mid): Drifting Steam Particles (0.6x parallax) */}
      <div
        className="absolute inset-0 pointer-events-none overflow-hidden z-10"
        style={{
          transform: `translate3d(${parallax.x * 18}px, ${parallax.y * 12}px, 0)`,
        }}
      >
        {particles.map((p) => (
          <div
            key={p.id}
            className="absolute rounded-full pointer-events-none blur-md transition-opacity duration-300"
            style={{
              left: `${p.x}%`,
              top: `${p.y}%`,
              width: `${p.size}px`,
              height: `${p.size}px`,
              backgroundColor: '#F5F0E8', // Off-white with warm tint
              opacity: p.opacity,
              filter: 'blur(10px)',
            }}
          />
        ))}
      </div>

      {/* Layer 3 (Front): Heat Shimmer Band over the skyline */}
      <div
        className="absolute bottom-16 left-0 right-0 h-40 pointer-events-none z-20 opacity-70"
        style={{
          filter: 'url(#heatShimmer)',
        }}
      />

      {/* Layer 4: Vignette Overlay */}
      <div className="vignette" />

      {/* Layer 5: Film Grain Overlay */}
      <div className="film-grain" />

      {/* Centered Content (Foreground 1.0x parallax) */}
      <div
        className="relative z-30 max-w-4xl mx-auto text-center flex flex-col items-center justify-center my-auto px-4"
        style={{
          transform: `translate3d(${parallax.x * 25}px, ${parallax.y * 18}px, 0)`,
        }}
      >
        {/* Title: Rubik Mono One in #E8E0D0 with #F0A500 for the colon */}
        <h1 className="font-heading text-4xl sm:text-6xl md:text-7xl lg:text-8xl tracking-tight text-[#E8E0D0] leading-none select-none drop-shadow-md">
          APAS <span className="text-[#F0A500]">:</span> BREACH
        </h1>

        {/* Tagline: Space Mono, 20px, #8A8FA8, mt-4 */}
        <div className="mt-4 font-mono text-base sm:text-xl text-[#8A8FA8] leading-relaxed">
          <p>The cloud runs on water.</p>
          <p>Someone is paying for it.</p>
        </div>

        {/* Subline: Space Mono, 14px, #8A8FA8, opacity 0.7, mt-2 */}
        <p className="mt-2 font-mono text-xs sm:text-sm text-[#8A8FA8]/70 tracking-wide">
          You have one shift. Five decisions. No green button.
        </p>

        {/* PLAY NOW button: Amber #F0A500, Rubik Mono One, comic shadow & amber glow */}
        <button
          type="button"
          onClick={() => navigate('/play')}
          className="mt-10 font-heading text-base sm:text-xl tracking-wider bg-[#F0A500] text-[#1A1F2E] px-8 sm:px-12 py-3.5 sm:py-4 border-2 border-[#1A1F2E] comic-shadow animate-amber-pulse hover:bg-[#C17F24] transition-colors focus:outline-none focus:ring-2 focus:ring-[#F0A500]"
        >
          PLAY NOW
        </button>
      </div>

      {/* Scroll cue at bottom center */}
      <div
        className={`absolute bottom-6 left-1/2 -translate-x-1/2 z-30 font-mono text-[11px] tracking-widest text-[#8A8FA8] transition-opacity duration-500 select-none ${
          hasScrolled ? 'opacity-0 pointer-events-none' : 'opacity-80 animate-pulse'
        }`}
      >
        &darr; THE SITUATION
      </div>
    </section>
  );
};
