[CmdletBinding()]
param(
    [ValidateSet('CurrentUser','AllUsers')]
    [string]$Scope,

    [string]$SourcePath,

    [switch]$Build,

    [switch]$Force,

    [switch]$Menu
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-PSUAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal] $identity
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Find-PSUModuleSource {
    param([string]$ExplicitSource)

    $candidates = New-Object System.Collections.Generic.List[string]

    if ($ExplicitSource) {
        $candidates.Add($ExplicitSource)
    }

    $roots = New-Object System.Collections.Generic.List[string]

    if ($PSScriptRoot) {
        $roots.Add((Resolve-Path -Path $PSScriptRoot).Path)
    }

    try {
        $roots.Add((Resolve-Path -Path (Get-Location)).Path)
    }
    catch {
        # Ignore invalid current location.
    }

    foreach ($root in @($roots | Select-Object -Unique)) {
        $current = $root

        while ($current) {
            $candidates.Add((Join-Path $current 'dist\PSUninstaller'))
            $candidates.Add((Join-Path $current 'PSUninstaller\dist\PSUninstaller'))
            $candidates.Add((Join-Path $current 'src'))
            $candidates.Add((Join-Path $current 'PSUninstaller\src'))

            $parent = Split-Path -Path $current -Parent
            if (-not $parent -or $parent -eq $current) { break }
            $current = $parent
        }
    }

    foreach ($candidate in @($candidates | Select-Object -Unique)) {
        if (-not $candidate) { continue }

        $manifest = Join-Path $candidate 'PSUninstaller.psd1'
        $module   = Join-Path $candidate 'PSUninstaller.psm1'

        if ((Test-Path $manifest) -and (Test-Path $module)) {
            return (Resolve-Path -Path $candidate).Path
        }
    }

    return $null
}

function Get-PSUModuleInstallRoot {
    param(
        [ValidateSet('CurrentUser','AllUsers')]
        [string]$Scope
    )

    if ($Scope -eq 'AllUsers') {
        if ($PSVersionTable.PSEdition -eq 'Core') {
            return Join-Path $env:ProgramFiles 'PowerShell\Modules'
        }

        return Join-Path $env:ProgramFiles 'WindowsPowerShell\Modules'
    }

    if ($PSVersionTable.PSEdition -eq 'Core') {
        return Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Modules'
    }

    return Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WindowsPowerShell\Modules'
}

function Invoke-PSUBuildIfRequested {
    param([switch]$Build)

    if (-not $Build) { return }

    $candidates = @(
        (Join-Path $PSScriptRoot 'tools\Build-PSUninstaller.ps1'),
        (Join-Path $PSScriptRoot 'PSUninstaller\tools\Build-PSUninstaller.ps1'),
        (Join-Path (Split-Path $PSScriptRoot -Parent) 'tools\Build-PSUninstaller.ps1'),
        (Join-Path (Get-Location) 'tools\Build-PSUninstaller.ps1')
    )

    $buildScript = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1

    if (-not $buildScript) {
        Write-Warning 'Build solicitado, mas tools\Build-PSUninstaller.ps1 nao foi encontrado.'
        return
    }

    Write-Host "Executando build: $buildScript"
    & $buildScript
}

function Install-PSUModule {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('CurrentUser','AllUsers')]
        [string]$Scope,

        [Parameter(Mandatory)]
        [string]$ModuleSource,

        [switch]$Force
    )

    if ($Scope -eq 'AllUsers' -and -not (Test-PSUAdministrator)) {
        throw 'Instalacao para todos usuarios exige PowerShell como Administrador.'
    }

    $installRoot = Get-PSUModuleInstallRoot -Scope $Scope
    $target = Join-Path $installRoot 'PSUninstaller'

    New-Item -Path $installRoot -ItemType Directory -Force | Out-Null

    if (Test-Path $target) {
        if (-not $Force) {
            Write-Host ''
            Write-Host "Modulo ja existe em: $target"
            Write-Host 'Use a opcao Reinstalar ou execute com -Force para substituir.'
            return
        }

        Remove-Item -Path $target -Recurse -Force
    }

    Copy-Item -Path $ModuleSource -Destination $target -Recurse -Force
    Import-Module (Join-Path $target 'PSUninstaller.psd1') -Force

    Write-Host ''
    Write-Host 'PSUninstaller instalado com sucesso.'
    Write-Host "Escopo : $Scope"
    Write-Host "Origem : $ModuleSource"
    Write-Host "Destino: $target"
    Write-Host ''
    Write-Host 'Testes sugeridos:'
    Write-Host '  psu'
    Write-Host '  psu -Analyze Firefox'
    Write-Host '  psu Firefox -WhatIf'
    Write-Host ''
}

function Show-PSUInstallerMenu {
    param(
        [Parameter(Mandatory)]
        [string]$ModuleSource
    )

    do {
        Clear-Host
        $currentUserTarget = Join-Path (Get-PSUModuleInstallRoot -Scope CurrentUser) 'PSUninstaller'
        $allUsersTarget    = Join-Path (Get-PSUModuleInstallRoot -Scope AllUsers) 'PSUninstaller'

        Write-Host '===================================================='
        Write-Host '        INSTALADOR PSUNINSTALLER'
        Write-Host '===================================================='
        Write-Host ''
        Write-Host 'Origem detectada:'
        Write-Host "  $ModuleSource"
        Write-Host ''
        Write-Host 'Destino usuario atual:'
        Write-Host "  $currentUserTarget"
        Write-Host ''
        Write-Host 'Destino todos usuarios:'
        Write-Host "  $allUsersTarget"
        Write-Host ''
        Write-Host '1. Instalar para usuario atual'
        Write-Host '2. Instalar para todos usuarios'
        Write-Host '3. Reinstalar / substituir instalacao existente'
        Write-Host '0. Cancelar'
        Write-Host ''

        $choice = Read-Host 'Selecione'

        switch ($choice) {
            '1' {
                Install-PSUModule -Scope CurrentUser -ModuleSource $ModuleSource
                return
            }
            '2' {
                Install-PSUModule -Scope AllUsers -ModuleSource $ModuleSource
                return
            }
            '3' {
                Write-Host ''
                Write-Host 'Reinstalar em qual escopo?'
                Write-Host '1. Usuario atual'
                Write-Host '2. Todos usuarios'
                Write-Host '0. Voltar'
                Write-Host ''
                $subChoice = Read-Host 'Selecione'

                switch ($subChoice) {
                    '1' { Install-PSUModule -Scope CurrentUser -ModuleSource $ModuleSource -Force; return }
                    '2' { Install-PSUModule -Scope AllUsers -ModuleSource $ModuleSource -Force; return }
                    '0' { continue }
                    default {
                        Write-Host 'Opcao invalida.'
                        Pause
                    }
                }
            }
            '0' {
                Write-Host 'Instalacao cancelada.'
                return
            }
            default {
                Write-Host 'Opcao invalida.'
                Pause
            }
        }
    } while ($true)
}

Invoke-PSUBuildIfRequested -Build:$Build

$moduleSource = Find-PSUModuleSource -ExplicitSource $SourcePath

if (-not $moduleSource) {
    throw 'Nao foi possivel localizar PSUninstaller.psd1 e PSUninstaller.psm1. Rode o build ou informe -SourcePath.'
}

if ($Scope) {
    Install-PSUModule -Scope $Scope -ModuleSource $moduleSource -Force:$Force
    return
}

Show-PSUInstallerMenu -ModuleSource $moduleSource
