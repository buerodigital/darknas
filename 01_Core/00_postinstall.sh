#!/bin/bash
#
# 00_postinstall.sh – DarkNAS Grundsystem
#
# ============================================================
#                    I N H A L T S V E R Z E I C H N I S
# ============================================================
#   01) PATH sicherstellen
#   02) Root-Prüfung
#   03) Logdatei vorbereiten
#   04) Konfigurations-Verzeichnis vorbereiten
#   05) Systemupdate
#   06) Zeitsynchronisation sicherstellen (chrony)
#   07) sudo installieren
#   08) Admin-User "admin" anlegen oder aktualisieren
#   09) Admin-User in sudo-Gruppe aufnehmen
#   10) sudoers-Datei für Admin-User erstellen (NOPASSWD)
#   11) Marker-Konfigurationsdatei erstellen
#   12) Build-Abhängigkeiten für ttyd installieren
#   13) libwebsockets klonen und mit libuv bauen
#   14) ttyd klonen und bauen
#   15) ttyd installieren
#   16) systemd-Service für ttyd erstellen
#   17) ttyd Service aktivieren und starten
#   18) Abschlussmeldung
#
# ============================================================
#   Dieses Skript richtet ein vollständiges DarkNAS-Basissystem
#   ein, inklusive:
#     - Systemupdate
#     - Zeit-Synchronisation
#     - Admin-User
#     - sudo-Konfiguration
#     - vollständiger ttyd-Build aus Quellen
#     - libwebsockets mit libuv (für PTY-Support)
#     - stabiler systemd-Service ohne PAM-Self-Spawn
#
#   Die Terminalausgabe ist bewusst minimal gehalten.
#   Alle Details werden in die Logdatei geschrieben.
# ============================================================


#############################################
# Hilfsfunktion: Minimalistische Ausgabe
#############################################
msg() {
    echo "[DarkNAS] $1"
}


#############################################
# 01) PATH sicherstellen
#############################################
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"


#############################################
# 02) Root-Prüfung
#############################################
if [[ $EUID -ne 0 ]]; then
    echo "Dieses Skript muss als root ausgeführt werden."
    exit 1
fi


#############################################
# 03) Logdatei vorbereiten
#############################################
LOGDIR="/var/log/darknas"
mkdir -p "$LOGDIR"

DATE=$(date +"%Y-%m-%d")
LOGFILE="$LOGDIR/${DATE}_00_postinstall.log"

# Alles (stdout + stderr) wird in die Logdatei gespiegelt
exec > >(tee -a "$LOGFILE") 2>&1


#############################################
# DarkNAS Logo
#############################################
cat << "EOF"
    ____             _      _   _    _    ____
   |  _ \  __ _ _ __| | __ | \ | |  / \  / ___|
   | | | |/ _´ | ´__| |/ / |  \| | / _ \ \___ \
   | |_| | |_| | |  |   |  | |\  |/ ___ \ ___| |
   |____/ \__._|_|  |_|\_\ |_| \_/_/   \_\____/
Data belongs in the dark. Simple. Silent. Reliable.
EOF

echo
msg "Postinstall gestartet – Log: $LOGFILE"
echo


#############################################
# 04) Konfigurations-Verzeichnis vorbereiten
#############################################
CONFDIR="/etc/darknas"
CONFFILE="$CONFDIR/00_postinstall.conf"

mkdir -p "$CONFDIR"

# Marker verhindert doppelte Ausführung
if [[ -f "$CONFFILE" ]]; then
    msg "Marker-Datei existiert – Skript wurde bereits ausgeführt."
    exit 0
fi


#############################################
# 05) Systemupdate
#############################################
msg "Systemupdate…"
apt-get update -y >/dev/null 2>&1
apt-get upgrade -y >/dev/null 2>&1
msg "Systemupdate abgeschlossen."


#############################################
# 06) Zeitsynchronisation sicherstellen
#############################################
msg "Installiere und aktiviere chrony…"

apt-get install -y chrony >/dev/null 2>&1
systemctl enable chrony --now >/dev/null 2>&1

# Sofortige Zeitkorrektur
chronyc makestep >/dev/null 2>&1

msg "Zeitsynchronisation abgeschlossen."


#############################################
# 07) sudo installieren
#############################################
if ! command -v sudo >/dev/null 2>&1; then
    msg "Installiere sudo…"
    apt-get install -y sudo >/dev/null 2>&1
else
    msg "sudo bereits installiert."
fi


#############################################
# 08) Admin-User anlegen/aktualisieren
#############################################
ADMINUSER="admin"

if id "$ADMINUSER" >/dev/null 2>&1; then
    msg "Benutzer '$ADMINUSER' existiert bereits."
else
    msg "Lege Benutzer '$ADMINUSER' an…"
    useradd -m -s /bin/bash "$ADMINUSER"
fi

# Passwort setzen
echo "${ADMINUSER}:pass" | chpasswd
msg "Passwort gesetzt."


#############################################
# 09) Admin-User in sudo-Gruppe aufnehmen
#############################################
msg "Füge '$ADMINUSER' zur sudo-Gruppe hinzu…"
usermod -aG sudo "$ADMINUSER"


#############################################
# 10) sudoers-Datei erstellen
#############################################
SUDOERS_FILE="/etc/sudoers.d/darknas"

msg "Erstelle sudoers-Datei…"

{
    echo "# DarkNAS Admin-Rechte"
    echo "admin ALL=(ALL) NOPASSWD: ALL"
} > "$SUDOERS_FILE"

chmod 440 "$SUDOERS_FILE"


#############################################
# 11) Marker-Konfigurationsdatei erstellen
################################
