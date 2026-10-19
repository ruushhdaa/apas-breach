# APAS: BREACH — Requirements Document
## A GTA3-Style 3D Browser/Desktop Game

---

## 1. PROJECT OVERVIEW

APAS: BREACH is a third-person 3D game built in Godot 4.
The player is an environmental auditor investigating a hyperscale
data centre in the Thane–Rabale industrial corridor, Maharashtra.
The facility is illegally drawing water from the municipal supply
and dumping thermal effluent into Thane Creek.

The player must gather evidence, make decisions, and survive
five levels of escalating pressure from facility management,
regulators, and the community. Every choice has a consequence
that carries into the next level. The world visually and
audibly changes in response to every major decision.

This game teaches the player — through experience, not lecture —
how data centres affect water supply, creek health, and
community trust. Information is embedded in the world:
on walls, billboards, flyers, lab readouts, and NPC dialogue.
There are no slideshows. There is no "info screen."
You learn by playing.

Target: Godot 4 (Windows)
Genre: Third-person 3D / narrative simulation
Style: GTA III PS2-era visual aesthetic

---

## 2. VISUAL STYLE

Reference: GTA III (PS2, 2001)

- Low-poly flat-shaded geometry, vertex colours
- No PBR, no bloom, no normal maps
- Chunky pixelated look, nearest-neighbour texture filtering
- 64x64 procedural canvas textures only
- Exponential fog, warm haze
- Film grain overlay
- Hard cheap lighting: one directional sun + one ambient
- Slightly desaturated, warm amber tones
- Draw distance: 150 units, fog beyond

Characters:
- 3D low-poly stylised character models, GTA3 proportions
- Generate or source from a free low-poly asset library
  (kenney.nl, opengameart.org, or procedural generation)
- Do NOT use hand-drawn 2D sprites
- Each character has a unique silhouette and colour palette

World changes with HHI (Health + Hydrology Index, 0–100):
- HHI 85–100 RESTORED:    sky #1A3A5C, blue creek, clean steam
- HHI 65–84 RECOVERING:   sky #2C3A1A, pale creek, light haze
- HHI 45–64 STRAINED:     sky #2E2010, murky creek, thick haze
- HHI 25–44 CRITICAL:     sky #1A0A00, brown creek, heavy smog
- HHI 0–24  COLLAPSE:     sky #0A0800, black creek, no steam

All world changes (sky colour, fog, creek colour, steam
particle density) lerp smoothly over 6–8 seconds after
each decision. This is the core feedback loop.

---

## 3. GAME WORLD — LAYOUT

Coordinate system: x east, z south, y up. Units = metres.

ZONES:
- Gate 4 + Gatehouse (0, 0, 50): entry point, boom barrier
- Rabale Colony (z 70–130): chawls, tanker queue, dry tap,
  tea stall, pedestrians
- Creek (x 60–110, z -50..50): Thane Creek, changes colour
  with HHI, mangrove silhouettes at edges
- Outfall Canal (50,0,-20): narrow sunken channel, fume effect
- Municipal Meter Substation (-28,0,44): meter cabinet,
  key interactable in Level 1
- Server Hall A (x -45..-15, z -45..-5): pump gallery inside,
  rack rows, emergency lighting, Level 2 valve puzzle
- Cooling Towers: 4 hyperboloid towers at x=-5,8,21,34 z=-35,
  steam particles scale with HHI
- SCADA Hub (20,0,10): screens visible through windows,
  console inside
- Audit Stage (0,0,58): MPCB vehicle, cones, barrier tape

WORLD DETAILS (information embedded in environment):
- Billboard near Gate 4:
  "AETHERSCALE DATA CENTRE — RABALE, THANE"
  "WATER RECYCLING TARGET: 95% | ACTUAL: 41%"
- Flyer on colony wall (readable up close):
  "6 DAYS WITHOUT TAP WATER — NMMC DO SOMETHING"
- Sticker on cooling tower:
  "EVAPORATIVE COOLING USES 1–5L PER kWh"
