#!/bin/bash
#
# 00_postinstall.sh – DarkNAS Grundsystem
#
# ============================================================
#                    I N H A L T S  V E R Z E I C H N I S
# ============================================================
#   01) Variablen definieren
#   02) Hostname setzen
#   03) PATH sicherstellen
#   04) Root-Prüfung
#   05) Logdatei vorbereiten
#   06) Konfigurations-Verzeichnis vorbereiten
#   07) Systemupdate
#   08) Zeitsynchronisation sicherstellen (chrony)
#   09) sudo installieren
#   10) Admin-User anlegen/aktualisieren
#   11) Admin-User in sudo-Gruppe aufnehmen
#   12) sudoers-Datei erstellen
#   13) Marker-Konfigurationsdatei erstellen
#   14) Build-Abhängigkeiten für ttyd installieren
#   15) libwebsockets klonen und mit libuv bauen
#   16) ttyd klonen und bauen
#   17) ttyd installieren
#   18) SSL-Zertifikate für ttyd erstellen
#   19) systemd-Service für ttyd erstellen (nur $ADMINUSER, SSL)
#   20) ttyd-Service aktivieren und starten
#   21) UFW installieren
#   22) UFW konfigurieren (automatische LAN-Erkennung)
#   23) Fail2ban installieren
#   24) Fail2ban konfigurieren
#   25) Abschlussmeldung + Neustart
# ============================================================

clear

#############################################
# 01) Variablen definieren
#############################################

# Hostname fuer DarkNAS
HOSTNAME_DARKNAS="darkNAS"

# IP des darkNAS Systems
SERVER_IP=$(hostname -I | awk '{print $1}')

# Admin-Benutzer fuer DarkNAS
ADMINUSER="darkroot"

# System-User fuer ttyd (ohne Login, ohne Home)
TTYDUSER="ttyduser"

# Port fuer ttyd
TTYD_PORT="7681"

# DarkNAS Konfigurationspfade
CONFDIR="/etc/darknas"
CONFFILE="$CONFDIR/00_postinstall.conf"

# Logging
LOGDIR="/var/log/darknas"
DATE=$(date +"%Y-%m-%d")
LOGFILE="$LOGDIR/${DATE}_00_postinstall.log"

# sudoers-Datei
SUDOERS_FILE="/etc/sudoers.d/darknas"

# Farbdefinitionen
NC="\033[0m"
CYAN="\033[36m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"

msg()      { echo -e "${CYAN}[DarkNAS]${NC} $1" >/dev/tty; }
msg_ok()   { echo -e "${GREEN}[DarkNAS]${NC} $1" >/dev/tty; }
msg_warn() { echo -e "${YELLOW}[DarkNAS]${NC} $1" >/dev/tty; }
msg_err()  { echo -e "${RED}[DarkNAS]${NC} $1" >/dev/tty; }


#############################################
# DarkNAS Logo
#############################################
cat >/dev/tty << "EOF"
    ____             _      _   _    _    ____
   |  _ \  __ _ _ __| | __ | \ | |  / \  / ___|
   | | | |/ _´ | ´__| |/ / |  \| | / _ \ \___ \
   | |_| | |_| | |  |   |  | |\  |/ ___ \ ___| |
   |____/ \__._|_|  |_|\_\ |_| \_/_/   \_\____/
Data belongs in the dark. Simple. Silent. Reliable.
EOF

echo
msg_ok "Postinstall gestartet – Log: $LOGFILE"


#############################################
# 02) Hostname setzen
#############################################
msg "Setze Hostname auf '$HOSTNAME_DARKNAS'..."

hostnamectl set-hostname "$HOSTNAME_DARKNAS"
echo "$HOSTNAME_DARKNAS" > /etc/hostname

# /etc/hosts aktualisieren
if grep -q "^127.0.1.1" /etc/hosts; then
    sed -i "s/^127.0.1.1.*/127.0.1.1   $HOSTNAME_DARKNAS/" /etc/hosts
else
    echo "127.0.1.1   $HOSTNAME_DARKNAS" >> /etc/hosts
fi

msg_ok "Hostname gesetzt."


#############################################
# 03) PATH sicherstellen
#############################################
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"


