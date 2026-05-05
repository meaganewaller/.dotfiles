# Fonts

These are fonts used throughout my configuration, I include them here for easy installation. Ones that can be installed by Homebrew are configured in the [base brewfile](../../../brewfiles/base.Brewfile).

## Font Listing

| Name | From | Used |
| --- | --- | --- |
| [Babel Stone Runic Elder Futhark](./BabelStoneRunicElderFuthark.ttf) | [BabelStone Fonts](https://www.babelstone.co.uk/Fonts/ElderFuthark.html) | [Wezterm fallback font](../../../home/.config/wezterm/lua/fonts.lua) |

## Installation

They will install as part of the standard dotfiles installation:

```bash
mise run setup --profile=<profile>
```

To install just the fonts, run:

```bash
mise run fonts
```