# Kanagawa prompt: a quiet two-line prompt drawn with Nerd Font (v3+) glyphs.
#
#   ╭─ [wave] ~\Projects\Themes\KanagawaTerminalTheme on [branch] master  [+] 1  [.] 2 took [hourglass] 3.2s
#   ╰─❯
#
# Git status after the branch name, as outlined Octicons with a count:
#   [+] staged (green)   [.] modified (yellow)   [?] untracked (grey)
#   [!] conflicts (red)  [up] / [down] commits ahead of / behind upstream (blue)
#
# Colours come from the terminal's 16-colour palette, so the prompt follows
# whichever variant (Dragon, Wave or Lotus) the terminal is using. Glyphs are built from
# code points (not literals) so they render the same in PowerShell 5.1, which
# reads BOM-less files as ANSI, and PowerShell 7.

$global:KanagawaPrompt = @{
    # Settings: change these after dot-sourcing if you want
    ShowGit           = $true
    GitOnNetworkPaths = $false  # git status over UNC shares can be slow
    MinDuration       = 2       # seconds before "took" is shown
    MaxPathSegments   = 3       # trailing folders kept when the path is long
    IconWidth         = 2       # cells an icon is drawn across: 2 for "Nerd Font", 1 for "Nerd Font Mono"

    Glyph = @{
        Wave     = [char]::ConvertFromUtf32(0xF078D)  # nf-md-waves
        Branch   = [char]::ConvertFromUtf32(0xF418)   # nf-oct-git_branch
        Timer    = [char]::ConvertFromUtf32(0xF252)   # nf-fa-hourglass_half
        Python   = [char]::ConvertFromUtf32(0xE73C)   # nf-dev-python
        Shield   = [char]::ConvertFromUtf32(0xF132)   # nf-fa-shield
        Chevron  = [string][char]0x276F               # ❯
        Cross    = [string][char]0x2718               # ✘
        Staged    = [char]::ConvertFromUtf32(0xF457)  # nf-oct-diff_added
        Modified  = [char]::ConvertFromUtf32(0xF459)  # nf-oct-diff_modified
        Untracked = [char]::ConvertFromUtf32(0xF420)  # nf-oct-question
        Conflict  = [char]::ConvertFromUtf32(0xF421)  # nf-oct-alert
        Ahead     = [char]::ConvertFromUtf32(0xF431)  # nf-oct-arrow_up
        Behind    = [char]::ConvertFromUtf32(0xF433)  # nf-oct-arrow_down
        Ellipsis = [string][char]0x2026               # …
        Top      = [string][char]0x256D + [char]0x2500  # ╭─
        Bottom   = [string][char]0x2570 + [char]0x2500  # ╰─
        Rail     = [string][char]0x2502               # │
    }

    Ink = @{
        Muted  = "$([char]27)[90m"    # fujiGray: connective words, frame
        Blue   = "$([char]27)[34m"    # crystalBlue / dragonBlue: parent folders
        Leaf   = "$([char]27)[1;94m"  # springBlue, bold: current folder
        Wave   = "$([char]27)[94m"    # springBlue: wave mark, prompt chevron
        Violet = "$([char]27)[35m"    # oniViolet: git branch
        Green  = "$([char]27)[32m"    # springGreen: staged
        Yellow = "$([char]27)[33m"    # boatYellow: modified, duration
        Aqua   = "$([char]27)[36m"    # waveAqua: python env
        Red    = "$([char]27)[31m"    # autumnRed: errors, admin
        Reset  = "$([char]27)[0m"
    }

    HasGit        = [bool](Get-Command git -CommandType Application -ErrorAction Ignore)
    IsAdmin       = $env:OS -eq 'Windows_NT' -and
                    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
                        [Security.Principal.WindowsBuiltInRole]::Administrator)
    LastHistoryId = (Get-History -Count 1).Id
    LastError     = $global:Error[0]  # to tell cmdlet failures from native exit codes
    FirstPrompt   = $true
}

# Python's Activate.ps1 would otherwise wrap this prompt with its own "(venv)"
$env:VIRTUAL_ENV_DISABLE_PROMPT = 1

