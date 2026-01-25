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
#   08) Admin-User "darkroot" anlegen oder aktualisieren
#   09) Admin-User in sudo-Gruppe aufnehmen
#   10) sudoers-Datei für Admin-User erstellen (NOPASSWD)
#   11) Marker-Konfigurationsdatei erstellen
#   12) Build-Abhängigkeiten für ttyd installieren
#   13) libwebsockets klonen und mit libuv bauen
#   14) ttyd klonen und bauen
#   15) ttyd installieren
#   16) systemd-Service für ttyd erstellen
#   17) ttyd Service aktivieren und starten
#   18) UFW installieren
#   19) UFW konfigurieren (automatische LAN-Erkennung)
#   20) Fail2ban installieren
#   21) Fail2ban konfigurieren (SSH, ttyd, SMB)
#   22) Abschlussmeldung
#
# ============================================================
#   Zweck:
#   Dieses Skript richtet das DarkNAS-Grundsystem ein:
#     - Systemupdate und Zeitsynchronisation
#     - Admin-User und sudo-Rechte
#     - ttyd (Web-Terminal) aus Quellen gebaut
#     - libwebsockets mit libuv (PTY-Support)
#     - stabiler systemd-Service ohne PAM-Self-Spawn
#
#   Design:
#     - Minimalistische, farbige Terminalausgabe
#     - Vollständiges Logging nach /var/log/darknas/…
#     - Idempotent durch Marker-Datei /etc/darknas/00_postinstall.conf
# ============================================================

clear

#############################################
# Farbdefinitionen (DarkNAS Style)
#############################################
NC="\033[0m"
CYAN="\033[36m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"

msg()      { echo -e "${CYAN}[DarkNAS]${NC} $1"; }
msg_ok()   { echo -e "${GREEN}[DarkNAS]${NC} $1"; }
msg_warn() { echo -e "${YELLOW}[DarkNAS]${NC} $1"; }
msg_err()  { echo -e "${RED}[DarkNAS]${NC} $1"; }


#############################################
# 01) PATH sicherstellen
#############################################
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"


#############################################
# 02) Root-Prüfung
#############################################
if [[ $EUID -ne 0 ]]; then
    msg_err "Dieses Skript muss als root ausgeführt werden."
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
    ____             _      _   _    _    ____
   |  _ \  __ _ _ __| | __ | \ | |  / \  / ___|
   | | | |/ _´ | ´__| |/ / |  \| | / _ \ \___ \
   | |_| | |_| | |  |   |  | |\  |/ ___ \ ___| |
   |____/ \__._|_|  |_|\_\ |_| \_/_/   \_\____/
Data belongs in the dark. Simple. Silent. Reliable.
EOF

echo
msg_ok "Postinstall gestartet – Log: $LOGFILE"
echo


#############################################
# 04) Konfigurations-Verzeichnis vorbereiten
#############################################
CONFDIR="/etc/darknas"
CONFFILE="$CONFDIR/00_postinstall.conf"

mkdir -p "$CONFDIR"

if [[ -f "$CONFFILE" ]]; then
    msg_warn "Marker-Datei existiert – Skript wurde bereits ausgeführt."
    exit 0
fi


#############################################
# 05) Systemupdate
#############################################
msg "Systemupdate…"
apt-get update -y >/dev/null 2>&1
apt-get upgrade -y >/dev/null 2>&1
msg_ok "Systemupdate abgeschlossen."


#############################################
# 06) Zeitsynchronisation sicherstellen (chrony)
#############################################
msg "Installiere und aktiviere chrony…"

apt-get install -y chrony >/dev/null 2>&1
systemctl enable chrony --now >/dev/null 2>&1
chronyc makestep >/dev/null 2>&1

msg_ok "Zeitsynchronisation abgeschlossen."


#############################################
# 07) sudo installieren
#############################################
if ! command -v sudo >/dev/null 2>&1; then
    msg "Installiere sudo…"
    apt-get install -y sudo >/dev/null 2>&1
    msg_ok "sudo installiert."
else
    msg "sudo bereits installiert."
fi


#############################################
# 08) Admin-User anlegen/aktualisieren
#############################################
ADMINUSER="darkroot"

if id "$ADMINUSER" >/dev/null 2>&1; then
    msg "Benutzer '$ADMINUSER' existiert bereits."
else
    msg "Lege Benutzer '$ADMINUSER' an…"
    useradd -m -s /bin/bash "$ADMINUSER"
    msg_ok "Benutzer '$ADMINUSER' angelegt."
fi

# Passwort-Abfrage mit Bestätigung
while true; do
    echo -n "Passwort für '$ADMINUSER' eingeben: "
    read -s PW1
    echo

    echo -n "Passwort erneut eingeben: "
    read -s PW2
    echo

    if [[ "$PW1" == "$PW2" ]]; then
        break
    else
        msg "Passwörter stimmen nicht überein. Bitte erneut versuchen."
    fi
done

echo "${ADMINUSER}:${PW1}" | chpasswd
msg_ok "Passwort für '$ADMINUSER' gesetzt."
."


#############################################
# 09) Admin-User in sudo-Gruppe aufnehmen
#############################################
msg "Füge '$ADMINUSER' zur sudo-Gruppe hinzu…"
usermod -aG sudo "$ADMINUSER"
msg_ok "'$ADMINUSER' ist Mitglied der sudo-Gruppe."


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
msg_ok "sudoers-Datei erstellt."


