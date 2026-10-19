APAS : BREACH — Build Specification v3
For the Antigravity agent · Author: Rushda · Stack: React + TypeScript + Vite + React Three Fiber + Rapier + Zustand + Web Audio API / Godot 4
0. Instructions to the AI agent (read first)
1.	Build in the phases of section 16. After every phase: run the game, take screenshots, check that phase's acceptance list, fix, then continue. Never write everything in one pass.
2.	Zero external copyrighted material. All audio is synthesised with the Web Audio API. All visuals are procedural geometry, procedural canvas textures and vertex colours, or CC0 assets logged in LICENSES.md. See section 10.
3.	Never invent citations, statistics or quotations. Every real-world fact lives in data/fieldNotes.ts with source set to TODO_VERIFY until a human fills it in.
4.	Every number on screen comes from the simulation engine. No hardcoded HUD values.
5.	Build the Dev Panel (section 15) in phase 1. It is how a human and you verify visuals and audio without playing through.
6.	Known bugs to avoid: triggers placed inside solid colliders; movement in world axes instead of camera axes; stray text or comments inside code; template labels such as CLASS 0VOLT; choices that change nothing; audio started before a user click; decisions that contradict each other across levels.
7.	Make decisions yourself using the defaults in this document. Do not stop to ask questions.
1. Pitch and goals
You are an independent site engineer on one long night, from a 42 °C afternoon to sunrise, inside AetherScale node MAH-04 (fictional, a 100 MW AI data centre in Airoli, Navi Mumbai, May 2027). The facility looks clean but is draining the neighbourhood's drinking water and dumping hot chemical blowdown into Thane Creek.
Every decision changes the physics numbers and the whole world: sky, haze, steam, creek, neighbourhood, people, music. Goals:
•	It plays like a real game: about 40 minutes across 5 levels, with story, tension, failure and retry.
•	The player learns how data centres use and pollute water, through discovery, not lectures.
•	There is no single green button. Every option trades off Water, Power, Heat, Creek, Trust and Uptime.
2. Story
Level	Title	Game clock	Sky and mood
1	Meter 4	16:30	Harsh afternoon, yellow-grey haze, 42 °C
2	Eighty-Five	19:00	Dusk, orange smog, floodlights switch on
3	Blowdown	23:00	Night, sodium light, creek fumes
4	Rebuild	03:00	Deep night, quiet, tense
5	Dawn Audit	06:05	Sunrise colour depends on how well you did
Cast (all fictional): the player (one of three specialists, section 4); Meera Joshi, MPCB field coordinator, your radio voice (text only); Rohan Vaidya, Facility Director, the antagonist who wants the audit to pass quietly; Sunita tai, a resident in the water-tanker queue outside Gate 4, the human face of the shortage; Dr. Kulkarni, the MPCB inspector who arrives at dawn.
Arc: you arrive on a warrant. The reservoir is at 14 percent and tankers queue outside while the facility drinks 2.5 MLD. You expose the theft (L1), survive a cooling failure without wrecking the district (L2), stop the creek dump (L3), rebuild the cooling system within a budget (L4), and face the audit at sunrise (L5). Rohan escalates each level: denial, pressure, sabotage, a bribe attempt.
Each level targets 7 to 9 minutes, made of about 6 beats: arrive, talk, investigate, mini-task, decision, consequence.
3. Core loop
Explore, then Investigate (collect Evidence), then do a physical Task, then see the Preview card, then Decide at a console, then watch a 6 to 8 second World Transition, then read the Debrief card, then move on.
•	Evidence cards are collected by scanning or interacting. They are used in L4 (budget) and L5 (audit answers).
•	Decisions are made at consoles, never in a menu out of nowhere.
•	Every decision has a visible and audible consequence within 10 seconds.
4. Controls, camera, characters
•	WASD move relative to the camera, Shift sprint, mouse orbits the camera (pointer lock on click), E interact, Q specialist tool, H hint radio, M full map, Esc pause.
•	Third-person chase camera, FOV 55, distance 7, height 3.2, smoothed, with collision so walls do not hide the player.
•	Characters (choose on a dispatch screen). Each changes play, not just a label:
o	Kabir Volt Rao, Thermal Specialist. Q shows a thermal view that highlights hot pipes and failing equipment. Heat clock in L2 is 20 percent longer.
o	Dr. Ananya Sen, Hydro-Toxicologist. Q opens a sample kit that reads TDS, temperature and dissolved oxygen of any water or pipe in range. Sprint is 10 percent slower.
o	Tara Zero D'Souza, SCADA Specialist. Q hacks a console from up to 15 m and reveals hidden bypass lines. Each remote use adds a small Audit Pressure cost.
•	Low-poly blocky character models made from primitives, about 300 triangles, stepped 12 fps walk cycle, a colour per specialist.
5. The world (GTA III-inspired look, original content)
Units are metres. x east, z south, y up. Default coordinates; validate them with the reachability test in section 15.
•	Compound: fenced square x -50..50, z -50..50.
•	Gate 4 and gatehouse: (0, 0, 50). Road outside: z 50..70.
•	Rabale colony (neighbourhood): z 70..130, with chawl blocks, a water-tanker queue at (-15, 0, 80), dry public taps, laundry lines, a tea stall, a flyover on the far edge.
•	Creek and mangroves: x 60..110. Concrete canal from the outfall at (50, 0, -20) runs east into the creek.
•	Municipal meter substation: (-28, 0, 44). Level 1 console inside the fence.
•	Server Hall A: x -45..-15, z -45..-5. Hollow building with a real door at (-15, 0, -25) and an interior of rack rows, a corridor and a pump gallery. Level 2 console at (-30, 0, -25) inside.
•	Cooling towers: four, at x = -5, 8, 21, 34 and z = -35. Level 3 valve and sample point at (40, 0, -20), beside the canal.
•	SCADA hub: building at (20, 0, 10), size 16 by 10, console inside at (20, 0, 10). Level 4.
•	Audit stage: (0, 0, 58), outside Gate 4, MPCB vehicle at (8, 0, 62). Level 5.
Render style (important):
•	Render at an internal height of 540 px and upscale with nearest-neighbour filtering for a chunky PS2 look.
•	Flat-shaded low-poly meshes with vertex colours. Textures are 64 by 64 procedural canvas textures with nearest filtering. No PBR maps, no bloom, no glossy materials.
•	Exponential fog (see section 8), gradient sky dome, blob shadows (dark circle decals) under characters and cars, hard-edged cheap lighting.
•	Colour grade: slightly desaturated, warm haze, teal shadows, mild film grain.
•	Props to make the world feel alive: parked cars, auto-rickshaws, tankers, signboards with invented brand names, generators, pipe racks, painted hazard stripes, pedestrians walking loops.
•	Do not copy any real game's map, logos, fonts, UI art, sounds or text. The look is inspired by the era only.
6. Simulation engine (pure TypeScript, no React)
All values are model assumptions chosen to be illustrative. Say so in the in-game Info screen.
Inputs: itLoadMW (100), throttlePct (0 to 50, additive, capped), topology (HYBRID_EVAP, DRY, DTC), waterSource (POTABLE, STP), zld (bool), evapShareOverride (optional), extraAuxMW (0), makeupFloodMultiplier (1), cocOverride (optional), toxicityIndex (1.0).
Constants:
•	Heat fraction 0.985 of IT power. Latent heat 2.26 MJ/kg. Drift 0.5 percent of evaporation.
•	Topology table: HYBRID_EVAP evap share 0.528, aux 0.15 of IT, coolant 22 °C, rise 49.5 °C. DRY evap share 0, aux 0.48, coolant 34, rise 45.8. DTC evap share 0.45, aux 0.22, coolant 18, rise 46.
•	Source table: POTABLE makeup TDS 180 ppm and CoC 5.0. STP makeup TDS 650 ppm and CoC 3.8.
•	ZLD: +45 kWh per m3 of blowdown, 98 percent condensate recovered, salt mass = blowdown m3 times basin TDS in kg per m3.
Formulas: E (L/s) = evap share × heat MW ÷ 2.26. Blowdown B = E ÷ (CoC − 1). Withdrawal = E + B + drift − recovered condensate. Tj = coolant + rise × (IT ÷ 100). PUE = (IT + aux + extraAux + ZLD MW) ÷ IT. WUE potable and total as litres per IT kWh.
Baseline check (must pass as unit tests): HYBRID_EVAP, POTABLE, no ZLD gives PUE 1.150, Tj 71.5, potable 2.50 MLD, consumption 2.00 MLD, blowdown 0.50 MLD, TDS 900 ppm. DTC plus STP plus ZLD gives potable 0.00 MLD, discharge 0.00 MLD, ZLD about 1.1 MW, PUE about 1.23. Note honestly in-game that DTC plus STP still evaporates water at the towers: it saves drinking water, not all water.
Persistent game state, carried across levels: SLA (starts 100), Trust (starts 30), Evidence (0 to 6), Budget (100 plus 5 per Evidence, max 130), Pressure (0 to 100), plus the engine inputs above. Throttle auto-restores after Level 4 completes.
Hydro Health Index (HHI), 0 to 100
HHI = 100 × (0.30 water + 0.25 creek + 0.20 thermal + 0.15 energy + 0.10 trust), each term 0 to 1:
•	water = 1 − clamp(potableMLD ÷ 2.5)
•	creek = 1 − clamp(effluentMLD × toxicityIndex ÷ 0.5)
•	thermal = 1 if Tj ≤ 75, falling linearly to 0 at 90
•	energy = clamp((1.6 − PUE) ÷ 0.45)
•	trust = Trust ÷ 100
The start is about 38. A full remediation is about 95. Tiers: 0 to 24 Collapse, 25 to 44 Critical, 45 to 64 Strained, 65 to 84 Recovering, 85 to 100 Restored. HHI is smoothed over 3 seconds so the world transitions rather than snaps.
7. The five levels and their decisions
Effect notation: W = water draw, P = power or PUE, H = heat, C = creek, T = trust, S = SLA and uptime. Up or down arrows count 1 to 3 steps. Each option below is defensible and teaches something. Never mark an option as obviously stupid.
Level 1: Meter 4 (afternoon)
Beats: talk to Sunita tai in the tanker queue (Trust, Evidence); reach the substation; open the meter cabinet (hold E); scan the pipe to find the unmetered 1,200 mm bypass. Evidence: meter reading 28.9 L/s against SCADA 5.8 L/s, bypass trace, resident testimony.
Decision at the substation console: what to do with the bypass?
•	A. Close it now. W down 3, H up 3 (a 90 second Scramble: reach Server Hall A and restore flow, or the tower basins starve and silicon heats), T up 1, S down 1.
•	B. Throttle batch compute 30 percent and keep the bypass for now. W down 1, H down 1, S down 2.
•	C. Log it and report to MPCB, leave it running. T up 2, Evidence +1, W unchanged, Pressure down 10.
Level 2: Eighty-Five (dusk)
Beats: alarms and Rohan on the radio; enter the hall; Pump A seal fails; a valve-order puzzle (open V2, then V5, then close V1; the order is shown by Q); a Heat Clock rises toward 90 °C. Hard fail if Tj is at or above 90 for 20 seconds.
Decision at the hall console: a stopgap (temporary, final fix is Level 4):
•	A. Flood the towers with makeup water. H down 3 fast, W up 3 (makeup flood multiplier 1.65 for 10 minutes), C up 1, T down 2.
•	B. Shed 20 more percent of load, domestic only. H down 2, S down 2, W down 1. A note explains why moving data abroad is not allowed for sensitive data.
•	C. Bring in-row dry backup coolers. H down 1, P up 3 (extra aux 12 MW, evap share 0.35), W unchanged.
Level 3: Blowdown (night)
Beats: walk to the canal; the outfall pipe is steaming; collect water samples (Dr. Sen reads them directly); read the valve log; find the stuck blowdown valve. Evidence: creek DO 2.2 mg/L (below 4 mg/L), basin TDS 2,470 ppm, discharge 46 °C.
Decision at the outfall valve:
•	A. Dilute with potable water. The TDS reading looks fine, but the same mass of chemicals leaves. W up 2, T down 2, Pressure up 20.
•	B. Isolate the outfall and divert into the retention sump. C down 3. An 8 minute real-time Sump Timer starts; engaging RO or ZLD in Level 4 resets it; if it overflows, C up 2 and Pressure up 20.
•	C. Raise cycles of concentration to 7 and dose more biocide. Discharge volume down 33 percent but toxicity index 1.4. A trap that teaches that fewer litres can mean more harm.
Level 4: Rebuild (pre-dawn)
Beats: restore power to the SCADA hub; a valve-routing circuit puzzle; then the master console where you can simulate combinations before committing (each simulation costs 20 seconds of game clock).
Choose one item per row. Costs are in Budget units.
Row	Options
Cooling	Keep evaporative towers (0), Dry coolers (40), Direct-to-chip liquid (55)
Water source	Potable (0), Treated sewage STP (25)
Effluent	Discharge to creek (0), Zero Liquid Discharge train (35)
Direct-to-chip plus STP plus ZLD costs 115, so it needs at least 3 Evidence (Budget 115 or more). Players who rushed must pick a partial fix and live with the numbers, which is a fair and real trade-off. Reveal the true numbers after commit: potable draw, PUE, junction temperature, creek load, salt cake.
Level 5: Dawn Audit
Beats: Rohan tries to bribe you (refuse and report, refuse, or accept: Trust and Pressure change); Dr. Kulkarni arrives; you walk her through three stations (gate meter, towers, outfall). At each, she asks one question and the answers you can give depend on the Evidence cards you hold. Wrong or empty answers add Pressure. Three questions: why the old PUE of 1.15 hid the harm; why treated sewage water instead of pure dry cooling in a 42 °C city; how you prove the creek is no longer polluted.
Endings by HHI and Pressure: Restored (HHI 85 or more and Pressure under 30), Conditional pass, Penalty and monitoring order, Facility sealed (Pressure 100). Show a final scorecard and a Field Notes summary.
8. World reactivity (HHI tier drives everything)
Tier	Sky and sun	Fog	Tower steam	Creek	Neighbourhood
Collapse	Sulfur yellow, pale disc sun	density 0.040	Dense, 100 percent spawn	Dark brown, foam, dead fish	Long tanker queue, dry taps, empty streets
Critical	Orange-grey haze	0.030	85 percent	Murky brown	Tanker queue, a few people, laundry dry
Strained	Dull amber	0.022	60 percent	Cloudy green-brown	Short queue, taps trickle
Recovering	Blue-grey with warm horizon	0.014	35 percent	Greenish, clearer	Taps run, kids appear
Restored	Clean deep blue to gold sunrise	0.008	10 percent, thin vapour	Clear, reflective, fish visible	No queue, green mangroves, people out
Also react: tower steam particles (instanced low-poly puffs, spawn rate by tier), canal water colour and opacity (0.92 opaque when discharging, 0.25 when clean), mangrove tint, tanker and pedestrian counts, floodlight colour, emergency beacons (on below Strained), ground puddles in the colony, Rohan's radio tone. The clock advances by level, and the dawn gradient at Level 5 uses the current tier.
9. Audio (all synthesised, zero samples)
Use one AudioContext created on the first user click. Master gain -6 dB with a mute toggle.
•	Facility drone: 50 Hz sawtooth through a lowpass at 120 Hz, pitch up to 62 Hz with IT load.
•	Fan and steam layer: filtered noise, bandpass 800 Hz, gain 0.20 at Collapse down to 0.02 at Restored; louder near the towers (distance attenuation).
•	Alarm: square pulses 960 and 720 Hz, enabled in Collapse and Critical, off at Recovering or better.
•	Server hall interior: lowpass at 600 Hz, a 2.8 to 4.2 kHz fan whine, a generated impulse reverb.
•	Creek: bubbling noise bursts when discharging; soft water trickle when clean; night insects and a few synthesised bird chirps at dawn above Recovering.
•	Music: an original generative ambient pad (slow chords, random walk) that enters at Strained and brightens at Restored. A tense low pulse under the heat clock and sump timer. No existing songs or melodies.
•	One-shots: UI click, valve turn, preview-card tick, evidence pickup, success chime (a rising fifth), failure thud, radio squelch (noise burst plus bandpass 300 to 3,400 Hz).
•	Radio lines appear as text with a squelch; no voice recordings.
•	Every decision crossfades the mix over 6 seconds to match the new tier.
10. Copyright-safe assets policy
•	Audio: synthesised in code only. If a sample is ever needed, use CC0 sources only and log them.
•	Visuals: procedural meshes, vertex colours and canvas textures. CC0 packs such as Kenney or Quaternius are allowed if logged in LICENSES.md with URL, author and licence.
•	Fonts: open-licence fonts only (for example Space Mono, Inter, Rubik Mono One from Google Fonts under OFL).
•	Do not use: any real game's name, logos, maps, character likenesses, fonts, mission-complete screens, radio stations or sounds; real company logos; real people. The fictional company AetherScale and invented street brands are fine.
•	Real organisation names (MPCB, MIDC) appear only as neutral, factual references in fictional scenes. Use fictional individuals.
•	Include a Credits and Licences screen in the main menu.
•	If gameplay is recorded for video platforms, the same rules apply. This is general guidance, not legal advice.
11. UI and HUD
•	World look is PS2 low-poly. HUD is sober SCADA: flat rectangular panels, 1 px borders, monospace type (Space Mono or JetBrains Mono), uppercase 10 to 11 px labels, tabular numbers.
•	Top bar: HHI meter with tier name, game clock, level title.
•	Top-left: circular radar minimap with objective arrow and zone labels (rotates with camera).
•	Right: six meters W, P, H, C, T, S, each with an icon, a label, a value and a recent-change arrow. Never rely on colour alone (colour-blind safe).
•	Bottom centre: objective line and interaction prompt. Bottom-left: tool and hint buttons. Evidence tray bottom-right with a count.
•	Palette: background #090D16, panels #0F172A with borders #1E293B, text #F8FAFC, muted #64748B, potable #38BDF8, reclaimed #0D9488, blowdown #78350F, good #10B981, warning #F59E0B, danger #EF4444.
•	Meter changes flash the border for 150 ms (green for better, red for worse).
•	Title screen and dispatch screen use the same sober style over a slow flyover of the 3D compound.
Preview card (before every decision)
Shown when you press E at a console. Compact: one column per option with a short title, one line labelled Expect, a row of six chips (W, P, H, C, T, S) each with an arrow up or down of size small, medium or large, and a tag such as Timed, Irreversible or Temporary. No exact numbers. Buttons: Confirm (Enter) and Back (Esc). Exact numbers appear only in the debrief card after the decision.
12. Hints, failure and checkpoints
•	Hints in 3 stages through Dispatch on the radio: a pulsing waypoint always; after 45 seconds of no progress a text hint; after 90 seconds, pressing H highlights the exact object and explains why.
•	Checkpoints at the start of each level and right before each decision.
•	Hard fails: Tj at or above 90 for 20 seconds (Blackout), Pressure at 100 (Facility sealed), Scramble timer or Sump overflow combined with Pressure 100. A Lesson card explains what went wrong, then Retry from the checkpoint.
•	Soft fails (level continues but cost carries forward): SLA under 60 (Rohan threatens), Trust under 15 (neighbours turn hostile in the world), Evidence under 3 (Budget limits).
•	Never soft-lock. If the player is stuck, the radio gives the next step.
13. Learning layer
•	Field Notes codex: 3 entries unlocked per level, covering PUE vs WUE, withdrawal vs consumption vs discharge, evaporation and blowdown, cycles of concentration, thermal shock and dissolved oxygen, chemical biocides, treated sewage reuse, zero liquid discharge and its energy cost, dry cooling limits in hot climates.
•	Each entry is short (80 words max), shown in the debrief and kept in a codex menu.
•	Every entry in data/fieldNotes.ts has: title, body, source set to TODO_VERIFY, and confidence set to illustrative or verify-before-claiming. The human team replaces TODO_VERIFY with real, checked sources before submission. Do not invent any.
•	An Info screen states which numbers are model assumptions.
14. Architecture
•	src/engine/simulation.ts (pure, tested), src/engine/hhi.ts, src/state/store.ts (Zustand: game state, level progress, evidence, settings).
•	src/data/levels.ts (beats, dialogue, decisions with effects), src/data/fieldNotes.ts, src/data/characters.ts.
•	src/world/ (Compound, ServerHall, Towers, Canal, Colony, Sky, Steam, Water), src/player/ (controller, camera, specialist tools), src/systems/ (triggers, evidence, scramble, sump timer, hints).
•	src/audio/ (engine, layers, mixer), src/ui/ (HUD, Radar, PreviewCard, Debrief, Dispatch, Pause, Codex, Credits).
•	A single store feeds the HUD, the 3D scene and the audio mixer. The 3D scene never computes game numbers.
15. Dev tools and tests
•	Dev Panel on F1: HHI override slider, tier buttons, jump to any level, toggle each fail state, show colliders and trigger zones, show the engine inputs and outputs live, mute and solo audio layers.
•	Unit tests for the engine (baseline and remediated values in section 6).
•	Reachability test: build a walkable grid from the colliders and verify a path from the spawn to every trigger and objective; fail the build if any is unreachable.
•	Performance budget: 60 fps on a mid-range laptop, under 5 MB total, first load under 5 seconds, particles instanced, no per-frame allocations in the hot loop.
•	Desktop keyboard and mouse only; show a friendly message on phones.
16. Build phases and acceptance
1.	Engine, store and Dev Panel (no 3D). Accept: tests pass; moving inputs changes outputs and HHI correctly.
2.	Blockout world, player, camera-relative controls, collisions, low-res PS2 render and fog. Accept: walk from spawn to every zone; reachability test passes; screenshot shows chunky low-poly look.
3.	Level framework: triggers, evidence, preview card, decision, consequences, checkpoints, hard and soft fails. Accept: Level 1 is fully playable and each option visibly changes the HUD.
4.	World reactivity: tier-driven sky, fog, steam, canal, neighbourhood props and people. Accept: with the Dev Panel slider, five screenshots clearly differ per section 8.
5.	Audio engine and mixer. Accept: each tier sounds distinct; mute works; nothing plays before a click.
6.	Levels 2 to 5 with dialogue, puzzles, Field Notes and endings. Accept: a full playthrough in about 40 minutes with at least 3 different endings reachable.
7.	Polish: tutorial in Level 1, Credits and Licences screen, performance pass, deployment build. Stretch only if time remains: a drivable utility cart between zones.
