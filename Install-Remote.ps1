# ====================================================
# Install-Remote.ps1
# Instalador remoto - PSUninstaller
# ====================================================

$ErrorActionPreference = "Stop"

$ReleaseUrl = "https://github.com/jhoylsonn/PSUninstaller/releases/latest/download/PSUninstaller.zip"

$tempFolder = Join-Path $env:TEMP "PSUninstaller"
$zipPath    = Join-Path $tempFolder "PSUninstaller.zip"

Write-Host ""
Write-Host "Baixando PSUninstaller de:"
Write-Host $ReleaseUrl
Write-Host ""

if (!(Test-Path $tempFolder)) {
    New-Item -Path $tempFolder `
             -ItemType Directory `
             -Force | Out-Null
}

try {

    Invoke-WebRequest `
        -Uri $ReleaseUrl `
        -OutFile $zipPath `
        -UseBasicParsing

}
catch {

    Write-Host ""
    Write-Warning "Falha ao baixar release."

    Write-Host $_.Exception.Message
    return
}

Write-Host "Download concluido."

Write-Host ""
Write-Host "Extraindo arquivos..."

Expand-Archive `
    -Path $zipPath `
    -DestinationPath $tempFolder `
    -Force

$installScript = Get-ChildItem `
    -Path $tempFolder `
    -Filter "Install-PSUninstaller.ps1" `
    -Recurse |
    Select-Object -First 1

if (!$installScript) {

    Write-Warning "Install-PSUninstaller.ps1 nao encontrado."

    return
}

Write-Host ""
Write-Host "Executando instalador..."
Write-Host ""

& $installScript.FullName

Write-Host ""
Write-Host "PSUninstaller instalado com sucesso."
Write-Host ""