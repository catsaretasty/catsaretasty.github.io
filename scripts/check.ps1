<#
.SYNOPSIS
    Builds the site into a temporary folder and runs consistency checks on the output.

.DESCRIPTION
    Runs a one-off safe-mode Jekyll build, the same mode GitHub Pages uses, into a
    temporary folder so a running preview server's `_site` folder is left alone.
    Then checks the built site:
      - Build:        the Jekyll build succeeds.
      - Bookmarklet:  the bookmarklet link on the TastyPlug page matches bookmarklet.txt
                      exactly, after HTML-decoding the attribute.
      - 404 links:    every href and src in the built 404 page is absolute.
      - Links:        every internal href and src in the built site points at a page or
                      file that exists, and every #anchor points at an id on that page.
      - Command data: _data/tastybot-commands.json parses as JSON.
    Prints one PASS, FAIL or SKIP line per check, with details under each failure.
    Exits with 0 when every check passes and 1 otherwise. The temporary build folder
    is deleted before exit.

.PARAMETER BookmarkletFile
    Local bookmarklet.txt to compare against, such as one from a local TastyPlug build.
    When omitted, the live bookmarklet.txt is downloaded and used.

.EXAMPLE
    .\scripts\check.ps1
    .\scripts\check.ps1 -BookmarkletFile ..\tastyplug-wavez\dist\bookmarklet.txt
#>
param(
    [string]$BookmarkletFile
)

# Stop on the first failing cmdlet; native command failures are checked through $LASTEXITCODE.
$ErrorActionPreference = 'Stop'

# Repo root is the parent of this script's folder.
$root = Split-Path -Parent $PSScriptRoot

# Live location of the bookmarklet text, used when -BookmarkletFile is not given.
$liveBookmarkletUrl = 'https://tastyplug.tastycat.org/bookmarklet.txt'

# Site URL prefixes that count as links into this site. The site URL is read from
# _config.yml; both schemes are accepted so http links are still resolved and checked.
$siteUrl = (Select-String -Path (Join-Path $root '_config.yml') -Pattern '^url:\s*(\S+)').Matches[0].Groups[1].Value.TrimEnd('/')
$siteHost = $siteUrl -replace '^https?://', ''
$sitePrefixes = @("https://$siteHost", "http://$siteHost")

# Paths under these prefixes are served by other GitHub Pages sites on the same domain,
# so they are not part of this build and are not checked.
$externalPathPrefixes = @('/emotes/')

# Results collected by Add-Result and printed at the end.
$results = [System.Collections.Generic.List[object]]::new()

# Records the outcome of one check. Status is PASS, FAIL or SKIP; Details is a list of
# lines printed under the check's status line.
function Add-Result {
    param(
        [string]$Name,
        [string]$Status,
        [string[]]$Details = @()
    )
    $results.Add([pscustomobject]@{ Name = $Name; Status = $Status; Details = $Details })
}

# Returns every href and src attribute value in an HTML string, HTML-decoded.
# Both double- and single-quoted attributes are matched.
function Get-LinkValues {
    param([string]$Html)
    $pattern = '\b(?:href|src)\s*=\s*(?:"([^"]*)"|''([^'']*)'')'
    foreach ($m in [regex]::Matches($Html, $pattern)) {
        $raw = if ($m.Groups[1].Success) { $m.Groups[1].Value } else { $m.Groups[2].Value }
        [System.Net.WebUtility]::HtmlDecode($raw)
    }
}

# Maps a site path (such as /tastyplug/ or /css/tastycat.css) to the built file that
# serves it, the same way GitHub Pages does: a trailing slash means index.html, and a
# path without an extension may also be served from path.html or path/index.html.
# Returns $null when no built file matches.
function Resolve-BuiltFile {
    param(
        [string]$BuildDir,
        [string]$SitePath
    )
    $relative = [System.Uri]::UnescapeDataString($SitePath).TrimStart('/') -replace '/', '\'
    $base = Join-Path $BuildDir $relative
    $candidates = if ($SitePath.EndsWith('/')) {
        @(Join-Path $base 'index.html')
    }
    else {
        @($base, "$base.html", (Join-Path $base 'index.html'))
    }
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    }
    return $null
}

# Returns the set of id and name attribute values in an HTML file, used to check #anchors.
# Results are cached per file because the same pages are linked many times.
$anchorCache = @{}
function Get-AnchorIds {
    param([string]$File)
    if (-not $anchorCache.ContainsKey($File)) {
        $html = Get-Content -LiteralPath $File -Raw
        $ids = [System.Collections.Generic.HashSet[string]]::new()
        foreach ($m in [regex]::Matches($html, '\b(?:id|name)\s*=\s*"([^"]*)"')) {
            [void]$ids.Add([System.Net.WebUtility]::HtmlDecode($m.Groups[1].Value))
        }
        $anchorCache[$File] = $ids
    }
    return $anchorCache[$File]
}

