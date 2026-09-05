# Build both mdBook trees into site/{ru,en} plus a language index.
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

function Build-Book([string]$Config) {
    Copy-Item -Force $Config book.toml
    mdbook build
}

Build-Book book-ru.toml
Build-Book book-en.toml
Remove-Item -Force book.toml -ErrorAction SilentlyContinue

New-Item -ItemType Directory -Force -Path site | Out-Null
@'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Modus plugins</title>
  <meta http-equiv="refresh" content="0; url=ru/">
  <link rel="canonical" href="ru/">
  <style>
    body { font-family: system-ui, sans-serif; max-width: 36rem; margin: 3rem auto; padding: 0 1rem; line-height: 1.5; }
    a { color: #0b57d0; }
  </style>
</head>
<body>
  <h1>Modus plugins</h1>
  <p>Guest-surface docs (ABI 2).</p>
  <ul>
    <li><a href="ru/">Русский</a></li>
    <li><a href="en/">English</a></li>
  </ul>
  <p><a href="https://github.com/CaptainGnome/modus-docs">Source on GitHub</a></p>
</body>
</html>
'@ | Set-Content -Encoding utf8 site/index.html

Write-Host "Built site/ru and site/en"
