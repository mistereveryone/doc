# Variables
$TaskName = "UserModeExec"

# Détecter l'utilisateur connecté (format DOMAIN\Username ou PCNAME\Username)
$FullUserName = (Get-WmiObject Win32_ComputerSystem).UserName
if (-not $FullUserName) {
    Write-Host "[-] Aucun utilisateur connecté trouvé."
    exit
}

# Extraire uniquement le nom sans domaine/machine
$UserName = $FullUserName.Split("\")[-1]
Write-Host "[*] Utilisateur détecté : $UserName"

# Construire le chemin dynamique vers le bureau
$ProgramPath = "C:\Users\$UserName\Desktop\ESTABLISHED.exe"

# Vérifier si le fichier existe
if (-not (Test-Path $ProgramPath)) {
    Write-Host "[-] Le fichier $ProgramPath n'existe pas."
    exit
}

# Supprimer la tâche si elle existe déjà
schtasks /delete /tn $TaskName /f | Out-Null

# Créer la tâche planifiée dans le contexte de l'utilisateur connecté
schtasks /create /tn $TaskName `
    /tr "`"$ProgramPath`"" `
    /sc once /st 00:00 `
    /ru $FullUserName `
    /f | Out-Null

# Lancer la tâche immédiatement
schtasks /run /tn $TaskName

Write-Host "[+] Tâche $TaskName exécutée dans le contexte de $FullUserName"
