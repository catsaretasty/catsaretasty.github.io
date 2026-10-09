<#
.SYNOPSIS
    Builds the site, or serves it locally for preview.

.DESCRIPTION
    Installs any missing gems from the repo Gemfile, then runs Jekyll against
    the repo root. By default this does a one-off build in safe mode, matching
    the GitHub Pages build. With -Serve it starts a local preview server that
    rebuilds and reloads the page whenever a file changes.
    Output goes to the gitignored `_site` folder.

.PARAMETER Serve
    Start a local preview server instead of doing a one-off build.

.PARAMETER Port
    Local port for the preview server. Used only with -Serve.

.EXAMPLE
    .\scripts\build.ps1
    .\scripts\build.ps1 -Serve
    .\scripts\build.ps1 -Serve -Port 4001
#>
param(
    [switch]$Serve,
    [int]$Port = 4000
)

# Stop on the first failing command.
$ErrorActionPreference = 'Stop'

# Repo root is the parent of this script's folder.
$root = Split-Path -Parent $PSScriptRoot

# Point Bundler at the repo Gemfile so the script works from any directory.
$env:BUNDLE_GEMFILE = Join-Path $root 'Gemfile'

# Install gems only when the Gemfile's dependencies are not already satisfied.
bundle check *> $null
if ($LASTEXITCODE -ne 0) {
    bundle install
    if ($LASTEXITCODE -ne 0) { throw 'bundle install failed.' }
}

# Shared arguments: explicit source and destination so the current directory does not matter.
$jekyllArgs = @(
    '--source', $root,
    '--destination', (Join-Path $root '_site')
)

if ($Serve) {
    # Preview server with live reload; runs until stopped with Ctrl+C.
    bundle exec jekyll serve @jekyllArgs --port $Port --livereload
}
else {
    # One-off build in safe mode, the same mode GitHub Pages uses.
    bundle exec jekyll build @jekyllArgs --safe
    if ($LASTEXITCODE -ne 0) { throw 'jekyll build failed.' }
}
