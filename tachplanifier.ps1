# Variables
$TaskName    = "UserModeExec"
$ProgramPath = "C:\Users\ESTABLISHED.exe"

# Détection de l'utilisateur connecté
$UserName = (Get-WmiObject Win32_ComputerSystem).UserName
if (-not $UserName) {
    Write-Host "[-] Aucun utilisateur connecté trouvé."
    exit
}

Write-Host "[*] Utilisateur connecté détecté : $UserName"

# Connexion au service de planification
$service = New-Object -ComObject Schedule.Service
$service.Connect()

# Récupération du dossier racine des tâches
$rootFolder = $service.GetFolder("\")
try {
    $rootFolder.DeleteTask($TaskName, 0)  # Suppression si déjà existante
} catch {}

# Création d'une nouvelle définition de tâche
$taskDefinition = $service.NewTask(0)

# Paramètres de la tâche
$taskDefinition.RegistrationInfo.Description = "Tâche temporaire pour exécuter un programme en mode utilisateur"
$taskDefinition.Principal.UserId = $UserName
$taskDefinition.Principal.LogonType = 3  # Logon interactif
$taskDefinition.Principal.RunLevel = 0   # Niveau utilisateur standard

# Définir le déclencheur (immédiat)
$trigger = $taskDefinition.Triggers.Create(1)  # 1 = TimeTrigger
$trigger.StartBoundary = (Get-Date).AddSeconds(1).ToString("yyyy-MM-dd'T'HH:mm:ss")

# Action à exécuter
$action = $taskDefinition.Actions.Create(0)  # 0 = Exécuter un programme
$action.Path = $ProgramPath

# Enregistrer et exécuter la tâche
$rootFolder.RegisterTaskDefinition($TaskName, $taskDefinition, 6, $null, $null, 3, $null) | Out-Null
$rootFolder.GetTask("\$TaskName").Run($null) | Out-Null

# Attente pour lancement
Start-Sleep -Seconds 2

# Suppression immédiate de la tâche
$rootFolder.DeleteTask($TaskName, 0)

Write-Host "[+] Programme exécuté dans le contexte de $UserName et tâche supprimée immédiatement."
