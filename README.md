# PowerShell-Script-OU-Users-Gruppen
M122 - PowerShell Script OU Users/Gruppen

### Erklärung der Hauptfunktionen:
1. **Create-OU**: Erstellt eine neue Organisationseinheit (OU) in Active Directory basierend auf dem angegebenen Namen und Pfad.
2. **Create-Group**: Erstellt eine neue Sicherheitsgruppe in einer angegebenen OU.
3. **Create-User**: Erstellt einen neuen Benutzer mit dem angegebenen Namen und Passwort in einer bestimmten OU. Das Konto wird nach der Erstellung aktiviert.
4. **Add-UserToGroup**: Fügt einen vorhandenen Benutzer einer bestehenden Gruppe hinzu.
5. **Delete-OU**: Löscht eine angegebene OU und alle enthaltenen Objekte.
6. **Delete-Group**: Löscht eine bestehende Gruppe.
7. **Delete-User**: Löscht einen vorhandenen Benutzer.

### Hinweise:
- **OU-Pfade** und **Domain-Komponenten (DC)** müssen den tatsächlichen Strukturen Ihrer AD-Domäne entsprechen. Beispiel: `"DC=bbw,DC=lab"`.
- Das Skript verwendet die `Read-Host -AsSecureString` Funktion für die sichere Eingabe von Passwörtern.
- Löschen von OUs erfolgt rekursiv (`-Recursive`), das heißt, alle Unterobjekte werden ebenfalls gelöscht.

### Sicherheitshinweis:
- Seien Sie vorsichtig beim Löschen von OUs, Benutzern und Gruppen, da dies irreversibel sein kann, wenn nicht ordnungsgemäß gesichert wurde.
**
