# Publica Hora Dorada (beta) en GitHub: repositorio, ramas, tarjetas, PR de Joel,
# invitación a Jorge (JMartinez-D) y Release con el ejecutable.
# Se corre en PowerShell en la PC de Joel (NO en el servidor Linux):
#   powershell -ExecutionPolicy Bypass -File herramientas\publicar\publicar_github.ps1
# Si algo ya existe (repo, tarjeta, PR o Release) lo salta, así que se puede volver a correr.

$ErrorActionPreference = "Continue"
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$repo = "joeljorex/hora-dorada-godot"
$raiz = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $raiz
$datos = Get-Content "$PSScriptRoot\datos.json" -Raw -Encoding UTF8 | ConvertFrom-Json

function Paso($t) { Write-Host ""; Write-Host "== $t" -ForegroundColor Yellow }
function Revisar($t) { if ($LASTEXITCODE -ne 0) { Write-Host "Falló: $t (código $LASTEXITCODE)" -ForegroundColor Red; exit 1 } }

Paso "1/6 Repositorio $repo"
gh repo view $repo --json name 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    gh repo create $repo --public --description "Hora Dorada: versión beta en Godot 4.7 (UTH IDGS 8-2)"
    Revisar "crear el repositorio"
} else { Write-Host "Ya existe." }
if (-not ((git remote) -contains "origin")) { git remote add origin "https://github.com/$repo.git" }

Paso "2/6 Subir las ramas"
foreach ($b in @("main", "feature/nucleo-sol-sombra", "feature/enemigos", "feature/interfaz-demo", "feature/mercado", "feature/pruebas-beta")) {
    git push -u origin $b
    Revisar "subir $b"
}

Paso "3/6 Etiquetas y tarjetas (issues)"
gh label create joel --repo $repo --color F06733 --description "Tarjeta de Joel" --force | Out-Null
gh label create jorge --repo $repo --color 2E86C1 --description "Tarjeta de Jorge" --force | Out-Null
gh label create beta --repo $repo --color FFD36B --description "Versión beta 0.9" --force | Out-Null
$existentes = @(gh issue list --repo $repo --state all --limit 100 --json title | ConvertFrom-Json)
foreach ($i in $datos.issues) {
    if ($existentes.title -contains $i.titulo) { Write-Host "Ya existe: $($i.titulo)"; continue }
    gh issue create --repo $repo --title $i.titulo --body-file "$PSScriptRoot\$($i.archivo)" --label $i.etiqueta --label beta
    Revisar "crear la tarjeta $($i.titulo)"
}

Paso "4/6 Pull Requests de Joel"
foreach ($p in $datos.prs) {
    if ($p.autor -ne "joel") { continue }
    $ya = gh pr list --repo $repo --head $p.rama --state all --json number --jq 'length'
    if ([int]$ya -gt 0) { Write-Host "Ya existe el PR de $($p.rama)"; continue }
    gh pr create --repo $repo --base $p.base --head $p.rama --title $p.titulo --body-file "$PSScriptRoot\$($p.archivo)" --label joel
    Revisar "abrir el PR de $($p.rama)"
}

Paso "5/6 Invitar a Jorge (JMartinez-D) como colaborador"
gh api -X PUT "repos/$repo/collaborators/JMartinez-D" -f permission=push | Out-Null
Revisar "invitar a Jorge"

Paso "6/6 Release con el ejecutable (118 MB, tarda un poco)"
gh release view v0.9.0-beta --repo $repo 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    gh release create v0.9.0-beta "build\HoraDorada_Beta.exe" --repo $repo --target feature/pruebas-beta --title "Hora Dorada 0.9.0-beta" --notes-file "$PSScriptRoot\release.md"
    Revisar "crear el Release"
} else { Write-Host "Ya existe." }

Paso "Listo"
gh pr list --repo $repo --state all
Write-Host ""
Write-Host "Repositorio: https://github.com/$repo"
Write-Host "Release:     https://github.com/$repo/releases/tag/v0.9.0-beta"
Write-Host "Jorge abre sus 2 PR aquí (después de aceptar la invitación que le llegó por correo):"
Write-Host "  https://github.com/$repo/compare/feature/nucleo-sol-sombra...feature/enemigos?expand=1"
Write-Host "  https://github.com/$repo/compare/feature/enemigos...feature/interfaz-demo?expand=1"
Write-Host "Los textos para esos PR están en herramientas\publicar\pr_2.md y pr_3.md"