#############################################
# 04) Root-Prüfung
#############################################
if [[ $EUID -ne 0 ]]; then
    msg_err "Dieses Skript muss als root ausgeführt werden."
    exit 1
fi


#############################################
# 05) Logdatei vorbereiten
#############################################
mkdir -p "$LOGDIR"
exec >"$LOGFILE" 2>&1



#############################################
# 06) Konfigurations-Verzeichnis vorbereiten
#############################################
mkdir -p "$CONFDIR"

if [[ -f "$CONFFILE" ]]; then
    msg_warn "Marker-Datei existiert – Skript wurde bereits ausgeführt."
    exit 0
fi


#############################################
# 07) Systemupdate
#############################################
msg "Systemupdate..."
apt-get update -y
apt-get upgrade -y
msg_ok "Systemupdate abgeschlossen."


#############################################
# 08) Zeitsynchronisation sicherstellen (chrony)
#############################################
msg "Installiere und aktiviere chrony..."
apt-get install -y chrony
systemctl enable chrony --now
chronyc makestep
msg_ok "Zeitsynchronisation abgeschlossen."


#############################################
# 09) sudo installieren
#############################################
if ! command -v sudo; then
    msg "Installiere sudo..."
    apt-get install -y sudo
    msg_ok "sudo installiert."
else
    msg "sudo bereits installiert."
fi


#############################################
# 10) Admin-User anlegen/aktualisieren
#############################################
if id "$ADMINUSER"; then
    msg "Benutzer '$ADMINUSER' existiert bereits."
else
    msg "Lege Benutzer '$ADMINUSER' an..."
    useradd -m -s /bin/bash "$ADMINUSER"
    msg_ok "Benutzer '$ADMINUSER' angelegt."
fi

while true; do
    # Prompt 1
    echo -n "          Passwort für '$ADMINUSER' eingeben: " >/dev/tty
    read -s PW1 < /dev/tty
    echo >/dev/tty

    # Prompt 2
    echo -n "          Passwort erneut eingeben: " >/dev/tty
    read -s PW2 < /dev/tty
    echo >/dev/tty

    [[ "$PW1" == "$PW2" ]] && break

    msg_err "Passwörter stimmen nicht überein."
done

echo "${ADMINUSER}:${PW1}" | chpasswd
msg_ok "Passwort für '$ADMINUSER' gesetzt."


#############################################
# 11) Admin-User in sudo-Gruppe aufnehmen
#############################################
msg "Füge '$ADMINUSER' zur sudo-Gruppe hinzu..."
usermod -aG sudo "$ADMINUSER"
msg_ok "'$ADMINUSER' ist Mitglied der sudo-Gruppe."


#############################################
# 12) sudoers-Datei erstellen
#############################################
msg "Erstelle sudoers-Datei..."

{
    echo "# DarkNAS Admin-Rechte"
    echo "${ADMINUSER} ALL=(ALL) NOPASSWD: ALL"
} > "$SUDOERS_FILE"

chmod 440 "$SUDOERS_FILE"
msg_ok "sudoers-Datei erstellt."


#############################################
# 13) Marker-Konfigurationsdatei erstellen
#############################################
msg "Erstelle Marker-Datei..."

{
    echo "POSTINSTALL_DONE=1"
    echo "ADMIN_USER=$ADMINUSER"
} > "$CONFFILE"

chmod 600 "$CONFFILE"
msg_ok "Marker-Datei erstellt."


#############################################
# 14) Build-Abhängigkeiten für ttyd installieren
#############################################
msg "Installiere Build-Abhängigkeiten für ttyd..."

apt-get install -y \
    git build-essential cmake pkg-config \
    libssl-dev libjson-c-dev zlib1g-dev \
    libuv1-dev

msg_ok "Build-Abhängigkeiten installiert."


#############################################
# 15) libwebsockets klonen und bauen (mit libuv)
#############################################
msg "Baue libwebsockets (mit libuv)..."

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
    -DLWS_WITHOUT_TESTAPPS=ON \

make -j"$(nproc)"
make install
/sbin/ldconfig

msg_ok "libwebsockets erfolgreich gebaut."


#############################################
# 16) ttyd klonen und bauen
#############################################
msg "Klone und baue ttyd..."

