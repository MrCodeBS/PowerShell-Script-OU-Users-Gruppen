# Ein Script, das dein Active Directory managed (oder es zumindest versucht 😅)

# Importiere das Active Directory Modul (hoffen wir, dass es installiert ist!)
Import-Module ActiveDirectory -ErrorAction Stop

# Globale Variablen für Fehlerprotokollierung
$logFile = "C:\ADManagement_log.txt"
$ErrorActionPreference = "Stop"

function Write-LogMessage {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File $logFile -Append
    Write-Host $Message
}

function Show-Menu {
    Clear-Host
    Write-Host "🎮 Active Directory Management Tool 3000 🎮" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "1. OU erstellen      (für Ordnungsfanatiker)" -ForegroundColor Green
    Write-Host "2. Gruppe erstellen  (Gruppentherapie für ADs)" -ForegroundColor Green
    Write-Host "3. Benutzer erstellen (noch mehr Chaos!)" -ForegroundColor Green
    Write-Host "4. Benutzer gruppieren (Soziales Networking)" -ForegroundColor Yellow
    Write-Host "5. OU löschen        (Frühjahrsputz)" -ForegroundColor Red
    Write-Host "6. Gruppe löschen    (Gruppenkuscheln ade)" -ForegroundColor Red
    Write-Host "7. Benutzer löschen  (Tschüss! 👋)" -ForegroundColor Red
    Write-Host "8. Beenden           (Feierabend! 🎉)" -ForegroundColor Magenta
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    
    $selection = Read-Host "Was darf's denn sein? (1-8)"
    return $selection
}

function Test-ADPath {
    param($Path)
    try {
        Get-ADOrganizationalUnit -Identity $Path
        return $true
    }
    catch {
        return $false
    }
}

function Create-OU {
    try {
        $ouName = Read-Host "Name der neuen OU (kreativ sein!)"
        $ouPath = Read-Host "Pfad (z.B. 'DC=bbw,DC=lab') - bitte nicht vertippen 🙏"
        
        # Prüfe, ob OU bereits existiert
        if (Test-ADPath -Path "OU=$ouName,$ouPath") {
            Write-LogMessage "🤦‍♂️ Diese OU existiert bereits! Wie wäre es mit etwas Originellerem?"
            return
        }

        New-ADOrganizationalUnit -Name $ouName -Path $ouPath
        Write-LogMessage "🎉 OU '$ouName' wurde erfolgreich erstellt! Zeit zum Feiern!"
    }
    catch {
        Write-LogMessage "😱 Ups! Fehler beim Erstellen der OU: $_"
    }
}

function Create-Group {
    try {
        $groupName = Read-Host "Name der neuen Gruppe (nichts mit 'Admin', bitte!)"
        $ouPath = Read-Host "OU-Pfad (z.B. 'OU=MeineOU,DC=bbw,DC=lab')"
        
        if (Get-ADGroup -Filter "Name -eq '$groupName'" -ErrorAction SilentlyContinue) {
            Write-LogMessage "🤔 Diese Gruppe gibt's schon! Sei kreativ!"
            return
        }

        New-ADGroup -Name $groupName -GroupCategory Security -GroupScope DomainLocal -Path $ouPath
        Write-LogMessage "🎈 Gruppe '$groupName' ist bereit für neue Mitglieder!"
    }
    catch {
        Write-LogMessage "💥 Autsch! Fehler beim Erstellen der Gruppe: $_"
    }
}

function Create-User {
    try {
        $userName = Read-Host "Username (bitte nicht 'admin1234')"
        $ouPath = Read-Host "OU-Pfad (wo soll der Neue hin?)"
        $password = Read-Host -AsSecureString "Sicheres Passwort (nicht 'Passwort123' 🙄)"
        
        if (Get-ADUser -Filter "Name -eq '$userName'" -ErrorAction SilentlyContinue) {
            Write-LogMessage "👥 Dieser Name ist schon vergeben! Wie wäre es mit '$userName_2'? 😉"
            return
        }

        New-ADUser -Name $userName -AccountPassword $password -Path $ouPath -PassThru | Enable-ADAccount
        Write-LogMessage "👋 Willkommen an Bord, $userName!"
    }
    catch {
        Write-LogMessage "🚫 Ups! Da ging was schief beim Benutzer erstellen: $_"
    }
}

