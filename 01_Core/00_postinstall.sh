#!/bin/bash
#
# 00_postinstall.sh
#
# DarkNAS Grundsystem:
# 01) PATH sicherstellen
# 02) Root-Prüfung
# 03) Logdatei vorbereiten - Logging nach /var/log/darknas/YYYY-MM-DD_00_postinstall.log
# 04) Konfiggurations-Verzeichnis vorbereiten - /etc/darknas/00_postinstall.conf erzeugen
# 05) Systemupdate
# 06) Zeitsynchronisation sicherstellen - Synchronisiere Systemzeit mit chrony...
# 07) sudo installieren
# 08) Admin-User "admin" anlegen oder aktualisieren
# 09) Admin-User in sudo-Gruppe aufnehmen
# 10) sudoers-Datei für Admin-User erstellen (NOPASSWD)
# 11) Konfigurations-Datei erstellen - /etc/darknas/00_postinstall.conf erzeugen
# 12) ttyd installieren
# 13) systemd-Service für ttyd erstellen
# 14) Service aktivieren und starten
# 15) Abschluss

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

exec > >(tee -a "$LOGFILE") 2>&1

echo "=== DarkNAS Postinstall gestartet: $(date) ==="
echo "Logdatei: $LOGFILE"
echo

#############################################
# 04) Konfigurations-Verzeichnis vorbereiten
#############################################
CONFDIR="/etc/darknas"
CONFFILE="$CONFDIR/00_postinstall.conf"

mkdir -p "$CONFDIR"

if [[ -f "$CONFFILE" ]]; then
    echo "Marker-Datei existiert bereits. Das Skript wurde schon ausgeführt."
    exit 0
fi

#############################################
# 05) Systemupdate
#############################################
echo "--- Systemupdate wird durchgeführt ---"
apt-get update -y
apt-get upgrade -y
echo "--- Systemupdate abgeschlossen ---"
echo


#############################################
# 06) Zeitsynchronisation sicherstellen
#############################################
echo "Synchronisiere Systemzeit mit chrony..."

# chrony installieren
apt-get install -y chrony

# Dienst aktivieren und starten
systemctl enable chrony --now

# Sofortige Synchronisation anstoßen
chronyc makestep

echo "Zeitsynchronisation abgeschlossen."
echo

#############################################
# 07) sudo installieren
#############################################
if ! command -v sudo >/dev/null 2>&1; then
    echo "sudo wird installiert..."
    apt-get install -y sudo
else
    echo "sudo ist bereits installiert."
fi
echo

#############################################
# 08) Admin-User "admin" anlegen oder aktualisieren
#############################################
ADMINUSER="admin"

# Prüfen, ob der Benutzer existiert
if id "$ADMINUSER" >/dev/null 2>&1; then
    echo "Benutzer '$ADMINUSER' existiert bereits."
else
    echo "Benutzer '$ADMINUSER' wird angelegt..."
    useradd -m -s /bin/bash "$ADMINUSER"
fi

# Passwort setzen (immer)
echo "Setze Passwort für Benutzer '$ADMINUSER'..."
echo "${ADMINUSER}:pass" | chpasswd

echo "Admin-User ist: $ADMINUSER"
echo

#############################################
# 09) Admin-User in sudo-Gruppe aufnehmen
#############################################
echo "Füge Benutzer '$ADMINUSER' zur sudo-Gruppe hinzu..."
usermod -aG sudo "$ADMINUSER"
echo

#############################################
# 10) sudoers-Datei für Admin-User erstellen (NOPASSWD)
#############################################
SUDOERS_FILE="/etc/sudoers.d/darknas"

echo "Erstelle sudoers-Datei für Admin-User..."

{
    echo "# DarkNAS Admin-Rechte"
    echo "admin ALL=(ALL) NOPASSWD: ALL"
} > "$SUDOERS_FILE"

chmod 440 "$SUDOERS_FILE"

echo "sudoers-Datei erstellt: $SUDOERS_FILE"
echo

#############################################
# 11) Konfigurations-Datei erstellen
#############################################
echo "Erstelle Marker-Datei: $CONFFILE"
{
    echo "POSTINSTALL_DONE=1"
    echo "ADMIN_USER=$ADMINUSER"
} > "$CONFFILE"

chmod 600 "$CONFFILE"

#############################################
# 12) ttyd installieren
#############################################
echo "Installiere ttyd..."
apt-get update -y
apt-get install -y ttyd

#############################################
# 13) systemd-Service für ttyd erstellen
#############################################
echo "Erstelle systemd-Service für ttyd..."

SERVICE_FILE="/etc/systemd/system/ttyd.service"

cat > "$SERVICE_FILE" << 'EOF'
[Unit]
Description=ttyd - Web Terminal
After=network.target

[Service]
User=root
ExecStart=/usr/bin/ttyd -p 7681 -u admin login
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

chmod 644 "$SERVICE_FILE"

#############################################
# 14) Service aktivieren und starten
#############################################
systemctl daemon-reload
systemctl enable ttyd --now

#############################################
# 15) Abschluss
#############################################
echo
echo "=== DarkNAS Postinstall abgeschlossen: $(date) ==="
echo "Der Admin-User dieses Systems lautet: $ADMINUSER"
echo "Information gespeichert in: $CONFFILE"
echo "ttyd wurde eingerichtet."
echo "Öffne im Browser: http://<SERVER-IP>:7681"
echo "Login: admin (Passwort wie gesetzt)"