function global:Get-KanagawaGitSegment {
    $kp = $global:KanagawaPrompt
    $g = $kp.Glyph
    $ink = $kp.Ink

    # --no-optional-locks: don't refresh the index, which can clash with editors running git at the same time
    $status = git --no-optional-locks status --porcelain=v2 --branch 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $status) { return '' }

    $oid = $branch = $null
    $ahead = $behind = $staged = $modified = $untracked = $conflicts = 0
    switch -Regex ($status) {
        '^# branch\.oid (\S+)'            { $oid = $Matches[1] }
        '^# branch\.head (.+)'            { $branch = $Matches[1] }
        '^# branch\.ab \+(\d+) -(\d+)'    { $ahead = [int]$Matches[1]; $behind = [int]$Matches[2] }
        '^[12] (.)(.)'                    { if ($Matches[1] -ne '.') { $staged++ }; if ($Matches[2] -ne '.') { $modified++ } }
        '^u '                             { $conflicts++ }
        '^\? '                            { $untracked++ }
    }
    if ($branch -eq '(detached)' -and $oid.Length -ge 7) { $branch = $oid.Substring(0, 7) }

    # Icons overflow their cell in non-Mono Nerd Fonts, so give them room before the next character
    $pad = ' ' * [math]::Max(0, $kp.IconWidth - 1)
    $out = " $($ink.Muted)on$($ink.Reset) $($ink.Violet)$($g.Branch)$pad $branch$($ink.Reset)"
    $parts = (
        ($conflicts, $ink.Red, $g.Conflict),
        ($staged, $ink.Green, $g.Staged),
        ($modified, $ink.Yellow, $g.Modified),
        ($untracked, $ink.Muted, $g.Untracked),
        ($ahead, $ink.Wave, $g.Ahead),
        ($behind, $ink.Wave, $g.Behind)
    )
    foreach ($part in $parts) {
        $count, $colour, $icon = $part
        if ($count) { $out += "  $colour$icon$pad $count$($ink.Reset)" }
    }
    $out
}

