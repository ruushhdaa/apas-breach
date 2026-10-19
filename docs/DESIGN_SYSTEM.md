# APAS : BREACH — Design System
# Visual direction: comic-book noir, gritty industrial graphic novel,
# warm and slightly dirty. NOT cyberpunk. NOT clean SaaS dark mode.

## FONTS
Heading / Title:  Rubik Mono One (Google Fonts, SIL OFL)
Body / UI / HUD:  Space Mono (Google Fonts, SIL OFL)
Remove Bebas Neue, Inter, JetBrains Mono entirely.
Load only Rubik Mono One and Space Mono from Google Fonts in index.html.
No other typefaces. No system fonts except as fallbacks.

## COLOR PALETTE
Background:         #1A1F2E  (blue-grey, not pure black)
Surface/Panel:      #252B3B  (slightly lighter blue-grey)
Border:             #3A4156  (muted steel)
Accent primary:     #F0A500  (amber/gold — the hero color)
Accent secondary:   #C17F24  (darker amber for hover states)
Accent danger:      #CC2200  (muted red, not neon)
Accent good:        #4A7C59  (muted olive green)
Text primary:       #E8E0D0  (warm off-white, never pure white)
Text secondary:     #8A8FA8  (muted blue-grey)
Text accent:        #F0A500  (amber for labels and highlights)
Character outline:  #1A1F2E  (dark, for comic-style SVG fills)
HUD background:     rgba(26, 31, 46, 0.85)
HUD border:         #F0A500

There is NO cyan anywhere. 
Replace every instance of #00E5FF with #F0A500.
Replace every instance of #00C853 with #4A7C59.
Replace every instance of #090D16 with #1A1F2E.
Replace every instance of #0F1622 with #252B3B.
Replace every instance of #1C2A3A with #3A4156.
Replace every instance of #E8F0FE with #E8E0D0.
Replace every instance of #7A8FA6 with #8A8FA8.
Replace every instance of #FFB300 with #F0A500.
Replace every instance of #FF3D00 with #CC2200.

## WORLD STATE TIERS
HHI 80–100  Restored:  sky gradient #2B4A7A top to #F0A500 horizon,
                       fog 0.008, steam 10%, creek warm blue
HHI 60–79   Stressed:  sky #3D3A2A, warm amber haze,
                       fog 0.014, steam 35%, creek murky
HHI 40–59   Critical:  sky #2E2010, orange smog,
                       fog 0.022, steam 60%, creek brown
HHI 20–39   Breach:    sky #1A0A00, deep red-orange tint,
                       fog 0.030, steam 85%, creek dark
HHI 0–19    Collapse:  sky #0A0800, near black with yellow tint,
                       fog 0.040, steam 100%, creek black

## VISUAL EFFECTS
Film grain:    CSS noise overlay, opacity 0.04, animated. KEEP.
Vignette:      Dark edges on every full-width section, 
               radial gradient from transparent center to 
               rgba(10,8,0,0.15) at edges.
Scanlines:     1px horizontal lines, opacity 0.03, over all 
               panel and HUD elements. KEEP.
Heat shimmer:  SVG feTurbulence displacement on skyline. KEEP.
Mouse parallax: foreground 1x, midground 0.6x, background 0.3x. KEEP.
NO cyan glows. NO neon borders. NO bloom effects.
Steam particles: off-white with warm tint #F5F0E8, not pure white.

## CHARACTER STYLE (specialist cards)
Characters must be flat 2D SVG comic-book illustrations.
NOT 3D renders. NOT geometric low-poly shapes. NOT photos.

Rules for every character SVG:
- Bold black outlines, stroke 2.5px, color #1A1F2E
- Flat colour fills only. No gradients. No drop shadows.
- Slightly exaggerated proportions: strong jaw, large hands,
  readable silhouette at 120x120px
- Muted palette matching the color tokens above
- Each character visually distinct at a glance

Volt   — amber #F0A500 tones, engineer vest, stern expression,
          crossed arms or hand on equipment
Ananya — teal-grey tones (#4A6B7A), field jacket, clipboard,
          focused downward expression
Tara   — olive #4A7C59 tones, headset on, sharp side profile,
          hand raised or pointing at a screen

## OVERALL FEELING
Gritty industrial graphic novel.
Warm, slightly dirty, comic-noir.
Think: inked panels, flat colours, amber streetlight, 
industrial haze, hand-lettered signage.
NOT: clean, futuristic, cyberpunk, neon, glowing, SaaS.

## AUDIO RULES (unchanged)
All audio synthesised via Web Audio API. No audio files. No samples.
Audio starts ONLY after a user click or tap.
Default state: muted. Speaker toggle top-right.

### AMBIENT LAYERS
HHI 80–100: Low drone 60Hz sine + 120Hz sub, gentle filter sweep.
            Distant water flow: white noise, bandpass 400–800Hz.
HHI 60–79:  Add hum 180Hz subtle distortion. Water fades.
HHI 40–59:  Cooling fan roar: pink noise filtered. Hum louder.
HHI 20–39:  Alarm pulse 440Hz every 3s. Fan noise dominant.
HHI 0–19:   Harsh klaxon 880Hz distorted. No water. No calm.

### UI SOUNDS
Decision popup opens:  880Hz → 660Hz → 440Hz, 80ms each
Option selected:       1200Hz, 20ms, sharp attack
Wrong choice:          200Hz → 80Hz, 400ms
Correct choice:        660Hz → 880Hz, 200ms
Level complete:        major triad arpeggio, 3 notes, 150ms each
Game over:             long descending tone, 800ms

### LEVEL THEMES
Level 1 (16:30): neutral industrial hum, slow LFO
Level 2 (21:00): tension, faster LFO, minor intervals
Level 3 (02:00): heavy pulse, distorted sub
Level 4 (05:00): sparse silence + single tones
Level 5 sunrise: restored = open warm pads / collapse = static
