# Merge Conflict

A first-person office comedy built with **Godot 4.7.2 and GDScript**. You are a software engineering intern at Small Batch, where coffee is critical infrastructure and every quick question has a follow-up meeting.

## Play

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
| E | Interact with the person or workstation under the crosshair |
| Click / 1, 2, 3 | Choose a dialogue response |
| Enter | Continue after feedback |
| Escape | Pause, resume, restart, or quit |

Follow the objective at the lower left and the teal destination on the floor map. Move close enough to a person or desk and look at them; the interaction prompt appears when they are within reach. During dialogue, the mouse is free for clicking. It returns to camera control when the dialogue closes.

## The prototype

One compressed **final internship day**, taking roughly 10–15 minutes depending on reading and exploration:

1. Give your standup update.
2. Walk to Maya's desk and clarify an ambiguous feature.
3. Return to your workstation and choose an instruction for BatchGPT.
4. Ask Maya about review feedback, then decide how thoroughly to test.
5. Help Sam, or protect your own deadline.
6. Meet Jordan for your 1:1: own a mistake and choose project scope.
7. Take a break, work late, or pursue beverage-based productivity.
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
| `scripts/hud.gd` | Status, dialogue, choices, pause, evaluation |
| `scripts/office_map.gd` | Floor map and destination |
| `content/story.gd` | Editable dialogue, choices, effects, offer rules |

All art is built from simple geometry and materials; no external asset pack is required. The renderer uses OpenGL Compatibility with 4× MSAA.

## Verify

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\test.ps1
```

The checks cover importing the project, complete workday progression, decision paths and ending boundaries, connected walkable floor space, interaction visibility, and keyboard input.

To capture the actual rendered game screens into the ignored `artifacts` folder:

```powershell
& '.tools\godot\Godot_v4.7.2-stable_win64_console.exe' --path . -- --capture
```