function global:prompt {
    # Capture before anything else overwrites them
    $ok = $?
    $exitCode = $global:LASTEXITCODE
    $newError = $global:Error.Count -and -not [object]::ReferenceEquals($global:Error[0], $global:KanagawaPrompt.LastError)

    $kp = $global:KanagawaPrompt
    $kp.LastError = $global:Error[0]
    $g = $kp.Glyph
    $ink = $kp.Ink
    $pad = ' ' * [math]::Max(0, $kp.IconWidth - 1)  # room for icons that overflow their cell
    $esc = [char]27
    $bel = [char]7
    $inWT = [bool]$env:WT_SESSION

    # Did a new command run since the last prompt (vs. just pressing Enter)?
    $last = Get-History -Count 1
    $ranCommand = $last -and $last.Id -ne $kp.LastHistoryId
    if ($ranCommand) { $kp.LastHistoryId = $last.Id }

    # Path: ~ for home, trimmed to the last few folders, current folder in bold
    $location = $executionContext.SessionState.Path.CurrentLocation
    $path = if ($location.Provider.Name -eq 'FileSystem') { $location.ProviderPath } else { $location.Path }
    $isUnc = $path.StartsWith('\\')
    if ($path.Equals($HOME, 'OrdinalIgnoreCase') -or $path.StartsWith("$HOME\", 'OrdinalIgnoreCase')) {
        $path = '~' + $path.Substring($HOME.Length)
    }
    $segments = @($path.TrimEnd('\', '/') -split '[\\/]')
    $rootCount = if ($isUnc) { 4 } else { 1 }  # '', '', server, share
    if ($segments.Count -gt $rootCount + $kp.MaxPathSegments + 1) {  # only collapse 2+ folders
        $segments = @($segments[0..($rootCount - 1)]) + $g.Ellipsis + @($segments[(-$kp.MaxPathSegments)..-1])
    }
    $leaf = $segments[-1]
    $parent = if ($segments.Count -gt 1) { ($segments[0..($segments.Count - 2)] -join '\') + '\' } else { '' }
    if (-not $parent -and $leaf -match ':$') { $leaf += '\' }

    $out = ''

    # Windows Terminal shell integration: previous command's result, prompt start, cwd
    if ($inWT -and $ranCommand) { $out += "$esc]133;D;$(if ($ok) { 0 } else { 1 })$bel" }
    if (-not $kp.FirstPrompt) {
        # A little breathing room between commands, except at the top of a cleared screen
        $atTop = try { $Host.UI.RawUI.CursorPosition.Y -eq 0 } catch { $false }
        if (-not $atTop) { $out += "`n" }
    }
    $kp.FirstPrompt = $false
    if ($inWT) {
        $out += "$esc]133;A$bel"
        if ($location.Provider.Name -eq 'FileSystem') { $out += "$esc]9;9;`"$($location.ProviderPath)`"$bel" }
    }

    # Line one
    $out += "$($ink.Muted)$($g.Top)$($ink.Reset) "
    if ($kp.IsAdmin) { $out += "$($ink.Red)$($g.Shield)$pad$($ink.Reset) " }
    $out += "$($ink.Wave)$($g.Wave)$pad$($ink.Reset) $($ink.Blue)$parent$($ink.Reset)$($ink.Leaf)$leaf$($ink.Reset)"

    if ($kp.ShowGit -and $kp.HasGit -and $location.Provider.Name -eq 'FileSystem' -and
        (-not $isUnc -or $kp.GitOnNetworkPaths)) {
        $out += Get-KanagawaGitSegment
    }

    $venv = if ($env:VIRTUAL_ENV) { Split-Path $env:VIRTUAL_ENV -Leaf } elseif ($env:CONDA_DEFAULT_ENV) { $env:CONDA_DEFAULT_ENV }
    if ($venv) { $out += "  $($ink.Muted)via$($ink.Reset) $($ink.Aqua)$($g.Python)$pad $venv$($ink.Reset)" }

    if ($ranCommand) {
        $took = $last.EndExecutionTime - $last.StartExecutionTime
        if ($took.TotalSeconds -ge $kp.MinDuration) {
            $text = if ($took.TotalHours -ge 1) { '{0}h {1}m' -f [int][math]::Floor($took.TotalHours), $took.Minutes }
                    elseif ($took.TotalMinutes -ge 1) { '{0}m {1}s' -f $took.Minutes, $took.Seconds }
                    else { '{0:0.0}s' -f $took.TotalSeconds }
            $out += "  $($ink.Muted)took$($ink.Reset) $($ink.Yellow)$($g.Timer)$pad $text$($ink.Reset)"
        }
        if (-not $ok) {
            # $LASTEXITCODE only changes when a native program runs, so a new error record means a cmdlet failed
            $code = if ($exitCode -and -not $newError) { " $exitCode" } else { '' }
            $out += "  $($ink.Red)$($g.Cross)$code$($ink.Reset)"
        }
    }

    # Line two: the chevron turns red after a failed command
    $chevron = if ($ranCommand -and -not $ok) { $ink.Red } else { $ink.Wave }
    $out += "`n$($ink.Muted)$($g.Bottom)$($ink.Reset)$chevron$($g.Chevron)$($ink.Reset) "
    if ($inWT) { $out += "$esc]133;B$bel" }

    $Host.UI.RawUI.WindowTitle = $leaf
    $global:LASTEXITCODE = $exitCode
    $out
}

# Matching syntax colours while typing
if (Get-Module PSReadLine) {
    $ink = $global:KanagawaPrompt.Ink
    Set-PSReadLineOption -ContinuationPrompt "   $($ink.Muted)$($global:KanagawaPrompt.Glyph.Rail)$($ink.Reset) " -Colors @{
        Command   = "$([char]27)[34m"    # crystalBlue: functions
        Keyword   = "$([char]27)[35m"    # oniViolet: keywords
        String    = "$([char]27)[32m"    # springGreen: strings
        Number    = "$([char]27)[91m"    # waveRed / peachRed: literals
        Operator  = "$([char]27)[33m"    # boatYellow: operators
        Parameter = "$([char]27)[95m"    # springViolet: parameters
        Variable  = "$([char]27)[37m"    # oldWhite: identifiers
        Type      = "$([char]27)[96m"    # waveAqua: types
        Member    = "$([char]27)[93m"    # carpYellow: members
        Comment   = "$([char]27)[3;90m"  # fujiGray, italic
        Emphasis  = "$([char]27)[1;94m"  # springBlue: search matches
        Error     = "$([char]27)[31m"    # autumnRed
        Selection = "$([char]27)[7m"          # reverse video: readable on every variant
    }
    # Prediction colours need PSReadLine 2.1+ (bundled with PowerShell 7)
    try { Set-PSReadLineOption -Colors @{ InlinePrediction = "$([char]27)[3;90m" } } catch { }
    Remove-Variable ink
}
