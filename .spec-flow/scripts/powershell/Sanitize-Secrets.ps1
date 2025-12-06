<#
.SYNOPSIS
    Secret sanitization utility for Spec-Flow reports.

.DESCRIPTION
    Removes sensitive information from text before writing to documentation files.
    Prevents accidental secret exposure in reports, summaries, and artifacts.

    Detects and redacts:
    - API keys (api_key, apikey, api-key)
    - Tokens (token, bearer, auth_token)
    - Passwords (password, pwd, passwd)
    - Database URLs (postgresql://, mysql://, mongodb://)
    - URLs with embedded credentials (https://user:pass@host)
    - JWT tokens (eyJ... pattern)
    - AWS keys (AKIA..., aws_secret_access_key)
    - Generic secrets (secret=value patterns)
    - Private keys (-----BEGIN PRIVATE KEY-----)
    - GitHub tokens (ghp_, gho_, etc.)
    - Vercel tokens (vercel_token)
    - Railway tokens (railway_token)

.PARAMETER InputText
    The text content to sanitize. Can be a string or array of strings.

.PARAMETER Path
    Path to file to sanitize. Reads file content and sanitizes.

.PARAMETER PassThru
    Returns the sanitized content. Default behavior.

.EXAMPLE
    Sanitize-Secrets -InputText "API_KEY=abc123xyz"
    Returns: "API_KEY=***REDACTED***"

.EXAMPLE
    "password=secret123" | Sanitize-Secrets
    Returns: "password=***REDACTED***"

.EXAMPLE
    Sanitize-Secrets -Path "report.md"
    Reads and sanitizes report.md content.

.EXAMPLE
    Get-Content "input.txt" | Sanitize-Secrets | Set-Content "output.txt"
    Sanitizes file content via pipeline.

.NOTES
    Author: Spec-Flow Security
    Version: 1.0.0
    Redaction Strategy:
      - Preserves variable names and structure
      - Replaces values with: ***REDACTED***
      - Keeps URLs readable but removes credentials
      - Maintains JSON/YAML structure
#>

[CmdletBinding(SupportsShouldProcess = $false)]
param(
    [Parameter(
        Mandatory = $false,
        ValueFromPipeline = $true,
        Position = 0
    )]
    [string[]]$InputText,

    [Parameter(Mandatory = $false)]
    [string]$Path
)

begin {
    # Redaction marker
    $Script:Redacted = "***REDACTED***"

    # Aggregate input from pipeline
    $Script:ContentLines = @()

    #
    # Sanitize-ApiKeys - Redact API key values
    #
    function Sanitize-ApiKeys {
        param([string]$Content)

        # Case-insensitive API key patterns
        $Content = $Content -replace '(?i)(api[_-]?key|apikey)[\s]*[=:]\s*["]?[^"&'' \n]+["]?', "`$1=$Script:Redacted"

        return $Content
    }

    #
    # Sanitize-Tokens - Redact bearer tokens and auth tokens
    #
    function Sanitize-Tokens {
        param([string]$Content)

        # Token patterns
        $Content = $Content -replace '(?i)(token|bearer|auth[_-]?token)[\s]*[=:]\s*["]?[^"&'' \n]+["]?', "`$1=$Script:Redacted"

        return $Content
    }

    #
    # Sanitize-Passwords - Redact password values
    #
    function Sanitize-Passwords {
        param([string]$Content)

        # Password patterns
        $Content = $Content -replace '(?i)(password|passwd|pwd)[\s]*[=:]\s*["]?[^"&'' \n]+["]?', "`$1=$Script:Redacted"

        return $Content
    }

    #
    # Sanitize-DatabaseUrls - Redact credentials in database URLs
    #
    function Sanitize-DatabaseUrls {
        param([string]$Content)

        # Database URL patterns
        $Content = $Content -replace '(?i)(postgresql|mysql|mongodb|redis)://[^:]+:[^@]+@', '$1://***:***@'

        return $Content
    }

    #
    # Sanitize-UrlsWithCreds - Redact credentials in HTTP(S) URLs
    #
    function Sanitize-UrlsWithCreds {
        param([string]$Content)

        # HTTP(S) URL with credentials
        $Content = $Content -replace '(?i)https?://[^:]+:[^@]+@', 'https://***:***@'

        return $Content
    }

    #
    # Sanitize-JwtTokens - Redact JWT tokens
    #
    function Sanitize-JwtTokens {
        param([string]$Content)

        # JWT pattern (starts with eyJ)
        $Content = $Content -replace 'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+', '***REDACTED_JWT***'

        return $Content
    }

    #
    # Sanitize-AwsKeys - Redact AWS access keys and secrets
    #
    function Sanitize-AwsKeys {
        param([string]$Content)

        # AWS access key ID (starts with AKIA)
        $Content = $Content -replace 'AKIA[0-9A-Z]{16}', '***REDACTED_AWS_KEY***'

        # AWS secret access key
        $Content = $Content -replace '(?i)(aws_secret_access_key)[\s]*[=:]\s*["]?[^"&'' \n]+["]?', "`$1=$Script:Redacted"

        return $Content
    }

    #
    # Sanitize-GithubTokens - Redact GitHub personal access tokens
    #
    function Sanitize-GithubTokens {
        param([string]$Content)

        # GitHub token patterns (ghp_, gho_, ghs_, etc.)
        $Content = $Content -replace 'gh[ps]_[A-Za-z0-9_]{36,255}', '***REDACTED_GITHUB_TOKEN***'

        return $Content
    }

    #
    # Sanitize-DeploymentTokens - Redact Vercel, Railway, and deployment tokens
    #
    function Sanitize-DeploymentTokens {
        param([string]$Content)

        # Vercel tokens
        $Content = $Content -replace '(?i)(vercel[_-]?token)[\s]*[=:]\s*["]?[^"&'' \n]+["]?', "`$1=$Script:Redacted"

        # Railway tokens
        $Content = $Content -replace '(?i)(railway[_-]?token)[\s]*[=:]\s*["]?[^"&'' \n]+["]?', "`$1=$Script:Redacted"

        # Generic deploy tokens
        $Content = $Content -replace '(?i)(deploy[_-]?token)[\s]*[=:]\s*["]?[^"&'' \n]+["]?', "`$1=$Script:Redacted"

        return $Content
    }

    #
    # Sanitize-PrivateKeys - Redact private key content
    #
    function Sanitize-PrivateKeys {
        param([string]$Content)

        # Private key blocks
        $Content = $Content -replace '(?s)-----BEGIN[^-]*PRIVATE KEY-----[^-]+-----END[^-]*PRIVATE KEY-----', '***REDACTED_PRIVATE_KEY***'

        return $Content
    }

    #
    # Sanitize-GenericSecrets - Redact generic secret patterns
    #
    function Sanitize-GenericSecrets {
        param([string]$Content)

        # Generic secret patterns
        $Content = $Content -replace '(?i)(secret|credential)[\s]*[=:]\s*["]?[^"&'' \n]+["]?', "`$1=$Script:Redacted"

        return $Content
    }

    #
    # Sanitize-EnvVars - Redact environment variable values
    #
    function Sanitize-EnvVars {
        param([string]$Content)

        # Specific sensitive env vars
        $sensitiveVars = @(
            "DATABASE_URL",
            "DIRECT_URL",
            "OPENAI_API_KEY",
            "CLERK_SECRET_KEY",
            "HCAPTCHA_SECRET_KEY",
            "JWT_SECRET",
            "SECRET_KEY",
            "REDIS_URL",
            "DOPPLER_TOKEN",
            "GITHUB_TOKEN",
            "VERCEL_TOKEN",
            "RAILWAY_TOKEN"
        )

        foreach ($var in $sensitiveVars) {
            # Match VAR=value or VAR="value" or VAR: value
            $Content = $Content -replace "(?i)($var)[\s]*[=:]\s*['`"]?[^'`"& \n]+['`"]?", "`$1=$Script:Redacted"
        }

        return $Content
    }
}

process {
    # Handle -Path parameter
    if ($Path) {
        if (-not (Test-Path $Path)) {
            Write-Error "File not found: $Path"
            return
        }

        $Script:ContentLines += Get-Content -Path $Path -Raw
    }
    # Handle pipeline input
    elseif ($InputText) {
        $Script:ContentLines += $InputText
    }
}

end {
    # Join all content
    $content = $Script:ContentLines -join "`n"

    # Apply all sanitization patterns
    $content = Sanitize-ApiKeys $content
    $content = Sanitize-Tokens $content
    $content = Sanitize-Passwords $content
    $content = Sanitize-DatabaseUrls $content
    $content = Sanitize-UrlsWithCreds $content
    $content = Sanitize-JwtTokens $content
    $content = Sanitize-AwsKeys $content
    $content = Sanitize-GithubTokens $content
    $content = Sanitize-DeploymentTokens $content
    $content = Sanitize-PrivateKeys $content
    $content = Sanitize-GenericSecrets $content
    $content = Sanitize-EnvVars $content

    # Return sanitized content
    Write-Output $content
}