- Creek monitoring board:
  "THANE CREEK — FLAMINGO HABITAT (Phoenicopterus roseus)"
  "DISSOLVED OXYGEN MIN. 4mg/L | CURRENT READING: —"
- Server hall poster:
  "PUE TARGET 1.15 | CURRENT PUE: —"
- Outfall warning sign:
  "BLOWDOWN TDS: — ppm | PERMISSIBLE: 2100 ppm"
- Road graffiti:
  "DATA CENTRE TOOK OUR WATER"

All — readouts in the world update live from the
simulation engine. They are not decorative.

---

## 4. THREE PLAYABLE CHARACTERS

Choose one at dispatch screen before Level 1 begins.

---

KABIR "VOLT" RAO
Visual: tall, stocky, hard hat, high-vis vest, dark skin,
        shaved head, amber accent colour
Role: Senior Power Systems Engineer
Perk: Thermal View (Q key) — highlights hot pipes,
      overheating components, hidden heat signatures in orange
Upside: Heat clock in Level 2 runs 20% slower
Downside: Cannot collect water samples (no kit)
Stats: Power 80 / Water 30 / Compliance 50 / Crisis 70

DR. ANANYA SEN
Visual: medium height, lab coat, hair tied back, warm brown skin,
        teal accent colour, sample kit visible on hip
Role: Environmental Compliance Officer
Perk: Sample Kit (Q key) — reads TDS, temperature, DO
      of any water source or pipe in range, logs it as evidence
Upside: Water/creek evidence auto-tagged as verified
Downside: Sprint 10% slower
Stats: Power 20 / Water 90 / Compliance 80 / Crisis 50

TARA "ZERO" D'SOUZA
Visual: slim, hoodie, sneakers, olive skin, olive accent colour,
        laptop bag, always slightly alert posture
Role: SCADA Specialist
Perk: Remote Hack (Q key) — interact with any console
      from 15m away, no need to walk up to it
Upside: Can access valve logs without physical proximity
Downside: Each remote hack adds +5 Audit Pressure
Stats: Power 40 / Water 80 / Compliance 60 / Crisis 40

---

## 5. CONTROLS

Show controls in a tutorial screen before Level 1 (skippable).
Also show a persistent CONTROLS panel in pause menu.

Movement:
  WASD          — Move (relative to camera direction)
  Shift + WASD  — Sprint
  Mouse         — Camera orbit (pointer lock)
  Scroll wheel  — Camera zoom (3–10 units)

Actions:
  E             — Interact / Talk / Open
  Q             — Specialist tool
  H             — Hint (radio message from Meera)
  M             — Toggle large map overlay
  F1            — Dev panel (debug, internal use)
  Esc           — Pause menu

Tutorial flow:
  - Short on-rails walk from spawn to first interactable
  - Each control introduced as needed (WASD → run, E → talk,
    Q → tool, E → interact with cabinet)
  - Can skip entire tutorial with one button
  - Tutorial is Level 0, not a separate screen

---

## 6. HUD LAYOUT

All values live from simulation engine. No fake numbers.

TOP BAR:
  Left:   HHI value + tier label (e.g. "38 — CRITICAL")
          Space Mono, amber #F0A500
  Center: In-game clock (16:30, 19:00, etc.)
  Right:  Level name

RIGHT PANEL (during play):
  Six rows, each: label | live value | delta arrow
  W — Water Draw (MLD)
  P — Power Draw (PUE)
  H — Heat Index (°C)
  C — Creek Health (% baseline DO)
  T — Community Trust (0–100)
  S — Uptime SLA (%)
  Background semi-transparent dark panel

BOTTOM LEFT:
  Radio message area (Meera / Rohan dialogue)
  Portrait placeholder beside text
  Message fades in/out, does not persist

CORNER MINIMAP:
  Bottom right, always visible during play
  Large enough to actually read (200×200px minimum)
  Shows full compound layout from top-down
  Player dot in amber
  Interactables as white dots
  NPCs as grey dots
  Minimap should feel like the GTA III map:
    street-level outlines, zone labels, no satellite texture
  Press M for full-screen map overlay with legend

ACTIVE TIMERS (top-right, when running):
  Scramble Timer: red countdown, pulses under 30s
  Sump Timer: orange countdown
  Evidence counter: 0–6 icons, fills left to right

