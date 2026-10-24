# Merge Conflict

A first-person office comedy built with **Godot 4.7.2 and GDScript**. You are a software engineering intern at Small Batch, where coffee is critical infrastructure and every quick question has a follow-up meeting.

## Play

[Play in your browser](https://ryanchan339.github.io/merge-conflict/) on a desktop or laptop with a keyboard and mouse. The first load downloads about 41 MB. Click the clock-in response to start. If an embedded browser cannot capture the mouse, use WASD to walk and the arrow keys or hold the right mouse button to look.

Double-click **Start Game.cmd** in this folder. The portable Godot engine is already downloaded on this computer; no installation is needed. On another Windows computer, the launcher downloads the same official engine on its first run.

To edit the game, import `project.godot` into Godot, or run:

```powershell
& '.tools\godot\Godot_v4.7.2-stable_win64.exe' --editor --path .
```

## Controls

| Control | Action |
| --- | --- |
| WASD / arrow keys | Walk |
| Mouse | Look |
| Shift | Sprint |
| E / left click | Interact with the object under the crosshair |
| Mouse click while seated | Use buttons on the actual computer monitor |
| F | Drink a held coffee |
| Wheel / up and down / drag | Scroll Loop on your phone |
| Click / 1, 2, 3 | Choose a dialogue response |
| Enter | Continue after feedback |
| Escape | Put down the phone, stand up from the desk, or pause while walking |

Follow the objective at the upper left. Approach a person or object and look at it to see its action. Delivery, quality, trust, and energy stay visible at the top, including during conversations and phone use. Choices use full sentences. Coworkers turn toward you, and dialogue leaves their face visible beside the choices. For your 1:1, interact with the visitor chair or Jordan to sit across the desk, then stand automatically when the meeting ends.

At your desk, interact with the chair or workstation to sit down. Click choices directly on the 3D monitor. The screen's **Loop** button picks up your phone; you can also approach the physical phone on the desk. Scroll the fictional short-video feed, like a clip, and put it down to return to work. Every five posts costs ten game minutes and two delivery points.

In the kitchenette, open the refrigerator and slide out the drawer. Take a cup from the counter or open drawer, put it under the coffee machine, wait for it to brew, pick it up, and press **F** to drink. The first coffee restores 12 energy. The objective tracks your next step.

Alex in People Operations handles optional complaints about lunch theft, meeting behavior, and crunch. Your approach changes time and stats, and the report appears in your evaluation history. Filing a complaint does not skip your current assignment, and repeating it cannot farm rewards.

Explore the office to clear the printer jam, vend and pick up a snack, get water, organize the whiteboard, and water the plant. These objects animate when used. Small stat benefits apply once per day.

## The prototype

One compressed **final internship day**, taking roughly 10–15 minutes depending on reading and exploration:

1. Give your standup update.
2. Walk to Maya's desk and clarify an ambiguous feature.
3. Sit at your workstation and click an instruction for BatchGPT on the monitor.
4. Ask Maya about review feedback, then decide how thoroughly to test.
5. Help Sam, or protect your own deadline.
6. Meet Jordan for your 1:1: own a mistake and choose project scope.
7. Make a coffee, then decide whether to rest or work late.
8. Respond to a severity page: sprint to your desk and solve an accessible incident puzzle.
9. Head to the elevator for your evaluation.

Choices change **delivery, quality, trust, and energy**. Energy below 25 slows your sprint. The pager gives you 45 seconds to reach your workstation; dialogue and the pause menu stop the clock. Missing the deadline costs trust and triggers a teammate's intervention, but you can still finish the incident and the day.

Possible outcomes are **fired, no return offer, return offer, and an upleveled return offer**. The highest offer requires strong results plus clarification and testing. Feedback names the consequences of each choice; the evaluation recalls your recent decisions.

The AI assistant is authored satire with predefined outcomes. There is no live model, API key, real code execution, or programming knowledge requirement. Coworkers currently remain at their stations. This is a single-day vertical slice, with restart rather than a multi-day save system. The latest evaluation is recorded in Godot's user-data directory as `last_evaluation.json`.

## Project layout

| File | Purpose |
| --- | --- |
| `scripts/main.gd` | Workday progression, interactions, consequences, pager, evaluation |
| `scripts/office.gd` | Procedural office geometry, furniture, coworkers, targets |
| `scripts/player.gd` | First-person movement, camera, collision, interaction ray |
| `scripts/hud.gd` | Minimal objectives, compact dialogue, pause, evaluation |
| `scripts/workstation.gd` | Interactive desktop rendered onto the physical monitor |
| `scripts/phone.gd` | Loop, a local animated short-video feed |
| `scripts/office_map.gd` | Optional floor-map component, hidden in the minimal HUD |
| `content/story.gd` | Editable dialogue, choices, effects, offer rules |

All art is built from simple geometry and materials; no external asset pack is required. The renderer uses OpenGL Compatibility with 2× MSAA. The bundled [Inter font](assets/fonts/README.md) uses the SIL Open Font License.

## Web deployment

GitHub Pages serves a single-threaded Godot Web export. The **Deploy game to GitHub Pages** workflow exports and publishes every push to `main`; it can also be run manually from Actions. The repository's Pages source is GitHub Actions. There is no backend or API key.

To create the same build locally:

```powershell
./tools/export-web.ps1
```

The installer downloads matching Godot 4.7.2 tools and verifies the official SHA512 checksums. It extracts the web templates from the full template archive on its first run. Serve `build/web` through a local HTTP server to test; opening the HTML file directly will not work. WebGL 2 is required. The evaluation save stays in that browser's local storage.

## Verify

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\test.ps1
```

The checks cover importing the project, complete workday progression, decision paths and ending boundaries, connected walkable floor space, physical monitor clicks, seating, phone scrolling, coffee preparation, and keyboard input.

To capture the actual rendered game screens into the ignored `artifacts` folder:

```powershell
& '.tools\godot\Godot_v4.7.2-stable_win64_console.exe' --path . -- --capture
```
