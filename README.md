# Butcher Corpses B42

Project Zomboid mod that lets players butcher corpses into Corpse Flesh. The flesh can be used for compost, cooked, or eaten with sandbox-configurable consequences.

This copy has been updated for Project Zomboid Build 42 and adjusted for multiplayer use by moving corpse removal and meat creation to server-side validation.

## Features

- Right-click corpse context-menu action for butchering.
- Supports butcher tools from the recipe, including cleavers, axes, sharp knives, and saws.
- Configurable effects for eating raw or cooked Corpse Flesh.
- Configurable result placement: drop meat on the ground or add it to the player's inventory.
- Multiplayer-ready server-side handling for corpse removal and result creation.

## Install

For Workshop upload, place this repository folder under `Zomboid/Workshop/ButcherCorpsesB42`. The upload root must contain `workshop.txt`, `preview.png`, and `Contents/`.

For local testing, copy `Contents/mods/ButcherCorpsesB42` to `Zomboid/mods/ButcherCorpsesB42`.

For multiplayer servers, make sure both the server and clients have the same mod files enabled. Server config should use `Mods=ButcherCorpsesB42`.

## Compatibility

Target game version: Project Zomboid Build 42.

## Credits

Original upstream repository: https://github.com/An77777777/Butcher-Corpses

Original contributors credited from the upstream GitHub repository:

- MassCraxx
- An77777777

See `CREDITS.md` for credit details.