---

## 7. SIMULATION ENGINE

File: res://scripts/simulation.gd
Pure GDScript, no visual elements, no side effects.

This engine runs every frame and outputs numbers
that drive the HUD, the world, and the level logic.

Constants:
  heat_fraction = 0.985
  latent_heat   = 2.26
  drift         = 0.005

Topology presets (player-changeable via decisions):
  HYBRID_EVAP: evap_share=0.528 aux=0.15 coolant=22 rise=49.5
  DRY:         evap_share=0    aux=0.48 coolant=34 rise=45.8
  DTC:         evap_share=0.45 aux=0.22 coolant=18 rise=46

Water source presets:
  POTABLE: makeup_tds=180 CoC=5.0
  STP:     makeup_tds=650 CoC=3.8

Formulas:
  E_ls     = evap_share × heat_mw / 2.26
  B_ls     = E_ls / (CoC - 1)
  drift_ls = 0.005 × E_ls
  withdrawal = E_ls + B_ls + drift_ls - recovered
  potable_mld = withdrawal × 86.4 / 1000
  Tj       = coolant + rise × (it_load / 100)
  PUE      = (IT + aux×IT + extra_aux + zld_mw) / IT

HHI Formula:
  HHI = 100 × (0.30×water + 0.25×creek +
               0.20×thermal + 0.15×energy + 0.10×trust)

  water   = 1 - clamp(potable_mld / 2.5, 0, 1)
  creek   = 1 - clamp(effluent_mld × toxicity / 0.5, 0, 1)
  thermal = Tj≤75 ? 1 : Tj≥90 ? 0 : 1-(Tj-75)/15
  energy  = clamp((1.6-PUE) / 0.45, 0, 1)
  trust   = Trust / 100

HHI smoothed over 3 seconds (lerp).

Baseline test must pass:
  HYBRID_EVAP + POTABLE + no ZLD:
  PUE=1.150, Tj=71.5°C, potable_mld=2.50

---

## 8. PERSISTENT STATE (carries across all levels)

  sla:      100 (uptime, reduced by load shed decisions)
  trust:    30  (community trust, changed by NPC interactions)
  evidence: 0   (max 6, each piece unlocks audit answers)
  budget:   100 (+ 5 per evidence collected, max 130)
  pressure: 0   (audit pressure, max 100 — triggers bad ending)

---

## 9. LEVEL DESIGN

### LEVEL 1 — METER 4 (16:30, afternoon, HHI starts 38)

Sky: yellow-grey haze, harsh light, 42°C feel

Beat 1: Spawn at Gate 4 (tutorial ends here if played).
  Meera on radio: "You're on a warrant. Reservoir's at 14%.
  Find the meter at the municipal substation."

Beat 2: Walk to tanker queue (-15,0,80).
  Sunita tai (NPC, old woman) standing by queue.
  Press E: "We haven't had tap water in six days.
  The tanker comes once if we're lucky."
  → Trust +5, Evidence +1
  Billboard behind her: "NMMC WATER ALLOCATION — THIS COLONY: 0L"

Beat 3: Walk to substation (-28,0,44).
  Glowing interact indicator on meter cabinet.
  Hold E for 2 seconds: cabinet opens, meter reading ticks up.
  "SCADA shows 5.8 L/s. Meter reads 28.9 L/s. Gap: 23.1 L/s."
  Evidence +1.
  Sign on cabinet: "1 MLD potable = ~500 families/day"

Beat 4: Press Q near pipe behind substation.
  Specialist tool reveals hidden 1200mm bypass pipe.
  Evidence +1.
  Rohan on radio: "Don't touch anything. Paperwork only."

Beat 5: Walk to console. DECISION CARD:

  "UNMETERED BYPASS DETECTED — 28.9 L/s"

  A. CLOSE IT NOW
     Consequences: W↓↓↓ H↑↑↑ T↑ S↓
     Scramble Timer starts: 90 seconds
     (Reach Server Hall A to restore cooling flow or
      towers starve and silicon overheats → Game Over)

  B. THROTTLE COMPUTE 30%
     Consequences: W↓ H↓ S↓↓
     No scramble. Rohan pressure +15.
     Note appears: "Batch jobs delayed. Client SLA at risk."

  C. LOG AND REPORT
     Consequences: T↑↑ Evidence+1 Pressure↓10
     Meera: "Smart. Paper trail before anything else."