#############################################
# 11) Marker-Konfigurationsdatei erstellen
#############################################
msg "Erstelle Marker-Datei…"

{
    echo "POSTINSTALL_DONE=1"
    echo "ADMIN_USER=$ADMINUSER"
} > "$CONFFILE"

chmod 600 "$CONFFILE"
msg_ok "Marker-Datei erstellt."


#############################################
# 12) Build-Abhängigkeiten für ttyd installieren
#############################################
msg "Installiere Build-Abhängigkeiten für ttyd…"

apt-get update -y >/dev/null 2>&1
apt-get install -y \
    git build-essential cmake pkg-config \
    libssl-dev libjson-c-dev zlib1g-dev \
    libuv1-dev >/dev/null 2>&1

msg_ok "Build-Abhängigkeiten installiert."


#############################################
# 13) libwebsockets klonen und mit libuv bauen
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

msg_ok "libwebsockets erfolgreich gebaut."


#############################################
# 14) ttyd klonen und bauen
#############################################
msg "Klone und baue ttyd…"

cd /usr/local/src
rm -rf ttyd >/dev/null 2>&1
git clone https://github.com/tsl0922/ttyd.git >/dev/null 2>&1

cd ttyd
mkdir build >/dev/null 2>&1
cd build

cmake .. >/dev/null 2>&1
make -j"$(nproc)" >/dev/null 2>&1

msg_ok "ttyd erfolgreich gebaut."


#############################################
# 15) ttyd installieren
#############################################
msg "Installiere ttyd…"

make install >/dev/null 2>&1

msg_ok "ttyd erfolgreich installiert."


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

msg_ok "ttyd systemd-Service-Datei erstellt."


#############################################
# 17) ttyd Service aktivieren und starten
#############################################
msg "Aktiviere und starte ttyd-Service…"

systemctl daemon-reload >/dev/null 2>&1
systemctl enable ttyd --now >/dev/null 2>&1

msg_ok "ttyd systemd-Service aktiviert und gestartet."

#############################################
# 18) UFW installieren
#############################################
msg "Installiere UFW Firewall…"

apt-get install -y ufw >/dev/null 2>&1

msg_ok "UFW installiert."


#############################################
# 19) UFW konfigurieren (automatische LAN-Erkennung)
#############################################
msg "Ermittle internes LAN…"

# Erste globale IPv4-Adresse extrahieren
LAN_CIDR=$(ip -o -f inet addr show | awk '/scope global/ {print $4; exit}')

if [[ -z "$LAN_CIDR" ]]; then
    msg_warn "Konnte internes LAN nicht automatisch erkennen. Setze Fallback 192.168.0.0/16."
    LAN_CIDR="192.168.0.0/16"
else
    msg_ok "Internes LAN erkannt: $LAN_CIDR"
fi

msg "Richte UFW Firewall-Regeln ein…"

# Standard-Policies
ufw default deny incoming >/dev/null 2>&1
ufw default allow outgoing >/dev/null 2>&1

# Externe Freigaben
ufw allow 80/tcp    >/dev/null 2>&1   # HTTP extern
ufw allow 443/tcp   >/dev/null 2>&1   # HTTPS extern

# Interne Freigaben
ufw allow from "$LAN_CIDR" to any port 22    proto tcp >/dev/null 2>&1   # SSH intern
ufw allow from "$LAN_CIDR" to any port 7681  proto tcp >/dev/null 2>&1   # ttyd intern
ufw allow from "$LAN_CIDR" to any port 445   proto tcp >/dev/null 2>&1   # SMB intern

# Aktivieren (ohne Nachfrage)
echo "y" | ufw enable >/dev/null 2>&1

msg_ok "UFW Firewall aktiviert und konfiguriert."

#############################################
# 20) Fail2ban installieren
#############################################
msg "Installiere Fail2ban…"

apt-get install -y fail2ban >/dev/null 2>&1

msg_ok "Fail2ban installiert."


#############################################
# 21) Fail2ban konfigurieren (SSH, ttyd, SMB)
#############################################
msg "Konfiguriere Fail2ban…"

# Fail2ban-Konfigurationsverzeichnis
F2B_JAIL="/etc/fail2ban/jail.local"

cat > "$F2B_JAIL" << 'EOF'
[DEFAULT]
# Ban-Dauer: 10 Minuten
bantime = 10m
# Beobachtungszeitraum: 10 Minuten
findtime = 10m
# Anzahl Fehlversuche bis Ban
maxretry = 5
# Firewall-Aktion
banaction = ufw

# -------------------------
# SSH Schutz
# -------------------------
[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log

# -------------------------
# ttyd Schutz (über PAM)
# ttyd nutzt login → auth.log
# -------------------------
[ttyd]
enabled = true
port = 7681
filter = sshd
logpath = /var/log/auth.log

# -------------------------
# SMB Schutz (optional)
# -------------------------
[smb]
enabled = true
port = 445
logpath = /var/log/samba/log.smbd
EOF

# Fail2ban neu starten
systemctl restart fail2ban >/dev/null 2>&1

msg_ok "Fail2ban konfiguriert und gestartet."


#############################################
# 22) Abschluss
#############################################
msg_ok "Postinstall abgeschlossen."
msg "Admin-User: $ADMINUSER"
msg "ttyd läuft auf Port 7681."
msg "Öffne im Browser: http://<SERVER-IP>:7681"
