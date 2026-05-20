# PSUninstaller

Plataforma de orquestracao de software para inventario, analise e remocao de aplicativos Windows pelo terminal PowerShell.

## Uso rapido

```powershell
psu
psu -Menu
psu -Help

psu -ListPrograms
psu -Analyze Firefox
psu -Uninstall Firefox
psu -Uninstall Firefox -Silent
psu -Uninstall Firefox -Silent -Clean
psu -Uninstall Firefox -Force -Clean
psu -Uninstall Firefox -WhatIf
```

## Arquitetura CLI

```text
Invoke-PSUninstaller
|
+-- -ListPrograms
+-- -Analyze
+-- -Uninstall
|   +-- -Silent
|   +-- -Clean
|   +-- -Force
|   +-- -WhatIf
|
+-- -Menu
```

## Equivalencia Menu x CLI

| Menu | CLI |
|---|---|
| Listar todos os programas | `psu -ListPrograms` |
| Analisar programa | `psu -Analyze Firefox` |
| Desinstalar programa | `psu -Uninstall Firefox` |
| Modo silencioso | `psu -Uninstall Firefox -Silent` |
| Silencioso + limpeza | `psu -Uninstall Firefox -Silent -Clean` |
| Modo agressivo | `psu -Uninstall Firefox -Force -Clean` |
| Simular | `psu -Uninstall Firefox -WhatIf` |

## Multiplos programas e pipeline

```powershell
psu -Uninstall Chrome,Firefox -Silent
"Chrome","Firefox" | psu -Uninstall -Clean
"pdfsam","brave","chrome" | psu -Analyze
```

## Inventario avancado

```powershell
psu -ListPrograms
psu -IncludeAppx
psu -IncludeUpdates
psu -IncludeSystemComponent
psu -ListPrograms -IncludeAppx -IncludeUpdates -IncludeSystemComponent
```

## Saida estruturada

```powershell
psu -Analyze Firefox -AsObject
psu -Analyze Firefox -AsObject | ConvertTo-Json
psu -ListPrograms -AsObjectList | Where-Object Name -match "Chrome"
```

## Instalacao local

Com menu interativo:

```powershell
.\Install-PSUninstaller.ps1
```

Instalacao automatizada para o usuario atual:

```powershell
.\Install-PSUninstaller.ps1 -Scope CurrentUser -Force
```

Instalacao automatizada para todos os usuarios, em PowerShell como Administrador:

```powershell
.\Install-PSUninstaller.ps1 -Scope AllUsers -Force
```

## Build

Gere a release unificada:

```powershell
.\tools\Build-PSUninstaller.ps1
```

O build gera:

```text
dist/PSUninstaller/PSUninstaller.psm1
dist/PSUninstaller/PSUninstaller.psd1
```

Durante o desenvolvimento, as funcoes ficam separadas em `src/Public` e `src/Private`.

## Desinstalacao do modulo

```powershell
.\Uninstall-PSUninstaller.ps1
```
