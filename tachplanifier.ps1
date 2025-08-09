# Variables
$TaskName    = "UserModeExec"
$ProgramPath = "C:\Users\ESTABLISHED.exe"

# Détecter l'utilisateur actif
$UserName = (Get-WmiObject Win32_ComputerSystem).UserName
if (-not $UserName) {
    Write-Host "[-] Aucun utilisateur connecté trouvé."
    exit
}

Write-Host "[*] Utilisateur connecté détecté : $UserName"

# Supprimer une éventuelle ancienne tâche
schtasks /delete /tn $TaskName /f | Out-Null

# Créer la tâche planifiée temporaire
schtasks /create /tn $TaskName `
    /tr "`"$ProgramPath`"" `
    /sc once /st 00:00 `
    /ru $UserName `
    /f | Out-Null

# Lancer la tâche
schtasks /run /tn $TaskName

# Attendre un court instant pour s'assurer que le programme démarre
Start-Sleep -Seconds 2

# Supprimer la tâche pour effacer les traces
schtasks /delete /tn $TaskName /f | Out-Null

Write-Host "[+] Programme exécuté dans le contexte de $UserName et tâche supprimée."
