# Repository Guidelines
## Project Structure & Module Organization
Core addon behavior resides in `Necrosis.lua`, `NecrosisInitialize.lua`, and supporting modules such as `NecrosisTimerFunction.lua` and `NecrosisGraphicalTimer.lua`. XML layouts (`Necrosis.xml`, `NecrosisGeneral.xml`, `NecrosisTimer.xml`, `NecrosisButtonMenu.xml`, etc.) describe frames declared in the manifest `Necrosis.toc` alongside `Bindings.xml`. Localization strings are split into `Localization-dialog-*.lua`, `Localization-functions-*.lua`, and the language switcher `Localization.lua`. Assets live under `UI/` (color-themed icon sets) and `Sounds/` (spell and speech cues). Keep documentation updates in `README.md` and changelogs per locale.

## Build, Test, and Development Commands
No build step is required; the addon loads directly from the repository folder. 
It is worth testing lua changes with luac (preferably 5.1) when finalizing everything.

## Coding Style & Naming Conventions
Follow `.editorconfig`: tabs for indentation (width 4), CRLF line endings, UTF-8 encoding to preserve accented credits. Table keys and globals use UpperCamelCase (`NecrosisButton`, `StoneMenuPos`), while event handlers keep the legacy `Necrosis_OnEvent` form. Favor double quotes for strings to match existing files, and extend configuration tables rather than introducing globals.
The code should follow WoW API for client version 1.12.  This is running on the Turtle Private Server.

## Testing Guidelines
Manual verification is expected. After copying the addon into TurtleWoW, test core flows: shard count updates, stone creation/use cooldowns, graphical timers, and localized dialogs. Capture screenshots when UI changes touch `Necrosis.xml` or `UI/` assets. If you introduce saved variables, confirm they persist by relogging. Keep combat log open to spot Lua errors; `/console scriptErrors 1` helps surface them.

## Commit & Pull Request Guidelines
Commits follow a short `type: imperative summary` (see `git log` for examples like `feat:` and `fix:`). Group related Lua and XML edits together, and include locale updates in the same commit when strings change. Pull requests should describe gameplay impact, list manual test steps, and attach before/after UI captures for visual tweaks. Reference TurtleWoW issue IDs or forum threads when relevant.