# Temporary build folder outside the repo, unique per run.
$buildDir = Join-Path ([System.IO.Path]::GetTempPath()) ("catsaretasty-check-" + [guid]::NewGuid().ToString('N'))

try {
    # ---------------------------------------------------------------- Build
    # Point Bundler at the repo Gemfile so the script works from any directory, and
    # install gems only when the Gemfile's dependencies are not already satisfied.
    $env:BUNDLE_GEMFILE = Join-Path $root 'Gemfile'
    bundle check *> $null
    if ($LASTEXITCODE -ne 0) {
        bundle install
        if ($LASTEXITCODE -ne 0) { throw 'bundle install failed.' }
    }

    # Safe-mode build into the temporary folder. Output is captured so it can be shown
    # only when the build fails.
    $buildOutput = bundle exec jekyll build --source $root --destination $buildDir --safe 2>&1
    $buildOk = ($LASTEXITCODE -eq 0) -and (Test-Path -LiteralPath $buildDir)
    if ($buildOk) {
        Add-Result 'Build' 'PASS'
    }
    else {
        Add-Result 'Build' 'FAIL' ($buildOutput | ForEach-Object { "$_" } | Select-Object -Last 15)
    }

    # ---------------------------------------------------------------- Bookmarklet
    # Expected text: the bookmarklet file's single line, without its trailing line break.
    $expected = $null
    $source = $null
    try {
        if ($BookmarkletFile) {
            $source = (Resolve-Path -LiteralPath $BookmarkletFile).Path
            $expected = Get-Content -LiteralPath $source -Raw
        }
        else {
            $source = $liveBookmarkletUrl
            $response = Invoke-WebRequest -UseBasicParsing -Uri $liveBookmarkletUrl
            # Text responses arrive as a string; other content types arrive as bytes.
            $expected = if ($response.Content -is [byte[]]) {
                [System.Text.Encoding]::UTF8.GetString($response.Content)
            }
            else {
                $response.Content
            }
        }
        $expected = $expected.TrimEnd("`r", "`n")
    }
    catch {
        Add-Result 'Bookmarklet' 'FAIL' @("Could not read $source", $_.Exception.Message)
    }

    if ($null -ne $expected) {
        if (-not $buildOk) {
            Add-Result 'Bookmarklet' 'SKIP' @('Build failed.')
        }
        else {
            $page = Join-Path $buildDir 'tastyplug\index.html'
            $html = Get-Content -LiteralPath $page -Raw
            $m = [regex]::Match($html, '<a\b[^>]*\bclass="[^"]*\bbookmarklet\b[^"]*"[^>]*\bhref="([^"]*)"')
            if (-not $m.Success) {
                Add-Result 'Bookmarklet' 'FAIL' @('No bookmarklet link found on the TastyPlug page.')
            }
            else {
                $actual = [System.Net.WebUtility]::HtmlDecode($m.Groups[1].Value)
                if ($actual -ceq $expected) {
                    Add-Result 'Bookmarklet' 'PASS' @("Matches $source ($($actual.Length) chars).")
                }
                else {
                    # Report the first differing character position to make the mismatch easy to find.
                    $limit = [Math]::Min($actual.Length, $expected.Length)
                    $diffAt = 0
                    while ($diffAt -lt $limit -and $actual[$diffAt] -ceq $expected[$diffAt]) { $diffAt++ }
                    Add-Result 'Bookmarklet' 'FAIL' @(
                        "Does not match $source.",
                        "Page: $($actual.Length) chars, file: $($expected.Length) chars, first difference at char $diffAt."
                    )
                }
            }
        }
    }

    # ---------------------------------------------------------------- 404 links
    # The 404 page is served for any missing path, so a relative link would resolve
    # against that path. Every href and src must have a scheme or be protocol-relative;
    # fragment-only links stay on the page and are allowed.
    if (-not $buildOk) {
        Add-Result '404 links' 'SKIP' @('Build failed.')
    }
    else {
        $notFoundHtml = Get-Content -LiteralPath (Join-Path $buildDir '404.html') -Raw
        $relativeLinks = Get-LinkValues $notFoundHtml | Where-Object {
            $_ -notmatch '^[a-zA-Z][a-zA-Z0-9+.-]*:' -and $_ -notmatch '^//' -and $_ -notmatch '^#'
        } | Sort-Object -Unique
        if ($relativeLinks) {
            Add-Result '404 links' 'FAIL' ($relativeLinks | ForEach-Object { "Not absolute: $_" })
        }
        else {
            Add-Result '404 links' 'PASS'
        }
    }

    # ---------------------------------------------------------------- Links
    # Every internal href and src in every built HTML page must resolve to a built file,
    # and any #anchor must match an id or name on the target page.
    if (-not $buildOk) {
        Add-Result 'Links' 'SKIP' @('Build failed.')
    }
    else {
        $broken = [System.Collections.Generic.List[string]]::new()
        $checked = 0
        $pages = Get-ChildItem -LiteralPath $buildDir -Recurse -File -Filter '*.html'
        foreach ($pageFile in $pages) {
            $html = Get-Content -LiteralPath $pageFile.FullName -Raw
            # Site path of this page, used to resolve relative links and fragment-only links.
            $pagePath = '/' + ($pageFile.FullName.Substring($buildDir.Length).TrimStart('\') -replace '\\', '/')
            $pageLabel = $pagePath

            foreach ($link in (Get-LinkValues $html | Sort-Object -Unique)) {
                $target = $link.Trim()
                if ($target -eq '' -or $target -eq '#') { continue }

                # Turn links into this site into site paths; skip links to anywhere else.
                $sitePrefix = $sitePrefixes | Where-Object { $target -eq $_ -or $target.StartsWith("$_/") -or $target.StartsWith("$_#") } | Select-Object -First 1
                if ($sitePrefix) {
                    $target = $target.Substring($sitePrefix.Length)
                    if ($target -eq '' -or $target.StartsWith('#')) { $target = "/$target" }
                }
                elseif ($target -match '^[a-zA-Z][a-zA-Z0-9+.-]*:' -or $target.StartsWith('//')) {
                    continue
                }

                # Split off the fragment and drop any query string.
                $fragment = $null
                $hashAt = $target.IndexOf('#')
                if ($hashAt -ge 0) {
                    $fragment = $target.Substring($hashAt + 1)
                    $target = $target.Substring(0, $hashAt)
                }
                $queryAt = $target.IndexOf('?')
                if ($queryAt -ge 0) { $target = $target.Substring(0, $queryAt) }

                # Resolve to an absolute site path: empty means this page, a leading slash is
                # already absolute, anything else is relative to this page's folder.
                if ($target -eq '') {
                    $sitePath = $pagePath
                }
                elseif ($target.StartsWith('/')) {
                    $sitePath = $target
                }
                else {
                    $folder = $pagePath.Substring(0, $pagePath.LastIndexOf('/') + 1)
                    $sitePath = ([System.Uri]::new([System.Uri]::new("http://site$folder"), $target)).AbsolutePath
                }

                # Paths served by other Pages sites on the same domain are not in this build.
                if ($externalPathPrefixes | Where-Object { $sitePath.StartsWith($_) }) { continue }

                $checked++
                $file = Resolve-BuiltFile -BuildDir $buildDir -SitePath $sitePath
                if (-not $file) {
                    $broken.Add("${pageLabel}: missing $link")
                    continue
                }
                if ($fragment -and $file.EndsWith('.html')) {
                    $id = [System.Uri]::UnescapeDataString($fragment)
                    if (-not (Get-AnchorIds $file).Contains($id)) {
                        $broken.Add("${pageLabel}: no #$id in $link")
                    }
                }
            }
        }
        if ($broken.Count -gt 0) {
            Add-Result 'Links' 'FAIL' $broken
        }
        else {
            Add-Result 'Links' 'PASS' @("$checked internal links across $($pages.Count) pages.")
        }
    }

    # ---------------------------------------------------------------- Command data
    # The TastyBot command list must be valid JSON for the /tastybot page to build from it.
    $commandsFile = Join-Path $root '_data\tastybot-commands.json'
    try {
        Get-Content -LiteralPath $commandsFile -Raw | ConvertFrom-Json | Out-Null
        Add-Result 'Command data' 'PASS'
    }
    catch {
        Add-Result 'Command data' 'FAIL' @($_.Exception.Message)
    }
}
finally {
    # Remove the temporary build folder whatever happened above.
    if (Test-Path -LiteralPath $buildDir) {
        Remove-Item -LiteralPath $buildDir -Recurse -Force
    }
}

# ---------------------------------------------------------------- Report
# One status line per check, with its details indented underneath.
foreach ($result in $results) {
    $color = switch ($result.Status) { 'PASS' { 'Green' } 'FAIL' { 'Red' } default { 'Yellow' } }
    Write-Host ("[{0}] {1}" -f $result.Status, $result.Name) -ForegroundColor $color
    foreach ($detail in $result.Details) {
        Write-Host "       $detail"
    }
}

# Non-zero exit when any check failed, so the script can gate other steps.
$failed = @($results | Where-Object Status -eq 'FAIL').Count
if ($failed -gt 0) {
    Write-Host "$failed check(s) failed." -ForegroundColor Red
    exit 1
}
Write-Host 'All checks passed.' -ForegroundColor Green
exit 0