cd /usr/local/src
rm -rf ttyd
git clone https://github.com/tsl0922/ttyd.git

cd ttyd
mkdir build
cd build

cmake ..
make -j"$(nproc)"

msg_ok "ttyd erfolgreich gebaut."


#############################################
# 17) ttyd installieren
#############################################
msg "Installiere ttyd..."
make install
/sbin/ldconfig
msg_ok "ttyd erfolgreich installiert."


#############################################
# 18) SSL-Zertifikate für ttyd erstellen
#############################################
msg "Erstelle SSL-Zertifikate für ttyd..."

mkdir -p /etc/ttyd/ssl

openssl req -x509 -nodes -days 3650 \
  -newkey rsa:2048 \
  -keyout /etc/ttyd/ssl/ttyd.key \
  -out /etc/ttyd/ssl/ttyd.crt \
  -subj "/CN=darkNAS"

chmod 600 /etc/ttyd/ssl/ttyd.key
msg_ok "SSL-Zertifikate erstellt."


#############################################
# 19) systemd-Service für ttyd erstellen
# → nur Login für $ADMINUSER
# → HTTPS aktiviert
#############################################
msg "Erstelle systemd-Service..."

cat > /etc/systemd/system/ttyd.service << EOF
[Unit]
Description=ttyd - Web Terminal (SSL)
After=network.target

[Service]
ExecStart=/usr/local/bin/ttyd \
  --ssl \
  --ssl-cert /etc/ttyd/ssl/ttyd.crt \
  --ssl-key  /etc/ttyd/ssl/ttyd.key \
  --writable \
  -p ${TTYD_PORT} \
  /bin/su - ${ADMINUSER}
Restart=always
RestartSec=2
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

msg_ok "ttyd systemd-Service-Datei erstellt."


#############################################
# 20) ttyd Service aktivieren und starten
#############################################
msg "Aktiviere und starte ttyd-Service..."

systemctl daemon-reload
systemctl enable ttyd --now

msg_ok "ttyd systemd-Service aktiviert und gestartet."


#############################################
# 21) UFW installieren
#############################################
msg "Installiere UFW Firewall..."
apt-get install -y ufw
msg_ok "UFW installiert."


#############################################
# 22) UFW konfigurieren
#############################################
msg "Ermittle internes LAN..."

LAN_CIDR=$(ip -o -f inet addr show | awk '/scope global/ {print $4; exit}')

[[ -z "$LAN_CIDR" ]] && LAN_CIDR="192.168.0.0/16"

msg_ok "Internes LAN erkannt: $LAN_CIDR"

msg "Richte UFW Firewall-Regeln ein..."

ufw default deny incoming
ufw default allow outgoing

ufw allow 80/tcp
ufw allow 443/tcp

ufw allow from "$LAN_CIDR" to any port 22 proto tcp
ufw allow from "$LAN_CIDR" to any port ${TTYD_PORT} proto tcp
ufw allow from "$LAN_CIDR" to any port 445 proto tcp

echo "y" | ufw enable

msg_ok "UFW Firewall aktiviert und konfiguriert."


#############################################
# 23) Fail2ban installieren
#############################################
msg "Installiere Fail2ban..."
apt-get install -y fail2ban
msg_ok "Fail2ban installiert."


#############################################
# 24) Fail2ban konfigurieren
#############################################
msg "Konfiguriere Fail2ban..."

cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 10m
findtime = 10m
maxretry = 5
banaction = ufw

[sshd]
enabled = true
port = ssh
backend = systemd
logpath = /var/log/auth.log

[smb]
enabled = true
port = 445
logpath = /var/log/samba/log.smbd
EOF

systemctl restart fail2ban
msg_ok "Fail2ban konfiguriert und gestartet."


#############################################
# 25) Abschlussmeldung + Neustart
#############################################
msg_ok "Postinstall abgeschlossen."
msg "Admin-User: $ADMINUSER"
msg "Hostname: $HOSTNAME_DARKNAS"
msg "ttyd läuft auf: http://${SERVER_IP}:${TTYD_PORT}"
echo
echo "Drücke ENTER für Neustart..."
read

msg "Starte neu..."
reboot
