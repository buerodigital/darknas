#!/bin/bash
#
# 00_postinstall.sh – DarkNAS Grundsystem
#

#############################################
# Minimalistische Terminalausgabe
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

exec > >(tee -a "$LOGFILE") 2>&1

#############################################
# DarkNAS Logo
#############################################
cat << "EOF"
   ____             _      _   _   _   _____ 
  |  _ \  __ _ _ __(_) ___| \ | | / \ | ____|
  | | | |/ _` | '__| |/ __|  \| |/ _ \|  _|  
  | |_| | (_| | |  | | (__| |\  / ___ \ |___ 
  |____/ \__,_|_|  |_|\___|_| \_/_/   \_\____|
  
        Data belongs in the dark.
        Simple. Silent. Reliable.
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
#############################################
msg "Erstelle Marker-Datei…"
{
    echo "POSTINSTALL_DONE=1"
    echo "ADMIN_USER=$ADMINUSER"
} > "$CONFFILE"

chmod 600 "$CONFFILE"

#############################################
# 12) Abhängigkeiten für ttyd installieren
#############################################
msg "Installiere Build-Abhängigkeiten für ttyd…"

apt-get update -y >/dev/null 2>&1
apt-get install -y \
    git build-essential cmake pkg-config \
    libssl-dev libjson-c-dev zlib1g-dev \
    libuv1-dev >/dev/null 2>&1

#############################################
# 13) libwebsockets klonen und bauen
#############################################
msg "Baue libwebsockets (mit libuv)…"

cd /usr/local/src
rm -rf libwebsockets >/dev/null 2>&1
git clone https://github.com/warmcat/libwebsockets.git >/dev/null 2>&1

cd libwebsockets
mkdir build >/dev/null 2>&1
cd build

cmake .. \
    -DLWS_WITH_LIBUV=ON \
    -DLWS_WITH_SERVER=ON \
    -DLWS_WITH_CLIENT=ON \
    -DLWS_WITH_HTTP2=ON \
    -DLWS_WITHOUT_TESTAPPS=ON \
    >/dev/null 2>&1

make -j"$(nproc)" >/dev/null 2>&1
make install >/dev/null 2>&1

export PATH="$PATH:/sbin:/usr/sbin"
ldconfig >/dev/null 2>&1

#############################################
# 14) ttyd klonen und bauen
#############################################
msg "Baue ttyd…"

cd /usr/local/src
rm -rf ttyd >/dev/null 2>&1
git clone https://github.com/tsl0922/ttyd.git >/dev/null 2>&1

cd ttyd
mkdir build >/dev/null 2>&1
cd build

cmake .. >/dev/null 2>&1
make -j"$(nproc)" >/dev/null 2>&1
make install >/dev/null 2>&1

#############################################
# 16) systemd-Service für ttyd erstellen
#############################################
msg "Erstelle systemd-Service…"

cat > /etc/systemd/system/ttyd.service << 'EOF'
[Unit]
Description=ttyd - Web Terminal
After=network.target

[Service]
ExecStart=/usr/local/bin/ttyd --writable -p 7681 login
Restart=always
RestartSec=2
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload >/dev/null 2>&1
systemctl enable ttyd --now >/dev/null 2>&1

#############################################
# 18) Abschluss
#############################################
msg "Postinstall abgeschlossen."
msg "Admin-User: $ADMINUSER"
msg "ttyd läuft auf Port 7681."
msg "Öffne im Browser: http://<SERVER-IP>:7681"
