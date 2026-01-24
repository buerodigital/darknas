#!/bin/bash
#
# 00_postinstall.sh
# DarkNAS Grundsystem:
# - Systemupdate
# - Ermitteln des Admin-Users (UID 1000)
# - Admin-User in sudo-Gruppe aufnehmen
# - Marker-Datei /etc/darknas/00_postinstall.conf erzeugen
# - Logging nach /var/log/darknas/YYYY-MM-DD_00_postinstall.log
#

#############################################
# 1) PATH sicherstellen
#############################################
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

#############################################
# 2) Root-Prüfung
#############################################
if [[ $EUID -ne 0 ]]; then
    echo "Dieses Skript muss als root ausgeführt werden."
    exit 1
fi

#############################################
# 3) Logdatei vorbereiten
#############################################
LOGDIR="/var/log/darknas"
mkdir -p "$LOGDIR"

DATE=$(date +"%Y-%m-%d")
LOGFILE="$LOGDIR/${DATE}_00_postinstall.log"

exec > >(tee -a "$LOGFILE") 2>&1

echo "=== DarkNAS Postinstall gestartet: $(date) ==="
echo "Logdatei: $LOGFILE"
echo

#############################################
# 4) Marker-Verzeichnis vorbereiten
#############################################
MARKERDIR="/etc/darknas"
MARKERFILE="$MARKERDIR/00_postinstall.conf"

mkdir -p "$MARKERDIR"

if [[ -f "$MARKERFILE" ]]; then
    echo "Marker-Datei existiert bereits. Das Skript wurde schon ausgeführt."
    exit 0
fi

#############################################
# 5) Systemupdate
#############################################
echo "--- Systemupdate wird durchgeführt ---"
apt-get update -y
apt-get upgrade -y
echo "--- Systemupdate abgeschlossen ---"
echo

#############################################
# 6) sudo installieren
#############################################
if ! command -v sudo >/dev/null 2>&1; then
    echo "sudo wird installiert..."
    apt-get install -y sudo
else
    echo "sudo ist bereits installiert."
fi
echo

#############################################
# 7) Admin-User mit UID 1000 ermitteln
#############################################
ADMINUSER=$(awk -F: '$3 == 1000 {print $1}' /etc/passwd)

if [[ -z "$ADMINUSER" ]]; then
    echo "FEHLER: Kein Benutzer mit UID 1000 gefunden!"
    exit 1
fi

echo "Gefundener Admin-User (UID 1000): $ADMINUSER"
echo

#############################################
# 8) Admin-User in sudo-Gruppe aufnehmen
#############################################
echo "Füge Benutzer '$ADMINUSER' zur sudo-Gruppe hinzu..."
usermod -aG sudo "$ADMINUSER"
echo

#############################################
# 9) Marker-Datei erstellen
#############################################
echo "Erstelle Marker-Datei: $MARKERFILE"
{
    echo "POSTINSTALL_DONE=1"
    echo "ADMIN_USER=$ADMINUSER"
} > "$MARKERFILE"

chmod 600 "$MARKERFILE"

#############################################
# 10) Abschluss
#############################################
echo
echo "=== DarkNAS Postinstall abgeschlossen: $(date) ==="
echo "Der Admin-User dieses Systems lautet: $ADMINUSER"
echo "Information gespeichert in: $MARKERFILE"
