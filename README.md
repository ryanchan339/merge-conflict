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

Your computer is the main task hub. Sitting down opens a macOS-inspired desktop with wallpaper, a menu bar, app shortcuts, and a translucent dock. Click **Tasks** to resume your assignment, or open an app directly. Slack has a purple channel and direct-message layout, Changes has a repository sidebar and review/checks screens, and BatchGPT has a cream-and-green chat workspace. Decisions show context and reply or action choices without an extra question restating the options. The visible **X** closes a window and keeps unanswered drafts. Closing a submitted update acknowledges it once; yellow minimizes, and green zooms. Minimized feedback stays available, and desktop number keys cannot select a hidden option.

Slack contains the workday's messages from Maya, Sam, Jordan, and the pager bot. Its channel and person filters work, and red dots mark pending app and thread tasks until completion. Changes includes **Source code**, **Test runner**, and **App preview**. Inspect the executable `favorites.gd` module, its test file, and the ticket README. Run isolated tests to see expected versus received results; use small code edits to repair guest access, accidental orders, and duplicate requests. The same compiled function powers the clickable app preview. Edits invalidate earlier checks, and passing results appear on the CR. Changes tracks **CR #104** from draft through submission, review comments, and merge. After generating the feature, explicitly push the CR and request review. When Maya leaves comments, decide whether to ask her in person, check the cases at your desk, or merge early and deal with a follow-up. Drafts resume when you return to your desk. A choice to ask someone in person stays pending until you actually speak to them.

Click choices directly on the monitor. Gains and losses appear after each choice, using the actual stat change at the 0–100 limits. The screen's **Loop** button picks up your phone; you can also approach the physical phone on the desk. Scroll the fictional short-video feed, like a clip, and put it down to return to work. Every five posts costs ten game minutes and two delivery points.

Changes also includes **Investigate**, **Debugger**, **Release**, and **Calendar**. Investigate the duplicate-coffee report using receipts, request logs, an archived CR, and an optional conversation with Maya. The debugger steps through snapshots of actual executed lines and variables; log evidence opens the captured production revision while normal debugging uses staging. Choose a small request guard, a broader store-once fix, or an honest temporary feature hold. Passing code needs CR review before normal deployment; an explicit unsafe release can cause real extra orders, a page, and trust loss. Staging edits do not change the physical coffee tablet until deployment. Rollback restores the previous code, and disabling Save preserves checkout. Coworkers try releases and message you about the result.

The kitchenette's coffee tablet runs the live version. Use it to reproduce charges, compare guest behavior, and verify your fix. Maya and Sam move between desks, the kitchenette, and rehearsal according to the workday's appointments. Calendar entries show current locations and availability; a busy coworker can receive context on Slack. Conversations pause a commute and resume it afterward. The office clock advances with assignments.

In the kitchenette, open the refrigerator and slide out the drawer. Take a cup from the counter or open drawer, put it under the coffee machine, wait for it to brew, pick it up, and press **F** to drink. The first coffee restores 12 energy. The objective tracks your next step.

Alex in People Operations handles optional complaints about lunch theft, meeting behavior, and crunch. Your approach changes time and stats, and the report appears in your evaluation history. Filing a complaint does not skip your current assignment, and repeating it cannot farm rewards.

Explore the office to clear the printer jam, vend and pick up a snack, get water, organize the whiteboard, and water the plant. These objects animate when used. Small stat benefits apply once per day.

## The prototype

One compressed **final internship day**, taking roughly 10–15 minutes depending on reading and exploration:

1. Give your standup update.
2. Read Maya's ticket in Slack and choose how to clarify it.
3. Give BatchGPT instructions, then push your change request for review.
4. Receive Maya's CR comments; ask beforehand, test, or merge early.
5. Read Sam's Slack request and help in person, or protect your own deadline.
6. Meet Jordan for your 1:1: own a mistake and choose project scope.
7. Make a coffee, then decide whether to rest or work late.
8. Respond to a severity page: sprint to your desk and solve an accessible incident puzzle.
9. Head to the elevator for your evaluation.

Choices change **delivery, quality, trust, and energy**. Energy below 25 slows your sprint. The pager gives you 45 seconds to reach your workstation; dialogue and the pause menu stop the clock. Missing the deadline costs trust and triggers a teammate's intervention, but you can still finish the incident and the day.

Possible outcomes are **fired, no return offer, return offer, and an upleveled return offer**. The highest offer requires strong results plus clarification and testing. Feedback names the consequences of each choice; the evaluation recalls your recent decisions.

The AI assistant is authored satire with predefined outcomes. There is no live model or API key. The in-game source and test files are real GDScript compiled locally; fixes are selectable, so no syntax knowledge is required. Coworkers currently remain at their stations. This is a single-day vertical slice, with restart rather than a multi-day save system. The latest evaluation is recorded in Godot's user-data directory as `last_evaluation.json`.

## Project layout

| File | Purpose |
| --- | --- |
| `scripts/main.gd` | Workday progression, interactions, consequences, pager, evaluation |
| `scripts/office.gd` | Procedural office geometry, furniture, coworkers, targets |
| `scripts/player.gd` | First-person movement, camera, collision, interaction ray |
| `scripts/hud.gd` | Minimal objectives, compact dialogue, pause, evaluation |
| `scripts/workstation.gd` | Slack feed, change requests, AI tickets, and desktop rendered onto the physical monitor |
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
