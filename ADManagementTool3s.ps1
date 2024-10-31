# Advanced Active Directory Management Tool
# Version: 2.0
# Description: A comprehensive tool for managing Active Directory with enhanced security and validation

#Requires -Module ActiveDirectory
#Requires -Module GroupPolicy
#Requires -RunAsAdministrator

# Stop on errors
$ErrorActionPreference = "Stop"

# Configuration
$CONFIG = @{
    LogFile = "C:\Logs\ADManagement_log.txt"
    WallpaperPath = "\\$env:USERDNSDOMAIN\NETLOGON\Wallpapers"
    PasswordPolicy = @{
        MinLength = 12
        RequireComplexity = $true
    }
    BackupPath = "C:\Logs\ADBackups"
}

# Ensure log directory exists
$logDir = Split-Path $CONFIG.LogFile -Parent
if (-not (Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
}

# Ensure backup directory exists
if (-not (Test-Path $CONFIG.BackupPath)) {
    New-Item -Path $CONFIG.BackupPath -ItemType Directory -Force | Out-Null
}

function Write-LogMessage {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp [$Level] - $Message"
    
    # Add color coding for console output
    $color = switch ($Level) {
        'Info' { 'White' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
    }
    
    Write-Host $logMessage -ForegroundColor $color
    $logMessage | Out-File $CONFIG.LogFile -Append
}

function Test-AdminCredentials {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-ValidInput {
    param(
        [string]$Input,
        [string]$Pattern = '^[\w\s-]+$'
    )
    return $Input -match $Pattern
}

function Test-PasswordComplexity {
    param([System.Security.SecureString]$SecurePassword)
    
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
    $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    
    return ($password.Length -ge $CONFIG.PasswordPolicy.MinLength) -and 
           ($password -match '(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[!@#$%^&*(),.?":{}|<>])')
}

function Backup-ADObject {
    param(
        [string]$ObjectName,
        [string]$ObjectType
    )
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = Join-Path $CONFIG.BackupPath "$ObjectType`_$ObjectName`_$timestamp.xml"
    
    try {
        switch ($ObjectType) {
            'User' { Get-ADUser -Identity $ObjectName -Properties * | Export-Clixml -Path $backupFile }
            'Group' { Get-ADGroup -Identity $ObjectName -Properties * | Export-Clixml -Path $backupFile }
            'OU' { Get-ADOrganizationalUnit -Identity "OU=$ObjectName,$ouPath" -Properties * | Export-Clixml -Path $backupFile }
        }
        Write-LogMessage "Backup created: $backupFile" -Level Info
    }
    catch {
        Write-LogMessage "Failed to create backup: $_" -Level Error
    }
}

function Show-Menu {
    Clear-Host
    @"
╔════════════════════════════════════════════╗
║     Active Directory Management Suite      ║
╠════════════════════════════════════════════╣
║ 1. Create OU           7.  Delete User     ║
║ 2. Create Group        8.  Set Wallpaper   ║
║ 3. Create User         9.  Backup AD       ║
║ 4. Add User to Group   10. Restore Backup  ║
║ 5. Delete OU           11. View Logs       ║
║ 6. Delete Group        12. Exit            ║
╚════════════════════════════════════════════╝
"@ | Write-Host -ForegroundColor Cyan

    do {
        $selection = Read-Host "`nSelect an option (1-12)"
    } while ($selection -notmatch '^([1-9]|1[0-2])$')
    
    return $selection
}

function Create-OU {
    try {
        do {
            $ouName = Read-Host "Enter OU name"
        } while (-not (Test-ValidInput -Input $ouName))
        
        $ouPath = Read-Host "Enter parent path (e.g., 'DC=domain,DC=com')"
        
        if (Test-ADPath -Path "OU=$ouName,$ouPath") {
            Write-LogMessage "OU already exists!" -Level Warning
            return
        }

        New-ADOrganizationalUnit -Name $ouName -Path $ouPath -ProtectedFromAccidentalDeletion $true
        Write-LogMessage "Created OU: $ouName" -Level Info
    }
    catch {
        Write-LogMessage "Failed to create OU: $_" -Level Error
    }
}

function Create-User {
    try {
        do {
            $userName = Read-Host "Enter username"
        } while (-not (Test-ValidInput -Input $userName))
        
        $ouPath = Read-Host "Enter OU path"
        
        do {
            $password = Read-Host -AsSecureString "Enter password (min. 12 chars, must include uppercase, lowercase, number, and symbol)"
        } while (-not (Test-PasswordComplexity -SecurePassword $password))
        
        $userParams = @{
            Name = $userName
            AccountPassword = $password
            Path = $ouPath
            Enabled = $true
            ChangePasswordAtLogon = $true
            PasswordNeverExpires = $false
        }
        
        New-ADUser @userParams
        Write-LogMessage "Created user: $userName" -Level Info
    }
    catch {
        Write-LogMessage "Failed to create user: $_" -Level Error
    }
}

# Main execution loop
try {
    if (-not (Test-AdminCredentials)) {
        Write-LogMessage "This script requires administrative privileges!" -Level Error
        exit 1
    }

    Import-Module ActiveDirectory -ErrorAction Stop
    Import-Module GroupPolicy -ErrorAction Stop
    
    while ($true) {
        $action = Show-Menu
        
        switch ($action) {
            '1' { Create-OU }
            '2' { Create-Group }
            '3' { Create-User }
            '4' { Add-UserToGroup }
            '5' { Delete-OU }
            '6' { Delete-Group }
            '7' { Delete-User }
            '8' { Set-DomainWallpaper }
            '9' { Backup-ADEnvironment }
            '10' { Restore-ADBackup }
            '11' { Show-Logs }
            '12' { 
                Write-LogMessage "Exiting application..." -Level Info
                exit 0
            }
        }
        
        Write-Host "`nPress any key to continue..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
}
catch {
    Write-LogMessage "Critical error: $_" -Level Error
    exit 1
}
