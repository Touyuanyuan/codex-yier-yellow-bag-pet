$ErrorActionPreference='Stop'
$taskRoot=Split-Path $PSScriptRoot -Parent
$taskSandbox=Join-Path ([IO.Path]::GetTempPath()) ('yier-install-test-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $taskSandbox | Out-Null
$taskInstaller=Join-Path $taskRoot 'install.ps1'
$taskEngine=(Get-Process -Id $PID).Path
& $taskEngine -NoProfile -ExecutionPolicy Bypass -File $taskInstaller -CodexHome $taskSandbox
if ($LASTEXITCODE -ne 0) { throw 'Fresh installation failed.' }
$taskPet=Join-Path $taskSandbox 'pets/yier-yellow-bag'
$taskConfig=Get-Content -LiteralPath (Join-Path $taskPet 'pet.json') -Raw -Encoding UTF8 | ConvertFrom-Json
if ($taskConfig.id -cne 'yier-yellow-bag') { throw 'Installed identity differs.' }
& $taskEngine -NoProfile -ExecutionPolicy Bypass -File $taskInstaller -CodexHome $taskSandbox
if ($LASTEXITCODE -ne 0) { throw 'Repeat installation failed.' }
$taskConfigPath=Join-Path $taskPet 'pet.json'
[IO.File]::WriteAllText($taskConfigPath,'{"id":"preserve-test"}',[Text.UTF8Encoding]::new($false))
& $taskEngine -NoProfile -ExecutionPolicy Bypass -File $taskInstaller -CodexHome $taskSandbox
if ($LASTEXITCODE -eq 0) { throw 'Different existing version was not rejected.' }
if ((Get-Content -LiteralPath $taskConfigPath -Raw) -cne '{"id":"preserve-test"}') { throw 'Conflict contents were overwritten.' }
Write-Output 'PASS: fresh install, repeat install, existing-version conflict and preservation.'
Write-Output "Test directory retained: $taskSandbox"
