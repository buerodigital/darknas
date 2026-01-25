#!/bin/bash
#
# 00_postinstall.sh
#
# DarkNAS Grundsystem:
# 01) PATH sicherstellen
# 02) Root-Prüfung
# 03) Logdatei vorbereiten
# 04) Konfigurations-Verzeichnis vorbereiten
# 05) Systemupdate
# 06) Zeitsynchronisation sicherstellen
# 07) sudo installieren
# 08) Admin-User "admin" anlegen oder aktualisieren
# 09) Admin-User in sudo-Gruppe aufnehmen
# 10) sudoers-Datei für Admin-User erstellen (NOPASSWD)
# 11) Konfigurations-Datei erstellen
# 12) Abhängigkeiten für ttyd installieren (NEU)
# 13) libwebsockets klonen und bauen (NEU)
# 14) ttyd klonen und bauen (NEU)
# 15) ttyd installieren (NEU)
# 16) systemd-Service für ttyd erstellen (NEU)
# 17) ttyd Service aktivieren und starten
# 18) Abschluss

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

apt-get install -y chrony
systemctl enable chrony --now
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

if id "$ADMINUSER" >/dev/null 2>&1; then
    echo "Benutzer '$ADMINUSER' existiert bereits."
else
    echo "Benutzer '$ADMINUSER' wird angelegt..."
    useradd -m -s /bin/bash "$ADMINUSER"
fi

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
# 12) Abhängigkeiten für ttyd installieren
#############################################
echo "=== Installiere ttyd (Build aus Quellen) ==="
echo "Installiere Build-Abhängigkeiten..."

apt-get update -y
apt-get install -y \
    git build-essential cmake pkg-config \
    libssl-dev libjson-c-dev zlib1g-dev \
    libuv1-dev

echo "Abhängigkeiten installiert."
echo

#############################################
# 13) libwebsockets klonen und bauen
#############################################
echo "Baue libwebsockets (mit libuv)..."

cd /usr/local/src
rm -rf libwebsockets
git clone https://github.com/warmcat/libwebsockets.git

cd libwebsockets
mkdir build
cd build

cmake .. \
    -DLWS_WITH_LIBUV=ON \
    -DLWS_WITH_SERVER=ON \
    -DLWS_WITH_CLIENT=ON \
    -DLWS_WITH_HTTP2=ON \
    -DLWS_WITHOUT_TESTAPPS=ON

make -j"$(nproc)"
make install

# ldconfig sicherstellen
export PATH="$PATH:/sbin:/usr/sbin"
ldconfig

echo "libwebsockets erfolgreich gebaut."
echo

#############################################
# 14) ttyd klonen und bauen
#############################################
echo "Klone und baue ttyd..."

cd /usr/local/src
rm -rf ttyd
git clone https://github.com/tsl0922/ttyd.git

cd ttyd
mkdir build
cd build

cmake ..
make -j"$(nproc)"

echo "ttyd Build abgeschlossen."
echo

#############################################
# 15) ttyd installieren
#############################################
echo "Installiere ttyd nach /usr/local/bin..."

make install

echo "Installation abgeschlossen."
echo

#############################################
# 16) systemd-Service für ttyd erstellen
#############################################
echo "Erstelle systemd-Service..."

SERVICE_FILE="/etc/systemd/system/ttyd.service"

cat > "$SERVICE_FILE" << 'EOF'
[Unit]
Description=ttyd - Web Terminal
After=network.target

[Service]
ExecStart=/usr/local/bin/ttyd --writable -p 7681 login
Restart=always
RestartSec=2
User=root
Group=root
# Kein PAMName, um Self-Spawn zu verhindern

[Install]
WantedBy=multi-user.target
EOF

chmod 644 "$SERVICE_FILE"

echo "systemd-Service erstellt."
echo

#############################################
# 17) ttyd Service aktivieren und starten
#############################################
echo "Aktiviere und starte ttyd..."

systemctl daemon-reload
systemctl enable ttyd --now

#############################################
# 18) Abschluss
#############################################
echo
echo "=== DarkNAS Postinstall abgeschlossen: $(date) ==="
echo "Der Admin-User dieses Systems lautet: $ADMINUSER"
echo "Information gespeichert in: $CONFFILE"
echo "ttyd wurde erfolgreich eingerichtet."
echo "Öffne im Browser: http://<SERVER-IP>:7681"
echo "Login: admin (Passwort wie gesetzt)"
