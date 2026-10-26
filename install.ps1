#requires -Version 5.1
[CmdletBinding()]
param([string]$CodexHome)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$taskPetId='yier-yellow-bag'
try {
    $taskSource=Join-Path $PSScriptRoot 'pet'
    $taskManifest=Get-Content -LiteralPath (Join-Path $taskSource 'pet.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($taskManifest.id -cne $taskPetId -or $taskManifest.displayName -cne '小黄包一二' -or
        $taskManifest.spriteVersionNumber -ne 2 -or $taskManifest.spritesheetPath -cne 'spritesheet.webp') {
        throw 'Unexpected pet configuration. Extract the complete release ZIP again.'
    }
    $taskSheet=[IO.File]::ReadAllBytes((Join-Path $taskSource 'spritesheet.webp'))
    if ($taskSheet.Length -lt 30 -or [Text.Encoding]::ASCII.GetString($taskSheet,0,4) -cne 'RIFF' -or
        [Text.Encoding]::ASCII.GetString($taskSheet,8,4) -cne 'WEBP') { throw 'Invalid WebP sprite sheet.' }
    if ($PSBoundParameters.ContainsKey('CodexHome')) {
        if ([string]::IsNullOrWhiteSpace($CodexHome)) { throw 'CodexHome must not be blank.' }
        $taskRoot=$CodexHome
    } elseif ($env:CODEX_HOME) { $taskRoot=$env:CODEX_HOME }
    else { $taskRoot=Join-Path $env:USERPROFILE '.codex' }
    $taskPets=[IO.Path]::GetFullPath((Join-Path $taskRoot 'pets'))
    $taskTarget=Join-Path $taskPets $taskPetId
    if (Test-Path -LiteralPath $taskTarget) {
        $taskTargetItem=Get-Item -LiteralPath $taskTarget -Force
        if (-not $taskTargetItem.PSIsContainer -or ($taskTargetItem.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw 'The pet target is not an ordinary directory. No changes made.'
        }
        foreach ($taskName in @('pet.json','spritesheet.webp')) {
            $taskExisting=Join-Path $taskTarget $taskName
            if (-not (Test-Path -LiteralPath $taskExisting -PathType Leaf)) { throw 'An incomplete pet already exists. Back it up and move it out of pets before installing.' }
            if ((Get-Item -LiteralPath $taskExisting -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Existing pet files must not be links.' }
            $taskA=[IO.File]::ReadAllBytes((Join-Path $taskSource $taskName))
            $taskB=[IO.File]::ReadAllBytes($taskExisting)
            if ([Convert]::ToBase64String($taskA) -cne [Convert]::ToBase64String($taskB)) {
                throw 'A different version already exists. Back it up and move it out of pets before installing. Nothing overwritten.'
            }
        }
        Write-Host 'Already installed with identical files.'
    } else {
        New-Item -ItemType Directory -Path $taskTarget -Force | Out-Null
        foreach ($taskName in @('pet.json','spritesheet.webp')) {
            [IO.File]::Copy((Join-Path $taskSource $taskName),(Join-Path $taskTarget $taskName),$false)
        }
        Write-Host 'Installation complete.'
    }
    Write-Host "Installed location: $taskTarget"
    Write-Host 'Codex 设置 > Mini 与虚拟宠物 / Pets > 刷新列表 > 选择「小黄包一二」。'
    Write-Host 'If an older cloud pet still appears, see README: import the new artwork with install.html.'
    exit 0
} catch {
    Write-Host ('Installation stopped: '+$_.Exception.Message) -ForegroundColor Red
    exit 1
}
