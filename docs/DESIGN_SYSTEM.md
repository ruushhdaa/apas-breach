# APAS : BREACH — Design System

## COLOR PALETTE
Background:        #090D16
Surface/Panel:     #0F1622
Border:            #1C2A3A
Accent primary:    #00E5FF
Accent warning:    #FFB300
Accent danger:     #FF3D00
Accent green:      #00C853
Text primary:      #E8F0FE
Text secondary:    #7A8FA6
Hazard stripe:     repeating diagonal #FFB300 / #090D16, 4px, 45deg

## WORLD STATE TIERS
HHI 80–100  Restored:   sky #1A3A5C, fog 0.01, steam 20%, creek #2196F3
HHI 60–79   Stressed:   sky #2C3A1A, fog 0.02, steam 50%, creek #78909C
HHI 40–59   Critical:   sky #3A2A0A, fog 0.04, steam 80%, creek #795548
HHI 20–39   Breach:     sky #2A0A0A, fog 0.07, steam 100%, creek #4E342E
HHI 0–19    Collapse:   sky #0A0505, fog 0.10, steam 120%, creek #212121

## EFFECTS
Film grain:     CSS noise overlay, opacity 0.04, animated
Heat shimmer:   SVG feTurbulence displacement on skyline band
Mouse parallax: foreground 1x, midground 0.6x, background 0.3x
Scanlines:      1px horizontal lines, opacity 0.03, over all SCADA panels

## FONTS
Heading:    Bebas Neue (Google Fonts, SIL OFL)
Body/UI:    Inter (Google Fonts, SIL OFL)
Monospace:  JetBrains Mono (Google Fonts, SIL OFL)
Load via Google Fonts. No other typefaces. No system fonts except fallbacks.

## AUDIO RULES
- All audio synthesised via Web Audio API. No audio files. No samples.
- Audio starts ONLY after a user click or tap.
- Default state: muted. User toggles with speaker icon top-right.

### AMBIENT LAYERS
HHI 80–100: Low drone 60Hz sine + 120Hz sub, gentle filter sweep.
            Add distant water flow: white noise, bandpass 400–800Hz.
HHI 60–79:  Add hum 180Hz with subtle distortion. Water fades.
HHI 40–59:  Cooling fan roar: pink noise, filtered. Hum louder.
HHI 20–39:  Alarm pulse 440Hz every 3s. Fan noise dominant.
HHI 0–19:   Harsh klaxon 880Hz, distorted. No water. No calm.

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
Level 5 sunrise: restored = open pads / collapse = static silence
