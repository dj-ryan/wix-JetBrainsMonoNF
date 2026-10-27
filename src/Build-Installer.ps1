param(
    # Nerd Fonts version to package (e.g. 3.5.1). Defaults to the latest release.
    [string]$Version
)

$ErrorActionPreference = 'Stop'

$headers = @{}
if ($env:GH_TOKEN) {
    $headers.Authorization = "Bearer $env:GH_TOKEN"
}
$releaseUri = if ($Version) {
    "https://api.github.com/repos/ryanoasis/nerd-fonts/releases/tags/v$Version"
} else {
    'https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest'
}
$release = Invoke-RestMethod -Uri $releaseUri -Headers $headers
$version = $release.tag_name.TrimStart('v')
$zipAsset = $release.assets | Where-Object name -EQ 'JetBrainsMono.zip'
$sumsAsset = $release.assets | Where-Object name -EQ 'SHA-256.txt'
if (-not $zipAsset -or -not $sumsAsset) {
    throw "Release v$version is missing JetBrainsMono.zip or SHA-256.txt"
}

Invoke-WebRequest `
    -Uri $zipAsset.browser_download_url `
    -OutFile $PSScriptRoot\JetBrainsMono.zip
Invoke-WebRequest `
    -Uri $sumsAsset.browser_download_url `
    -OutFile $PSScriptRoot\SHA-256.txt

$expected = Get-Content -Path $PSScriptRoot\SHA-256.txt |
    Where-Object { $_ -match '^([0-9a-f]{64})\s+JetBrainsMono\.zip$' } |
    ForEach-Object { $Matches[1] }
$actual = (Get-FileHash -Path $PSScriptRoot\JetBrainsMono.zip -Algorithm SHA256).Hash
if (-not $expected -or $actual -ne $expected) {
    throw "SHA-256 mismatch for JetBrainsMono.zip (expected '$expected', got '$actual')"
}

Remove-Item `
    -Path $PSScriptRoot\Fonts `
    -Recurse `
    -Force `
    -ErrorAction SilentlyContinue
New-Item `
    -Path $PSScriptRoot\Fonts `
    -ItemType Directory
Expand-Archive `
    -Path $PSScriptRoot\JetBrainsMono.zip `
    -DestinationPath $PSScriptRoot\Fonts `
    -Force
Remove-Item `
    -Path $PSScriptRoot\Fonts\* `
    -Exclude *.ttf

(Get-Content -Path $PSScriptRoot\Package.xml) `
    -creplace '(\bVersion=)"[\d.]+"', ('$1"' + $version + '"') `
    > $PSScriptRoot\Package.wxs

pandoc -s -i $PSScriptRoot\..\License.txt -o $PSScriptRoot\License.rtf

dotnet build -c Release $PSScriptRoot\JetBrainsMono.wixproj
if ($LASTEXITCODE -ne 0) {
    throw "dotnet build failed with exit code $LASTEXITCODE"
}

if ($env:GITHUB_OUTPUT) {
    "version=$version" >> $env:GITHUB_OUTPUT
}
