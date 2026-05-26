[CmdletBinding()]
param(
    [ValidateSet('CurrentUser','AllUsers')]
    [string]$Scope = 'CurrentUser',

    [string]$ReleaseUrl = 'https://github.com/jhoylsonn/PSUninstaller/releases/latest/download/PSUninstaller.zip'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$tempRoot = Join-Path $env:TEMP ('PSUninstaller_' + [guid]::NewGuid().ToString('N'))
$zipPath = Join-Path $tempRoot 'PSUninstaller.zip'

New-Item -Path $tempRoot -ItemType Directory -Force | Out-Null

try {
    Write-Host "Baixando PSUninstaller de: $ReleaseUrl"
    Invoke-WebRequest -Uri $ReleaseUrl -OutFile $zipPath -UseBasicParsing

    Expand-Archive -Path $zipPath -DestinationPath $tempRoot -Force

    $installer = Get-ChildItem -Path $tempRoot -Filter 'Install-PSUninstaller.ps1' -Recurse | Select-Object -First 1
    if (-not $installer) {
        throw 'Install-PSUninstaller.ps1 nao encontrado no pacote baixado.'
    }

    & $installer.FullName -Scope $Scope -Force
}
finally {
    if (Test-Path $tempRoot) {
        Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
