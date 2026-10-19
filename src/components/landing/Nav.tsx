import React, { useState, useEffect } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { audioManager } from '../../game/audio/audioManager';

export const Nav: React.FC = () => {
  const navigate = useNavigate();
  const [isMuted, setIsMuted] = useState<boolean>(true);
  const [mobileMenuOpen, setMobileMenuOpen] = useState<boolean>(false);

  useEffect(() => {
    const unsubscribe = audioManager.subscribe((muted) => {
      setIsMuted(muted);
    });
    return unsubscribe;
  }, []);

  const handleAudioToggle = () => {
    audioManager.toggleMute();
  };

  const navLinks = [
    { label: 'Game', href: '#the-situation', isRoute: false },
    { label: 'Specialists', href: '#specialists', isRoute: false },
    { label: 'World', href: '#world', isRoute: false },
    { label: 'Field Notes', href: '#field-notes', isRoute: false },
    { label: 'Credits', href: '/credits', isRoute: true },
  ];

  return (
    <nav className="sticky top-0 z-50 w-full bg-[#1A1F2E]/90 backdrop-blur-md border-b-2 border-[#3A4156] px-4 sm:px-8 py-3 transition-colors duration-200">
      <div className="max-w-7xl mx-auto flex items-center justify-between">
        {/* Left: Wordmark in Rubik Mono One, amber #F0A500 */}
        <Link
          to="/"
          className="font-heading text-lg sm:text-2xl text-[#F0A500] tracking-wider hover:text-[#C17F24] transition-colors focus:outline-none"
          aria-label="APAS BREACH Home"
        >
          APAS : BREACH
        </Link>

        {/* Centre: Nav links in Space Mono, #8A8FA8 hover #E8E0D0 */}
        <div className="hidden md:flex items-center space-x-6 font-mono text-xs tracking-wider">
          {navLinks.map((link) =>
            link.isRoute ? (
              <Link
                key={link.label}
                to={link.href}
                className="text-[#8A8FA8] hover:text-[#E8E0D0] transition-colors uppercase"
              >
                {link.label}
              </Link>
            ) : (
              <a
                key={link.label}
                href={link.href}
                className="text-[#8A8FA8] hover:text-[#E8E0D0] transition-colors uppercase"
              >
                {link.label}
              </a>
            )
          )}
        </div>

        {/* Right: Speaker toggle & PLAY NOW CTA & Mobile Hamburger */}
        <div className="flex items-center space-x-3 sm:space-x-5">
          {/* Speaker Toggle Button */}
          <button
            type="button"
            onClick={handleAudioToggle}
            aria-label={isMuted ? 'Unmute ambient audio' : 'Mute ambient audio'}
            title={isMuted ? 'Click to enable ambient audio (Web Audio API)' : 'Audio active'}
            className="p-2 border border-[#3A4156] bg-[#252B3B] hover:border-[#F0A500] focus:outline-none transition-colors"
          >
            {isMuted ? (
              /* Crossed speaker icon (#8A8FA8) */
              <svg
                className="w-4 h-4 text-[#8A8FA8] hover:text-[#E8E0D0] transition-colors"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                strokeWidth={2}
                aria-hidden="true"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M5.586 15H4a1 1 0 01-1-1v-4a1 1 0 011-1h1.586l4.707-4.707C10.923 3.663 12 4.109 12 5v14c0 .891-1.077 1.337-1.707.707L5.586 15z"
                />
                <line
                  x1="3"
                  y1="3"
                  x2="21"
                  y2="21"
                  stroke="currentColor"
                  strokeWidth="2.5"
                  strokeLinecap="round"
                />
              </svg>
            ) : (
              /* Active speaker icon (#F0A500) */
              <svg
                className="w-4 h-4 text-[#F0A500] hover:text-[#E8E0D0] transition-colors"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                strokeWidth={2}
                aria-hidden="true"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M15.536 8.464a5 5 0 010 7.072m2.828-9.9a9 9 0 010 12.728M5.586 15H4a1 1 0 01-1-1v-4a1 1 0 011-1h1.586l4.707-4.707C10.923 3.663 12 4.109 12 5v14c0 .891-1.077 1.337-1.707.707L5.586 15z"
                />
              </svg>
            )}
          </button>

          {/* PLAY NOW button: Rubik Mono One, #F0A500 bg, #1A1F2E text, hover #C17F24 */}
          <button
            type="button"
            onClick={() => navigate('/play')}
            className="font-heading text-xs sm:text-sm tracking-wider bg-[#F0A500] text-[#1A1F2E] px-4 sm:px-5 py-2 hover:bg-[#C17F24] transition-colors duration-150 border-2 border-[#1A1F2E] comic-shadow-sm focus:outline-none"
          >
            PLAY NOW
          </button>

          {/* Mobile Hamburger toggle */}
          <button
            type="button"
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className="md:hidden p-2 text-[#8A8FA8] hover:text-[#E8E0D0] border border-[#3A4156] bg-[#252B3B] focus:outline-none"
            aria-label="Toggle mobile menu"
            aria-expanded={mobileMenuOpen}
          >
            <svg
              className="w-5 h-5"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              {mobileMenuOpen ? (
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M6 18L18 6M6 6l12 12"
                />
              ) : (
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M4 6h16M4 12h16M4 18h16"
                />
              )}
            </svg>
          </button>
        </div>
      </div>

      {/* Mobile Dropdown Menu */}
      {mobileMenuOpen && (
        <div className="md:hidden mt-3 pt-3 border-t-2 border-[#3A4156] flex flex-col space-y-2 font-mono text-xs px-2 pb-2">
          {navLinks.map((link) =>
            link.isRoute ? (
              <Link
                key={link.label}
                to={link.href}
                onClick={() => setMobileMenuOpen(false)}
                className="text-[#8A8FA8] hover:text-[#E8E0D0] py-1 transition-colors uppercase"
              >
                {link.label}
              </Link>
            ) : (
              <a
                key={link.label}
                href={link.href}
                onClick={() => setMobileMenuOpen(false)}
                className="text-[#8A8FA8] hover:text-[#E8E0D0] py-1 transition-colors uppercase"
              >
                {link.label}
              </a>
            )
          )}
        </div>
      )}
    </nav>
  );
};
