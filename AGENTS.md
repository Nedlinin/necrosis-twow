# Repository Guidelines
## Project Structure & Module Organization
Core addon behavior resides in `Necrosis.lua`, `NecrosisInitialize.lua`, and supporting modules such as `NecrosisTimerFunction.lua` and `NecrosisGraphicalTimer.lua`. XML layouts (`Necrosis.xml`, `NecrosisGeneral.xml`, `NecrosisTimer.xml`, `NecrosisButtonMenu.xml`, etc.) describe frames declared in the manifest `Necrosis.toc` alongside `Bindings.xml`. Localization strings are split into `Localization-dialog-*.lua`, `Localization-functions-*.lua`, and the language switcher `Localization.lua`. Assets live under `UI/` (color-themed icon sets) and `Sounds/` (spell and speech cues). Keep documentation updates in `README.md` and changelogs per locale.

## Build, Test, and Development Commands
No build step is required; the addon loads directly from the repository folder. 
You should always make a plan before modifying code: ask the user to review the plan before proceeding with modifications. If the changes are not trivial, write out your plan to the "PLAN.md" file (using Markdown syntax).
If the PLAN.md file already exists, append to the top of the file new data (create the file if necessary but you should never delete this file); this will allow it to act as a log of modifications we agreed to perform so make sure to mark it with date and timestamps.  Make sure to write this file out everytime you update the plan.
You should never make a code modification on a new topic without making a plan and confirming it with the user first.
Don't attempt your own file formatting, instead run stylua to format the file.
It is worth testing lua changes with luac (use Lua 5.0 to match the WoW 1.12 client) when finalizing everything.
If you ever run into a place where you could make divergent choices and aren't highly confident in the choice, detail it to the user and ask the user before proceeding.
Pay special attention to globals possibly being nil when accessed for the first time; ensure they are lazily evaluated or simply set to non-nil.
Pay special attention to file load order (be that in the .xml file Script blocks or the .toc file).
Pay special attention to the definition ordering of variables and functions, ensuring they are declared before use.

As you iterate through the steps of the plan you might update the plan and ask to user to reverify it,
especially if one of the steps was a discovery step and you can now provide more context/details.

## Coding Style & Naming Conventions
UTF-8 encoding to preserve accented characters. Table keys and globals use UpperCamelCase (`NecrosisButton`, `StoneMenuPos`), while event handlers keep the legacy `Necrosis_OnEvent` form. Favor double quotes for strings to match existing files, and extend configuration tables rather than introducing globals.
The code should follow WoW API for client version 1.12.  This is running on the Turtle Private Server.
Use stylua to format all .lua files.  The configuration for stylua is in the root of the repository in a file named stylua.toml.

## Testing Guidelines
It is worth testing lua changes with luac (use Lua 5.0 to match the WoW 1.12 client) when finalizing everything.
Manual verification is expected. After copying the addon into TurtleWoW, test core flows: shard count updates, stone creation/use cooldowns, graphical timers, and localized dialogs. Capture screenshots when UI changes touch `Necrosis.xml` or `UI/` assets. If you introduce saved variables, confirm they persist by relogging. Keep combat log open to spot Lua errors; `/console scriptErrors 1` helps surface them.

## Commit & Pull Request Guidelines
Commits follow a short `type: imperative summary` (see `git log` for examples like `feat:` and `fix:`). Group related Lua and XML edits together, and include locale updates in the same commit when strings change. Pull requests should describe gameplay impact, list manual test steps, and attach before/after UI captures for visual tweaks. Reference TurtleWoW issue IDs or forum threads when relevant.
