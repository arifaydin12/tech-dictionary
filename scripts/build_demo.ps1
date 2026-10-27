<#
.SYNOPSIS
  Builds the Firebase-free demo of Tech Dictionary and copies it into docs/ so
  GitHub Pages (branch main, folder /docs) can serve it.

.DESCRIPTION
  Runs `flutter build web --release --dart-define=DEMO_MODE=true` with the
  repository name as base href, then replaces the contents of docs/ with the
  build output. Requires `flutter` on PATH.

.PARAMETER BaseHref
  URL path the site is served from. Must start and end with a slash.
  Default: /tech-dictionary/ (https://<user>.github.io/tech-dictionary/).

.EXAMPLE
  ./scripts/build_demo.ps1
  ./scripts/build_demo.ps1 -BaseHref /my-fork/
#>
param(
  [string]$BaseHref = '/tech-dictionary/'
)

$ErrorActionPreference = 'Stop'

if ($BaseHref -notmatch '^/.*/$' -and $BaseHref -ne '/') {
  throw "BaseHref must start and end with '/', for example /tech-dictionary/"
}

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$build = Join-Path $root 'build/web'
$docs = Join-Path $root 'docs'

Push-Location $root
try {
  flutter pub get
  if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed' }

  flutter build web --release `
    --dart-define=DEMO_MODE=true `
    --base-href $BaseHref `
    --no-web-resources-cdn `
    --no-wasm-dry-run
  if ($LASTEXITCODE -ne 0) { throw 'flutter build web failed' }

  if (-not (Test-Path (Join-Path $build 'index.html'))) {
    throw "Build output not found in $build"
  }

  # Replace the previous demo. Only the contents of docs/ are removed.
  if (-not (Test-Path $docs)) { New-Item -ItemType Directory -Path $docs | Out-Null }
  Get-ChildItem -LiteralPath $docs -Force | Remove-Item -Recurse -Force
  Copy-Item -Path (Join-Path $build '*') -Destination $docs -Recurse -Force

  # The JavaScript build never loads the WebAssembly renderers or the debug
  # symbol files; dropping them keeps the repository small.
  $canvaskit = Join-Path $docs 'canvaskit'
  if (Test-Path $canvaskit) {
    Get-ChildItem -LiteralPath $canvaskit -Recurse -File |
      Where-Object { $_.Name -match '^(skwasm|wimp)' -or $_.Extension -eq '.symbols' } |
      Remove-Item -Force
  }
  Get-ChildItem -LiteralPath $docs -Filter '*.symbols' -File -ErrorAction SilentlyContinue |
    Remove-Item -Force

  # Stop GitHub Pages from running Jekyll over the output.
  New-Item -ItemType File -Path (Join-Path $docs '.nojekyll') -Force | Out-Null

  $size = (Get-ChildItem -LiteralPath $docs -Recurse -File | Measure-Object Length -Sum).Sum
  Write-Host ("Demo written to docs/ ({0:N1} MB). Base href: {1}" -f ($size / 1MB), $BaseHref)
  Write-Host 'Commit docs/ and push; Pages serves branch main, folder /docs.'
}
finally {
  Pop-Location
}
