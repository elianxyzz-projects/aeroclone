# Elianware

Elianware is a customised Roblox BedWars client project with its own branding, curated module selection and configuration interface.

## Features

- Custom blue-gradient interface and Elianware branding.
- Configurable modules and keybinds.
- Saved profiles and module preferences.
- Performance and gameplay customisation.
- Separate experimental development repository.

## Project files

- [Main loader](./loader.lua)
- [Elianware Testing](https://github.com/elianxyzz-projects/elianware-testing) — experimental features and development builds.

## Configuration and compatibility

New profiles start with modules disabled. Existing profiles restore saved settings. The main loader currently uses the legacy cache directory; complete runtime and profile isolation from the upstream client is not yet implemented.

Compatibility checks exist for Potassium, Real and Volt. Actual compatibility varies by runtime and has not been independently verified in-game.

## Development status

Changes are tested in the separate testing repository before promotion to this project. Runtime behaviour and game compatibility are not guaranteed. Follow Roblox and game-specific rules; use experimental gameplay features only in authorised environments.

## Credits

Elianware builds on the upstream GUI, module and library infrastructure from [wrealaero/aerov4](https://github.com/wrealaero/aerov4), using pinned revision `b723802d331778a362bfbd475fc2fb6f831c3fc1`. Original authors retain their respective rights. Elianware is a separately maintained derivative project, not an independent reimplementation or an official upstream release. No upstream license has been verified; public source availability does not imply redistribution permission.
