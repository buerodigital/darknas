#!/bin/bash

# 0010_update.sh.sh – DarkNAS Grundsystem

# Einfaches Update-Skript für Debian
# Funktioniert sowohl als root als auch mit sudo

dark_update() {

    # Prüfen, ob root
    if [[ $EUID -eq 0 ]]; then
        RUN="apt"
    else
        # Prüfen, ob sudo verfügbar ist
        if ! command -v sudo >/dev/null 2>&1; then
            echo "Fehler: Dieses Skript muss als root oder mit sudo-Rechten ausgeführt werden."
            return 1
        fi

        # Prüfen, ob der User sudo-Rechte hat
        if ! sudo -n true 2>/dev/null; then
            echo "Fehler: Du hast keine sudo-Rechte oder musst ein Passwort eingeben."
            echo "Bitte führe das Skript mit: sudo $0"
            return 1
        fi

        RUN="sudo apt"
    fi

    echo "Starte System-Update..."

    $RUN update
    $RUN upgrade -y
    $RUN full-upgrade -y
    $RUN autoremove -y

    echo "System-Update abgeschlossen."
}

dark_update