World transition: 6 seconds. Debrief card. Level 2 unlocks.

---

### LEVEL 2 — EIGHTY-FIVE (19:00, dusk, floodlights on)

Sky: orange smog. Floodlight cones visible at fence corners.

Beat 1: Rohan on radio: "Pump A seal failed. Server Hall A. Now."

Beat 2: Enter Server Hall A (-15,0,-25).
  Red emergency lights flickering. Pump A has warning light.
  Poster on wall: "COOLING SYSTEM WATER USE: 2.5 MLD/DAY"
  Another: "POTABLE WATER USE INDEX — TARGET: BELOW 1.0 L/kWh"

Beat 3: VALVE PUZZLE
  Three valves in pump gallery: V1, V2, V5.
  Correct order: open V2, then V5, then close V1.
  Volt Q-tool highlights correct valve in thermal orange.
  Wrong order: alarm sound, try again.

Beat 4: HEAT CLOCK starts: Tj rising toward 90°C (top-right).
  Volt slows clock 20%. Hard fail: Tj ≥ 90°C for 20s.
  Game Over: "SILICON MELTDOWN — FACILITY OFFLINE"

Beat 5: Console (-30,0,-25). DECISION CARD:
  "Tj AT 84°C AND RISING"

  A. FLOOD TOWERS WITH MAKEUP WATER
     H↓↓↓ W↑↑↑ C↑ T↓↓
     Creek goes dark immediately. makeupFloodMultiplier = 1.65
     Sign flashes: "EMERGENCY FLOOD: +1.2MLD DRAW"

  B. SHED 20% MORE COMPUTE LOAD
     H↓↓ S↓↓ W↓
     Rohan: "You're killing our SLA."
     Note: "Sensitive data cannot be offshored."

  C. BRING IN DRY BACKUP COOLERS
     H↓ P↑↑↑ W unchanged
     PUE spikes visible in HUD.
     Power meter flashes red.

World transition + debrief. Level 3 unlocks.

---

### LEVEL 3 — BLOWDOWN (23:00, night)

Sky: deep navy. Sodium orange street lights.
Creek: fume/shimmer particle effect rising from canal.

Beat 1: Meera: "Creek DO just dropped to 2.2mg/L. Legal minimum
  is 4. Get to the outfall."
  Creek monitoring board near outfall now shows live reading.

Beat 2: Walk to outfall canal (50,0,-20). Fume effect visible.

Beat 3: Q near canal.
  Ananya reads: TDS 2470ppm / temp 46°C / DO 2.2 mg/L
  Evidence +1. Readings flash on HUD.
  Sign: "DO BELOW 4mg/L — FLAMINGO HABITAT AT RISK"
  Tara can hack valve log remotely from here.

Beat 4: Blowdown valve at (40,0,-20). Press E: seized, needs force.
  Mash E ten times in 3 seconds or it stays stuck.

Beat 5: Console at valve. DECISION CARD:
  "BASIN TDS 2470PPM — OUTFALL RUNNING"

  A. EMERGENCY ZLD ACTIVATION
     C↑↑↑ W↓ P↓↓
     Effluent → 0. Creek improves immediately.
     Budget -20. Sign lights up: "ZLD ONLINE — 0 MLD DISCHARGE"

  B. DILUTE AND DISCHARGE
     C↑ W↑↑ Budget -5
     Creek improves slightly, not compliant.

  C. SEAL THE VALVE AND HOLD
     Sump Timer starts: 4 minutes.
     If unresolved before Level 4 end: Sump Overflow → fail.

World transition + debrief. Level 4 unlocks.

---

### LEVEL 4 — REBUILD (03:00, deep night)

Sky: near black. Single moon. Very sparse audio.

