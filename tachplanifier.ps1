# Variables
$ProgramPath = "C:\Users\ESTABLISHED.exe"  # Remplacer par ton exécutable
$TaskName    = "TempExec_{$( [Guid]::NewGuid().ToString().Substring(0,8) )}"  # Nom aléatoire

# Vérifier que le programme existe
if (-not (Test-Path $ProgramPath)) {
    Write-Host "[-] Programme introuvable : $ProgramPath"
    exit 1
}

# Détecter l'utilisateur connecté
$UserName = (Get-WmiObject Win32_ComputerSystem).UserName
if (-not $UserName) {
    Write-Host "[-] Aucun utilisateur connecté."
    exit 1
}
$UserSID = (Get-WmiObject Win32_UserAccount -Filter "Name='$($UserName.Split('\')[1])' AND Domain='$($UserName.Split('\')[0])'").SID
if (-not $UserSID) {
    Write-Host "[-] Impossible de récupérer le SID de l'utilisateur."
    exit 1
}

Write-Host "[*] Utilisateur : $UserName (SID: $UserSID)"

# Obtenir la session interactive
$Session = (Get-Process Explorer -ErrorAction SilentlyContinue).SessionId
if ($Session -eq $null -or $Session -eq 0) {
    Write-Host "[-] Aucune session interactive détectée (Explorer non lancé ou session 0)."
    exit 1
}
Write-Host "[*] Session interactive : $Session"

# Connexion au service de planification
$Scheduler = New-Object -ComObject Schedule.Service
$Scheduler.Connect()

# Dossier racine
$RootFolder = $Scheduler.GetFolder("\\")

# Créer une tâche en mémoire (non enregistrée)
$TaskDefinition = $Scheduler.NewTask(0)

# Informations
$TaskDefinition.RegistrationInfo.Description = "Tâche temporaire furtive"
$TaskDefinition.Principal.UserId = $UserName
$TaskDefinition.Principal.LogonType = 3  # S4U (utilise le jeton sans mot de passe)
$TaskDefinition.Principal.RunLevel = 0   # Pas d'élévation

# Déclencheur : immédiat
$Trigger = $TaskDefinition.Triggers.Create(1)  # TimeTrigger
$Trigger.StartBoundary = (Get-Date).ToString("yyyy-MM-dd'T'HH:mm:ss")
$Trigger.Enabled = $true

# Action
$Action = $TaskDefinition.Actions.Create(0)
$Action.Path = $ProgramPath

# Configurer la tâche pour qu'elle s'exécute dans la session utilisateur
$TaskDefinition.Settings.ExecutionTimeLimit = "PT0S"   # Pas de timeout
$TaskDefinition.Settings.Hidden = $true                # Invisible
$TaskDefinition.Settings.Priority = 0                  # Priorité normale

# --- 🔥 EXÉCUTION DIRECTE SANS ENREGISTREMENT ---
# On utilise `TargetServer` = null, `TaskName` = null → tâche temporaire
$WorkItem = $RootFolder.Validate($TaskDefinition, [ref]$null)
$WorkItem = $RootFolder.CreateWorkItem($TaskName, $TaskDefinition)

# Lancer la tâche en mémoire
$RunningTask = $WorkItem.Run()
if ($RunningTask) {
    Write-Host "[+] Programme lancé dans la session de $UserName."
    Start-Sleep -Seconds 2  # Laisser le temps au processus de démarrer
    $WorkItem.Terminate()   # Optionnel : forcer l'arrêt si besoin
} else {
    Write-Host "[-] Échec du lancement du programme."
    exit 1
}

# Nettoyage : la tâche n'existe que dans la variable
Remove-Variable -Name WorkItem -ErrorAction SilentlyContinue
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Scheduler) | Out-Null
[GC]::Collect()

Write-Host "[*] Tâche temporaire nettoyée. Aucune trace dans le planificateur."
