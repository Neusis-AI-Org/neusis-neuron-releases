# neusis-neuron-mcp installer for Windows.
#
# Usage:
#   irm https://neusis-ai-org.github.io/neusis-neuron-releases/install.ps1 | iex
#
# Environment variables:
#   VERSION      Pin a specific release version (default: latest).
#   INSTALL_DIR  Install location (default: $HOME\.local\bin).
#
# Re-running this script upgrades an existing install in place.

$ErrorActionPreference = 'Stop'

$Repo = 'Neusis-AI-Org/neusis-neuron-releases'
$Binary = 'neusis-neuron-mcp'
$InstallDir = if ($env:INSTALL_DIR) { $env:INSTALL_DIR } else { Join-Path $HOME '.local\bin' }

switch ($env:PROCESSOR_ARCHITECTURE) {
  'AMD64' { $Arch = 'x86_64' }
  'ARM64' { $Arch = 'arm64' }
  default { Write-Error "Unsupported arch: $($env:PROCESSOR_ARCHITECTURE). Builds target amd64/arm64 only."; exit 1 }
}

$Version = $env:VERSION
if (-not $Version) {
  $latest = Invoke-RestMethod "https://api.github.com/repos/$Repo/releases/latest"
  $Version = $latest.tag_name
}
$Version = $Version -replace '^v', ''

$Archive = "${Binary}_Windows_${Arch}.zip"
$Url = "https://github.com/$Repo/releases/download/v$Version/$Archive"

Write-Host "Downloading $Binary v$Version (Windows/$Arch)..."
$Tmp = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid())
New-Item -ItemType Directory -Path $Tmp -Force | Out-Null
try {
  $ZipPath = Join-Path $Tmp $Archive
  Invoke-WebRequest -Uri $Url -OutFile $ZipPath
  Expand-Archive -Path $ZipPath -DestinationPath $Tmp -Force

  New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
  # Copy-Item -Force overwrites in place, so reruns upgrade an existing binary.
  Copy-Item -Force (Join-Path $Tmp "$Binary.exe") (Join-Path $InstallDir "$Binary.exe")
  Write-Host "Installed: $(Join-Path $InstallDir "$Binary.exe")"
}
finally {
  Remove-Item -Recurse -Force $Tmp -ErrorAction SilentlyContinue
}

$pathEntries = $env:PATH -split ';'
if ($pathEntries -notcontains $InstallDir) {
  Write-Host ''
  Write-Host "Warning: $InstallDir is not on your PATH."
  Write-Host 'Add it with:'
  Write-Host "  [Environment]::SetEnvironmentVariable('PATH', `"$InstallDir;`" + `$env:PATH, 'User')"
}

Write-Host ''
Write-Host 'Next steps -----------------------------------------------------'
Write-Host '1. Create a fine-grained GitHub token with Contents: Read on your'
Write-Host '   KB repository:'
Write-Host '   https://github.com/settings/personal-access-tokens/new'
Write-Host ''
Write-Host "2. Register the server in neusis-code's neusiscode.json:"
Write-Host ''
@'
   {
     "mcp": {
       "neusis-neuron": {
         "type": "local",
         "command": ["neusis-neuron-mcp", "stdio", "--kb-repo", "OWNER/REPO"],
         "environment": { "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_your_token" },
         "enabled": true
       }
     }
   }
'@ | Write-Host
