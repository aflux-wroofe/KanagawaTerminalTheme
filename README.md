# Kanagawa & Kansō Terminal Themes

[Kanagawa](https://github.com/rebelot/kanagawa.nvim) and [Kansō](https://github.com/webhooked/kanso.nvim) colour schemes for Windows Terminal, plus a matching two-line Nerd Font prompt: either as a PowerShell profile or as an [Oh My Posh](https://ohmyposh.dev/) theme for any shell.

## What's included

```
windows-terminal/
  KanagawaDragon.json    Kanagawa Dragon colour scheme (dark, muted)
  KanagawaWave.json      Kanagawa Wave colour scheme (the standard variant)
  KanagawaLotus.json     Kanagawa Lotus colour scheme (light)
  KansoZen.json          Kanso Zen colour scheme (deep, rich dark)
  KansoInk.json          Kanso Ink colour scheme (balanced dark)
  KansoMist.json         Kanso Mist colour scheme (soft, muted dark)
  KansoPearl.json        Kanso Pearl colour scheme (light)
powershell/
  profile.ps1            PowerShell tweaks: bold blue directories in ls, loads the prompt
  KanagawaPrompt.ps1     Two-line prompt showing path, git branch/status and command duration
oh-my-posh/
  kanagawa.omp.json      The same prompt as an Oh My Posh theme (bash, zsh, fish, PowerShell, ...)
install.ps1              Installs the schemes into Windows Terminal and hooks the profile into PowerShell
```

## Requirements

- Windows Terminal
- PowerShell 7+ to run the installer (the prompt also works in Windows PowerShell 5.1)
- A [Nerd Font](https://www.nerdfonts.com/) v3+ for the prompt glyphs, e.g. JetBrainsMono Nerd Font or CaskaydiaCove Nerd Font

## Install

```powershell
git clone https://github.com/aflux-wroofe/KanagawaTerminalTheme.git
cd KanagawaTerminalTheme
./install.ps1
```

Options:

```powershell
./install.ps1 -Variant Wave                          # make Wave the default instead of Dragon
./install.ps1 -Variant Lotus                         # or the light Lotus variant
./install.ps1 -Variant Ink                           # or a Kanso variant: Zen, Ink, Mist, Pearl
./install.ps1 -FontFace 'CaskaydiaCove Nerd Font'    # set the font for all profiles
./install.ps1 -SkipDefaultScheme                     # add the schemes without applying them
./install.ps1 -OhMyPosh                              # use the Oh My Posh theme for the prompt
./install.ps1 -Uninstall                             # remove the schemes, profile hook and prompt files
./install.ps1 -WhatIf                                # preview changes
```

The installer is safe to re-run: schemes are replaced by name, the profile hook is rewritten rather than duplicated, and every changed file is backed up first. The prompt files are copied to `%LOCALAPPDATA%\KanagawaTerminalTheme` and your PowerShell profile loads them from there, so the repo can be moved or deleted afterwards. Re-run the installer to pick up changes made in the repo.

### Manual install

1. Open Windows Terminal settings → **Open JSON file**.
2. Paste the contents of any of the `windows-terminal/*.json` files into the `schemes` array.
3. Set `"colorScheme": "Kanagawa Dragon"` (or `"Kanagawa Wave"`, `"Kanagawa Lotus"`, `"Kanso Zen"`, `"Kanso Ink"`, `"Kanso Mist"`, `"Kanso Pearl"`) on a profile or under `profiles.defaults`.
4. Optionally add `. "C:\path\to\KanagawaTerminalTheme\powershell\profile.ps1"` to your `$PROFILE`. This loads the prompt straight from the repo, so update the path if you move it (the installer copies the files elsewhere to avoid this).

### Oh My Posh

In PowerShell, `./install.ps1 -OhMyPosh` sets this up for you. To do it by hand, or to use the prompt in another shell, point [Oh My Posh](https://ohmyposh.dev/) at the theme instead of loading `profile.ps1`:

```powershell
oh-my-posh init pwsh --config 'C:\path\to\KanagawaTerminalTheme\oh-my-posh\kanagawa.omp.json' | Invoke-Expression
```

```bash
eval "$(oh-my-posh init bash --config ~/KanagawaTerminalTheme/oh-my-posh/kanagawa.omp.json)"   # or zsh, fish, ...
```

The theme uses the terminal's 16 ANSI colours, like the PowerShell prompt, so it follows whichever Kanagawa or Kanso scheme the terminal is set to. For the matching colours outside Windows Terminal, use a scheme for your terminal from [kanagawa.nvim's extras](https://github.com/rebelot/kanagawa.nvim/tree/master/extras) or [kanso.nvim's extras](https://github.com/webhooked/kanso.nvim/tree/main/extras).

## Prompt

```
╭─ ~\Projects\Themes\KanagawaTerminalTheme on  master  1  2 took 3.2s
╰─❯
```

Shows staged, modified, untracked and conflicted file counts, commits ahead/behind upstream, and how long slow commands took. Settings can be changed after the profile loads via `$KanagawaPrompt`, for example:

```powershell
$KanagawaPrompt.ShowGit = $false        # hide git info
$KanagawaPrompt.MinDuration = 5         # only show durations over 5s
$KanagawaPrompt.IconWidth = 1           # use with "Nerd Font Mono" fonts
```

These settings are for the PowerShell prompt only. With Oh My Posh, edit `kanagawa.omp.json` directly (for example the `threshold` on the `executiontime` segment).

## Credits

Colour palettes from [kanagawa.nvim](https://github.com/rebelot/kanagawa.nvim) by rebelot and [kanso.nvim](https://github.com/webhooked/kanso.nvim) by webhooked.

## License

[MIT](LICENSE)
