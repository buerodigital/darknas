#!/bin/bash
#
# 0000_postinstall.sh – DarkNAS Grundsystem
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
# 01) DarkNAS Logo
#############################################

cat ~/darknas/01_Core/darknaslogo.txt
echo


#############################################
# 02) Root-Prüfung
#############################################

dark_checkroot() {
if [[ $EUID -ne 0 ]]; then
    echo "Dieses Skript muss als root ausgeführt werden."
    exit 1
fi
}

dark_checkroot


#############################################
# 03) Variablen definieren und Konfigurationsfile einrichten
#############################################

dark_set_variables() {
# Umgebungsvariablen setzen
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Konfigurationsfile anlegen und sourcen
mv ~/darknas/01_Core/darknas.conf /etc/darknas.conf
chown root:root /etc/darknas.conf
chmod 644 /etc/darknas.conf
source /etc/darknas.conf
}

dark_set_variables > /dev/null 2>&1


#############################################
# 04) Logging
#############################################

dark_log() {
# Logging vorbereiten
mkdir -p "$LOGDIR"
LOGFILE="$LOGDIR/${DATE}_00_postinstall.log"

exec 3>&1 4>&2
exec >"$LOGFILE" 2>&1
}

dark_log
msg_ok "Postinstall gestartet – Log: $LOGFILE"

# Am Ende des Scriptes unbedingt "exec 1>&3 2>&4" ausführen


#############################################
# 05) Hostname setzen
#############################################

dark_set_hostname() {
hostnamectl set-hostname "$HOSTNAME_DARKNAS"
echo "$HOSTNAME_DARKNAS" > /etc/hostname

# /etc/hosts aktualisieren
if grep -q "^127.0.1.1" /etc/hosts; then
    sed -i "s/^127.0.1.1.*/127.0.1.1   $HOSTNAME_DARKNAS/" /etc/hosts
else
    echo "127.0.1.1   $HOSTNAME_DARKNAS" >> /etc/hosts
fi
}

msg "Setze Hostname auf '$HOSTNAME_DARKNAS'..."
dark_set_hostname
msg_ok "Hostname gesetzt."


#############################################
# 06) Systemupdate
#############################################

msg "Systemupdate..."
source ./0010_update.sh
dark_update
msg_ok "Systemupdate abgeschlossen."


#############################################
# 07) Zeitsynchronisation sicherstellen (chrony)
#############################################

dark_install_chrony() {
apt-get install -y chrony
systemctl enable chrony --now
chronyc makestep
}

msg "Installiere und aktiviere chrony..."
dark_install_chrony
msg_ok "Zeitsynchronisation abgeschlossen."


#############################################
# 08) sudo installieren
#############################################

dark_install_sudo(){
if ! command -v sudo; then
    apt-get install -y sudo
fi
}

msg "Installiere sudo..."
dark_install_sudo
msg_ok "sudo installiert."


#############################################
# 09) Privilegierte Ports für nicht-root-User freigeben
# → Ports unter 1024 für non-root User freigeben
#############################################

dark_ports() {
echo 'net.ipv4.ip_unprivileged_port_start=0' | sudo tee /etc/sysctl.d/99-unprivileged-ports.conf
sysctl --system
}

msg "Priviligierte Ports für non-root user zulassen..."
dark_ports
msg_ok "Ports freigegeben"


#############################################
# 10) Admin-User anlegen/aktualisieren,
#     in die sudo Gruppe aufnehmen,
#     sudoers-Datei erstellen
#############################################

dark_create_admin() {

if id "$ADMINUSER" &>/dev/null; then
    msg "Benutzer '$ADMINUSER' existiert bereits."
else
    msg "Lege Benutzer '$ADMINUSER' an..."
    useradd -m -s /bin/bash "$ADMINUSER"
    msg_ok "Benutzer '$ADMINUSER' angelegt."
fi


# Passwort ohne Interaktion setzen
echo "${ADMINUSER}:${ADMINPASS}" | chpasswd
msg_ok "Passwort für '$ADMINUSER' gesetzt."


# User in die sudo Gruppe aufnehmen 
msg "Füge '$ADMINUSER' zur sudo-Gruppe hinzu..."
usermod -aG sudo "$ADMINUSER"
msg_ok "'$ADMINUSER' ist Mitglied der sudo-Gruppe."


# sudoers-Datei erstellen
msg "Erstelle sudoers-Datei..."
{
    echo "# DarkNAS Admin-Rechte"
    echo "${ADMINUSER} ALL=(ALL) NOPASSWD: ALL"
} > "$SUDOERS_FILE"

chmod 440 "$SUDOERS_FILE"
msg_ok "sudoers-Datei erstellt."

}

dark_create_admin


#############################################
# 11) ttyd installieren
#############################################

dark_install_ttyd() {
apt install -y libssl-dev 
apt install -y ~/darknas/01_Core/ttyd_1.7.7-4_amd64.deb
apt install -y ~/darknas/01_Core/libwebsockets-dev_4.3.5-3_amd64.deb
}

msg "Installiere ttyd..."
dark_install_ttyd
msg_ok "ttyd erfolgreich installiert."


#############################################
# 12) SSL-Zertifikate für ttyd erstellen
#############################################

dark_ttyd_ssl() {
mkdir -p /etc/ttyd/ssl

openssl req -x509 -nodes -days 3650 \
  -newkey rsa:2048 \
  -keyout /etc/ttyd/ssl/ttyd.key \
  -out /etc/ttyd/ssl/ttyd.crt \
  -subj "/CN=darkNAS"

chmod 600 /etc/ttyd/ssl/ttyd.key
}

msg "Erstelle SSL-Zertifikate für ttyd..."
dark_ttyd_ssl
msg_ok "SSL-Zertifikate erstellt."


#############################################
# 13) systemd-Service für ttyd erstellen
# → Login für $ADMINUSER
# → HTTPS aktiviert
#############################################

dark_ttyd_service() {
cat > /etc/systemd/system/ttyd.service << EOF
[Unit]
Description=ttyd - Web Terminal (SSL)
After=network.target

[Service]
ExecStart=/usr/bin/ttyd --ssl --ssl-cert /etc/ttyd/ssl/ttyd.crt --ssl-key /etc/ttyd/ssl/ttyd.key --writable -p ${TTYD_PORT} /bin/su - ${ADMINUSER}
Restart=always
RestartSec=2
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ttyd
}

msg "Erstelle und starte systemd-Service..."
dark_ttyd_service
msg_ok "ttyd systemd-Service-Datei erstellt, Service gestartet."


#############################################
# 14) UFW installieren und konfigurieren
#############################################

darf_ufw() {
apt install -y ufw

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
}

msg "Installiere UFW Firewall..."
darf_ufw
msg_ok "UFW installiert und konfiguriert."



#############################################
# 23) Fail2ban installieren und konfigurieren
#############################################

dark_fail2ban(){
apt install -y fail2ban

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
}

msg "Installiere Fail2ban..."
dark_fail2ban
msg_ok "Fail2ban installiert und konfiguriert."


#############################################
# XX) Abschlussmeldung + Neustart
#############################################

# IP des darkNAS Systems
SERVER_IP=$(hostname -I | awk '{print $1}')

msg_ok "Postinstall abgeschlossen."
msg "Admin-User: $ADMINUSER"
msg "Podman-User: $PODMANUSER"
msg "Hostname: $HOSTNAME_DARKNAS"
msg "ttyd läuft auf: http://${SERVER_IP}:${TTYD_PORT}"


exec 1>&3 2>&4
echo
echo "Drücke ENTER für Neustart..."
read < /dev/tty
echo "Starte neu..."

reboot
