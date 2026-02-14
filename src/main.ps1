<# 
Trash Rotation Reminder (PowerShell)
- Loads .env from script directory
- Uses ISO week number (Monday-based)
- Sends email/SMS via Gmail SMTP (App Password)
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ================================
# Load .env
# ================================
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$EnvPath   = Join-Path $ScriptDir ".env"

if (-not (Test-Path $EnvPath)) {
    Write-Host "❌ .env file not found in $ScriptDir"
    exit 1
}

Get-Content $EnvPath |
    Where-Object { $_ -and -not $_.StartsWith("#") } |
    ForEach-Object {
        $k, $v = $_ -split "=", 2
        $v = $v.Trim('"','''')
        [Environment]::SetEnvironmentVariable($k, $v, "Process")
    }

$SMTP_URL           = $env:SMTP_URL
$SMTP_FROM          = $env:SMTP_FROM
$GMAIL_APP_PASSWORD = $env:GMAIL_APP_PASSWORD

# ================================
# Trash Rotation
# ================================
$Rotation = @(
    "Jack|3392366543|vtext.com"
    "Jack|3392366543|vtext.com"
    "Jack|3392366543|vtext.com"
    "Jack|3392366543|vtext.com"
    "Jack|3392366543|vtext.com"
)

$Count   = $Rotation.Count
$IsoWeek = [System.Globalization.ISOWeek]::GetWeekOfYear((Get-Date))
$Index   = $IsoWeek % $Count

$Name, $Target, $Type = $Rotation[$Index] -split "\|"

# Recipient
$To = if ($Type -eq "email") { $Target } else { "$Target@$Type" }

# ================================
# Next in rotation
# ================================
$NextIndex = ($Index + 1) % $Count
$NextName  = ($Rotation[$NextIndex] -split "\|")[0]

# ================================
# Message
# ================================
$Today  = Get-Date -Format "dddd, MMMM dd, yyyy"
$Subject = "Trash Day Reminder"
$Body = @"
Trash reminder for $Today.

You're up this week: $Name
Up next: $NextName
"@

if ($Name -eq "Nick") {
    $Subject = "Напоминание: мусор на этой неделе"
    $Body = @"
Напоминание о выносе мусора на $Today.

На этой неделе твоя очередь: $Name
Следующий: $NextName
"@
}

# ================================
# Send via Gmail SMTP
# ================================
$Uri  = [Uri]$SMTP_URL
$Cred = New-Object PSCredential(
    $SMTP_FROM,
    (ConvertTo-SecureString $GMAIL_APP_PASSWORD -AsPlainText -Force)
)

Send-MailMessage `
    -From $SMTP_FROM `
    -To $To `
    -Subject $Subject `
    -Body $Body `
    -SmtpServer $Uri.Host `
    -Port $Uri.Port `
    -UseSsl `
    -Credential $Cred

Write-Host "✅ Trash reminder sent to $Name ($To) — ISO week $IsoWeek"
