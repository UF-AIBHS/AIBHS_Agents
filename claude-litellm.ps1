# Run Claude Code routed through the LiteLLM proxy defined in the .env next to this script.
# PowerShell equivalent of ./claude-litellm, for Windows users without Git Bash.
# Expects ANTHROPIC_API_KEY and LITELLM_BASE_URL in .env.
#
# Usage:  .\claude-litellm.ps1 [any claude arguments]

$ErrorActionPreference = 'Stop'

# Resolve .env relative to this script, not the caller's location
$EnvFile = Join-Path $PSScriptRoot '.env'
if (-not (Test-Path $EnvFile)) {
    Write-Error "claude-litellm: no .env next to script ($PSScriptRoot)"
    exit 1
}

Get-Content $EnvFile | ForEach-Object {
    if ($_ -match '^\s*([^#=]+?)\s*=\s*(.*)$') {
        Set-Item -Path "env:$($Matches[1])" -Value $Matches[2].Trim('"')
    }
}

if (-not $env:LITELLM_BASE_URL)  { Write-Error 'LITELLM_BASE_URL missing from .env';  exit 1 }
if (-not $env:ANTHROPIC_API_KEY) { Write-Error 'ANTHROPIC_API_KEY missing from .env'; exit 1 }

# Claude Code validates ANTHROPIC_API_KEY against Anthropic's key format, which a
# Navigator key will fail. ANTHROPIC_AUTH_TOKEN is passed through as a bearer token,
# which is what the proxy expects.
$env:ANTHROPIC_BASE_URL   = $env:LITELLM_BASE_URL
$env:ANTHROPIC_AUTH_TOKEN = $env:ANTHROPIC_API_KEY
Remove-Item env:ANTHROPIC_API_KEY

# Claude Code defaults to model names the Navigator key is not provisioned for,
# which comes back as "403 team not allowed to access model". Values set in .env
# are already loaded above and win; these are only fallbacks.
if (-not $env:ANTHROPIC_MODEL)            { $env:ANTHROPIC_MODEL            = 'claude-4.6-sonnet' }
if (-not $env:ANTHROPIC_SMALL_FAST_MODEL) { $env:ANTHROPIC_SMALL_FAST_MODEL = 'claude-4.5-haiku'  }

# Campus/corporate firewalls often block Claude Code's telemetry and analytics
# hosts, which surfaces as "connection refused". Only the proxy is needed.
$env:CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = '1'

# PowerShell has no exec; claude runs as a child process.
& claude @args