Beat 1: Tara: "Budget window open. Fix the cooling properly."
  Budget shown: 100 + (evidence × 5), max 130.

Beat 2: SCADA hub (20,0,10). Press E at console.
  Three system panels on screen. Press E on each to acknowledge.
  Tara can do this from outside (Q key, 15m range).

Beat 3: Rohan NPC walks toward player.
  "I can make this audit disappear. 50 lakhs. Inspector never
  sees this room."
  Two dialogue options:
  > "Get out." → Pressure +20, Trust +10
  > Walk away  → Pressure +10

Beat 4: Console. DECISION CARD:
  (options cost from Budget; Evidence unlocks permits)

  A. FULL DTC CONVERSION
     Topology → DTC. W↓↓↓ P↓ H↓↓
     Cost: Budget -40. Requires Evidence ≥ 3.
     Sign: "DIRECT-TO-CHIP COOLING: 0.45 L/kWh vs 2.5 EVAP"

  B. HYBRID WITH STP WATER
     waterSource → STP. Potable draw → 0.
     Cost: Budget -20. C↑
     Note: "STP water reuse frees 2.5 MLD/day for colony use."

  C. OPTIMISE EXISTING
     throttle_pct +10. Small gains.
     Cost: Budget -10. Weakest but preserves budget.

If Sump Timer still running from Level 3C:
  URGENT BANNER. Player must pick C immediately
  or lose Budget -20 to emergency fix.

World transition: 8 seconds (largest yet).
Sky, steam, creek all visibly shift.
Simulation numbers update in HUD in real time.
Level 5 unlocks. Throttle auto-restores.

---

### LEVEL 5 — DAWN AUDIT (06:05, sunrise)

Sky colour depends on final HHI:
  HHI ≥ 85: warm golden sunrise #FFB347 → #87CEEB
  HHI 65–84: pale grey-orange
  HHI 45–64: hazy dirty sunrise
  HHI < 45:  flat grey dawn, no colour

Beat 1: Dr. Kulkarni (MPCB inspector NPC) arrives in vehicle.
  Meera: "This is it. Show him what you found."

Beat 2: Walk to audit stage (0,0,58). Press E.

Beat 3: AUDIT SEQUENCE (3 questions):
  Q1: "What was the bypass flow rate?"
     Correct answer available if Evidence ≥ 1
     Correct: Pressure -10 / Wrong/bluff: Pressure +20

  Q2: "What was the creek dissolved oxygen reading?"
     Correct if Evidence ≥ 3
     Correct: Pressure -10 / No answer: Pressure +15

  Q3: "What cooling topology is currently active?"
     Always answerable from sim engine. Neutral.

Beat 4: FINAL DECISION:

  A. FULL DISCLOSURE
     Needs Evidence ≥ 4.
     Trust +20. SLA -10. Facility stays open.
     Best ending if HHI ≥ 65.

  B. PARTIAL DISCLOSURE
     Pressure must be < 60.
     Facility survives. Creek issue unresolved.

  C. WHISTLEBLOW
     Needs Evidence ≥ 5.
     Trust +30. SLA → 0. Facility may be shut.
     Best creek/community outcome.

---

## 10. OUTCOMES + END SCREENS

Final Score = HHI×0.5 + Trust×0.3 + Evidence×5 + (100-Pressure)×0.2

Camera pulls back to wide aerial shot of facility + creek + colony.
Sky settles to outcome colour. Hold for 4 seconds. Then overlay.

RESTORED (≥80):
  "The creek is blue. The colony has water.
   The facility is running clean.
   You did something real tonight."
  Creek: bright blue. Colony lights on.

STRAINED (55–79):
  "The numbers are better. Not good.
   The creek will recover. Eventually."

BREACH (30–54):
  "The facility passed the audit. The creek didn't.
   The tankers are still queuing."

COLLAPSE (<30):
  "The facility is offline. The creek is black.
   The colony is still waiting."

Each ending shows: final HHI, sim numbers, decision summary.
PLAY AGAIN → dispatch screen.

---

## 11. AUDIO SYSTEM

