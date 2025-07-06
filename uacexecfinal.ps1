# Script pour désactiver ou limiter la journalisation dans Windows

# Vérifie si le script est exécuté en tant qu'administrateur
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Ce script doit être exécuté en tant qu'administrateur." -ForegroundColor Red
    exit
}

# 1. Désactiver la journalisation de Microsoft Defender via le Registre
function Disable-DefenderLoggingInRegistry {
    Write-Host "Désactivation de la journalisation de Microsoft Defender via le Registre..." -ForegroundColor Yellow
    $regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\"
    try {
        if (-not (Test-Path $regPath)) {
            Write-Host "Création du chemin : $regPath" -ForegroundColor Yellow
            New-Item -Path $regPath -Force | Out-Null
        }
        Set-ItemProperty -Path $regPath -Name "DisableLogging" -Value 1 -Type DWord
        Write-Host "Journalisation de Microsoft Defender désactivée dans le Registre." -ForegroundColor Green
    } catch {
        Write-Host "Erreur lors de la désactivation de la journalisation dans le Registre : $_" -ForegroundColor Red
    }
}

# 2. Suppression des fichiers journaux de Microsoft Defender
function Remove-DefenderLogFiles {
    Write-Host "Suppression des fichiers journaux de Microsoft Defender..." -ForegroundColor Yellow
    $logFolder = "C:\ProgramData\Microsoft\Windows Defender\Support\"
    try {
        if (Test-Path $logFolder) {
            Get-ChildItem -Path $logFolder -Filter *.log | ForEach-Object {
                Write-Host "Suppression du fichier : $($_.FullName)" -ForegroundColor Yellow
                Remove-Item -Path $_.FullName -Force
            }
            Write-Host "Fichiers journaux supprimés avec succès." -ForegroundColor Green
        } else {
            Write-Host "Le dossier de journaux n'existe pas : $logFolder" -ForegroundColor Red
        }
    } catch {
        Write-Host "Erreur lors de la suppression des fichiers journaux : $_" -ForegroundColor Red
    }
}

# 3. Effacement des journaux d'événements Microsoft Defender dans Event Viewer
function Clear-DefenderEventLogs {
    Write-Host "Effacement des journaux d'événements Microsoft Defender dans Event Viewer..." -ForegroundColor Yellow
    try {
        $defenderLog = "Microsoft-Windows-Windows Defender/Operational"
        if ((Get-WinEvent -ListLog $defenderLog -ErrorAction SilentlyContinue)) {
            Write-Host "Effacement du journal : $defenderLog" -ForegroundColor Yellow
            wevtutil cl $defenderLog
            Write-Host "Journal d'événements Microsoft Defender effacé." -ForegroundColor Green
        } else {
            Write-Host "Le journal d'événements Microsoft Defender n'existe pas." -ForegroundColor Red
        }
    } catch {
        Write-Host "Erreur lors de l'effacement des journaux d'événements : $_" -ForegroundColor Red
    }
}

# 4. Désactiver la journalisation de Microsoft Defender (fonction originale)
function Disable-DefenderLogging {
    Write-Host "Désactivation de la journalisation de Microsoft Defender..." -ForegroundColor Yellow
    $regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
    try {
        if (-not (Test-Path $regPath)) {
            Write-Host "Création du chemin : $regPath" -ForegroundColor Yellow
            New-Item -Path $regPath -Force | Out-Null
        }
        Set-ItemProperty -Path $regPath -Name "DisableLogging" -Value 1 -Type DWord
        Write-Host "Journalisation de Microsoft Defender désactivée." -ForegroundColor Green
    } catch {
        Write-Host "Erreur lors de la désactivation de la journalisation de Microsoft Defender : $_" -ForegroundColor Red
    }
}

# 5. Désactiver la journalisation des événements Windows (Event Viewer)
function Disable-EventViewerLogging {
    Write-Host "Désactivation de la journalisation des événements Windows..." -ForegroundColor Yellow
    $logs = @("Application", "Security", "System")
    foreach ($log in $logs) {
        $logPath = "HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\$log"
        try {
            if (Test-Path $logPath) {
                Write-Host "Modification du chemin : $logPath" -ForegroundColor Yellow
                Set-ItemProperty -Path $logPath -Name "Start" -Value 4 -Type DWord
            } else {
                Write-Host "Chemin non trouvé : $logPath" -ForegroundColor Red
            }
        } catch {
            Write-Host "Erreur lors de la désactivation de la journalisation pour $log : $_" -ForegroundColor Red
        }
    }
    Write-Host "Journalisation des événements Windows désactivée." -ForegroundColor Green
}

# 6. Désactiver la journalisation PowerShell
function Disable-PowerShellLogging {
    Write-Host "Désactivation de la journalisation PowerShell..." -ForegroundColor Yellow
    $regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging"
    try {
        if (-not (Test-Path $regPath)) {
            Write-Host "Création du chemin : $regPath" -ForegroundColor Yellow
            New-Item -Path $regPath -Force | Out-Null
        }
        Set-ItemProperty -Path $regPath -Name "EnableModuleLogging" -Value 0 -Type DWord
        Write-Host "Journalisation PowerShell désactivée." -ForegroundColor Green
    } catch {
        Write-Host "Erreur lors de la désactivation de la journalisation PowerShell : $_" -ForegroundColor Red
    }
}

# 7. Nettoyer les journaux existants
function Clear-ExistingLogs {
    Write-Host "Nettoyage des journaux existants..." -ForegroundColor Yellow
    try {
        wevtutil el | ForEach-Object { 
            Write-Host "Effacement du journal : $_" -ForegroundColor Yellow
            wevtutil cl $_ 
        }
        Write-Host "Journaux existants nettoyés." -ForegroundColor Green
    } catch {
        Write-Host "Erreur lors du nettoyage des journaux : $_" -ForegroundColor Red
    }
}

# Exécution des fonctions
Disable-DefenderLoggingInRegistry
Remove-DefenderLogFiles
Clear-DefenderEventLogs
Disable-DefenderLogging
Disable-EventViewerLogging
Disable-PowerShellLogging
Clear-ExistingLogs