function Add-UserToGroup {
    try {
        $userName = Read-Host "Welcher Benutzer soll in die Gruppe? (Name)"
        $groupName = Read-Host "In welche Gruppe? (hoffentlich nicht 'Domain Admins')"
        
        if (-not (Get-ADUser -Identity $userName -ErrorAction SilentlyContinue)) {
            Write-LogMessage "🤷‍♂️ Benutzer nicht gefunden! Existiert der überhaupt?"
            return
        }

        Add-ADGroupMember -Identity $groupName -Members $userName
        Write-LogMessage "🤝 $userName ist jetzt Teil von $groupName - Willkommen im Club!"
    }
    catch {
        Write-LogMessage "😅 Das hat nicht geklappt: $_"
    }
}

function Delete-OU {
    try {
        $ouName = Read-Host "Welche OU muss gehen? (Name)"
        $ouPath = Read-Host "Pfad der OU (letzte Chance zum Überlegen!)"
        
        $confirmation = Read-Host "Bist du dir WIRKLICH sicher? (j/n)"
        if ($confirmation -ne "j") {
            Write-LogMessage "🛑 Abgebrochen - manchmal ist weniger mehr!"
            return
        }

        Remove-ADOrganizationalUnit -Identity "OU=$ouName,$ouPath" -Recursive -Confirm:$false
        Write-LogMessage "🗑️ OU '$ouName' ist Geschichte! Ruhe in Frieden..."
    }
    catch {
        Write-LogMessage "💣 Fehler beim Löschen der OU: $_"
    }
}

function Delete-Group {
    try {
        $groupName = Read-Host "Welche Gruppe soll aufgelöst werden? (Name)"
        
        $confirmation = Read-Host "Wirklich löschen? Die Gruppe könnte dich vermissen! (j/n)"
        if ($confirmation -ne "j") {
            Write-LogMessage "🛑 Abgebrochen - Gruppenliebe siegt!"
            return
        }

        Remove-ADGroup -Identity $groupName -Confirm:$false
        Write-LogMessage "👋 Gruppe '$groupName' ist jetzt in der großen AD-Gruppentherapie im Himmel..."
    }
    catch {
        Write-LogMessage "💥 Fehler beim Löschen der Gruppe: $_"
    }
}

function Delete-User {
    try {
        $userName = Read-Host "Wer muss gehen? (Username)"
        
        $confirmation = Read-Host "Letzte Worte? (j/n)"
        if ($confirmation -ne "j") {
            Write-LogMessage "🛑 Abgebrochen - zweite Chancen sind wichtig!"
            return
        }

        Remove-ADUser -Identity $userName -Confirm:$false
        Write-LogMessage "🌈 $userName ist jetzt in einem besseren Verzeichnis..."
    }
    catch {
        Write-LogMessage "🔥 Fehler beim Löschen des Benutzers: $_"
    }
}

# Hauptschleife - hier geht die Party ab!
try {
    while ($true) {
        $action = Show-Menu
        
        switch ($action) {
            1 { Create-OU }
            2 { Create-Group }
            3 { Create-User }
            4 { Add-UserToGroup }
            5 { Delete-OU }
            6 { Delete-Group }
            7 { Delete-User }
            8 { 
                Write-Host "🎉 Danke fürs Spielen! Bis zum nächsten AD-Abenteuer!" -ForegroundColor Magenta
                exit 
            }
            default { Write-Host "🤨 Das war keine gültige Option. Probier's nochmal!" -ForegroundColor Yellow }
        }
        
        Write-Host "`nDrücke eine beliebige Taste für's nächste Abenteuer..." -ForegroundColor Cyan
        $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
    }
}
catch {
    Write-LogMessage "🚨 Kritischer Fehler! Die Welt geht unter! (oder auch nicht): $_"
    exit 1
}