Godot AudioStreamPlayer nodes only.
Synthesised via GDScript AudioStreamGenerator.
Zero external audio files.
Audio starts ONLY after first player input.
Default: muted. Toggle in pause menu.

AMBIENT LAYERS (change with HHI tier):
  85–100: 60Hz sine + water noise bandpass
  65–84:  add 180Hz hum, water fades
  45–64:  pink noise (fan roar), hum louder
  25–44:  440Hz pulse every 3s + fan
  0–24:   880Hz klaxon, distorted, nothing calm

UI SOUNDS (synthesised):
  Decision card opens:  880→660→440Hz, 80ms each
  Option hover:         1200Hz 20ms click
  Option selected:      660→880Hz 200ms
  Wrong valve:          200→80Hz 400ms
  Level complete:       major triad arpeggio 150ms×3
  Game over:            800ms descending tone
  Evidence collected:   300→600Hz chirp
  Rohan dialogue:       lower, slight distortion
  Meera dialogue:       clear mid, warm

---

## 12. FIELD NOTES (accessible from pause menu)

15 entries. All sources marked TODO_VERIFY.
Displayed as in-world readable documents, not a separate screen.
Found on desks, pinned to walls, in clipboards around the facility.

Topics:
  1. Hyperscale data centres: 1–5L per kWh
  2. Evaporative vs air cooling power tradeoff
  3. Thermal discharge and creek temperature
  4. Dissolved oxygen below 4mg/L harms aquatic life
  5. Mumbai metro water stress (critical tier)
  6. Global data centre water use: 200 billion litres/year
  7. ZLD recovers 98% of process water
  8. Thane Creek: flamingo habitat, Phoenicopterus roseus
  9. STP water reuse reduces potable demand
  10. PUE 1.15 is efficient for hot climates
  11. Blowdown TDS: typically 900–3000ppm
  12. Indian data centre capacity doubling every 3 years
  13. CoC (cycles of concentration) affects blowdown volume
  14. Creek DO recovery: weeks after a thermal event
  15. Community trust: non-recoverable once lost

---

## 13. DEV PANEL (F1 key, debug use only)

Fixed overlay, Space Mono 11px, dark background.

Sections:
  SIMULATION: all input sliders + dropdowns, live outputs
  HHI: current value, 5 component bars, manual override,
       tier jump buttons
  GAME STATE: level display, jump buttons 1–5,
              persistent values all editable
  FAIL STATES: toggle Blackout / Sealed / Overflow / Scramble
  AUDIO: mute all, solo each layer

---

## 14. CREDITS SCREEN

Route: main menu > Credits

Text only, same 3D world behind it.
Engine: Godot 4
Visual style: GTA III (Rockstar Games, 2001) — homage only
Assets: generated low-poly 3D, procedural textures
Audio: GDScript AudioStreamGenerator, no samples
Fonts: to be specified
Simulation data: TODO_VERIFY sources

---

## 15. BANNED WORDS

These must never appear in code, UI text, dialogue,
comments, or filenames:

  evs, "environmental studies", capstone, assignment,
  "course project", "college project", "end-sem",
  "project submission", "semester project"

---

## 16. BUILD ORDER (for Antigravity)

Do these in order. Do not skip ahead. Fix errors before continuing.

1. Godot 4 project scaffold, folder structure
2. Simulation engine (simulation.gd), baseline test must pass
3. HHI engine (hhi.gd), tier output verified
4. Game state manager (game_state.gd), all persistent vars
5. World geometry — all zones, props, interactables
6. In-world text — all billboards, signs, readouts
7. Player controller — movement, camera, pointer lock
8. Three character models — sourced or generated, rigged
9. Dispatch screen
10. Tutorial (Level 0)
11. Level 1 complete with decision + consequence
12. Level 2 complete
13. Level 3 complete
14. Level 4 complete
15. Level 5 + all four endings
16. HUD — all panels, live values
17. Minimap — corner + full-screen overlay
18. Audio system
19. Field Notes — 15 entries, in-world placement
20. Dev panel (F1)
21. Credits screen
22. End-to-end playthrough test (all 3 characters)
23. Banned word check — zero violations
24. Final commit

---

END OF REQUIREMENTS