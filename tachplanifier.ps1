# Variables
$TaskName    = "UserModeExec"
$ProgramPath = "C:\Users\zadih\Desktop\ESTABLISHED.exe"

# Détecter l'utilisateur actif
$UserName = (Get-WmiObject Win32_ComputerSystem).UserName
if (-not $UserName) {
    Write-Host "[-] Aucun utilisateur connecté trouvé."
    exit
}

Write-Host "[*] Utilisateur connecté détecté : $UserName"

# Supprimer la tâche si elle existe déjà
schtasks /delete /tn $TaskName /f | Out-Null

# Créer la tâche planifiée dans le contexte de l'utilisateur connecté
schtasks /create /tn $TaskName `
    /tr "`"$ProgramPath`"" `
    /sc once /st 00:00 `
    /ru $UserName `
    /f | Out-Null

# Lancer la tâche immédiatement
schtasks /run /tn $TaskName

Write-Host "[+] Tâche $TaskName exécutée dans le contexte de $UserName"

