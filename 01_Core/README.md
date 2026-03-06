Via ssh verbinden und einloggen
````
su
````


Variante 1 - Git installieren, Repo klonen, Berechtigungen setzen und starten
````
cd ~
apt install -y git
git clone https://github.com/buerodigital/darknas.git
chmod +x ~/darknas/01_Core/0000_postinstall.sh
~/darknas/01_Core/0000_postinstall.sh

````

Variante 2 - Wget download postinstall
````
apt install -y wget
wget --no-check-certificate https://darknas.ideenrocker.com/00_postinstall.sh -O /usr/local/sbin/00_postinstall.sh

````


Nach dem Neustart kann die Konsole via Browser geöffnet werden
http://IP:7681/



|Zweck|Pfad  |Warum|Berechtigungen   |Kurzbewertung   |
|-----|-----|-----|-----|-----|
|Konfiguration   |/etc/darknas   |Systemkonfigs gehören nach /etc   |root:root 644   |Standard, leicht editierbar   |
|Binärskripte   |/usr/local/bin/darknas   |Systemweite ausführbare Tools   |root:root 755   |Einfach im PATH   |
|Module   |/opt/darknas/modules   |große modulare Komponenten   |root:root 755   |Sauber, isoliert  |
|Logs   |/var/log/darknas   |rotierbare Logs   |root:adm 640   |kompatibel mit logrotate   |
|Daten Mounts   |/mnt/pool   |MergerFS/SnapRAID Mountpoints   |root:root 755   |klar trennbar   |

## 📋 01 CORE

### 1.1 Basic Setup
- [ ] **Minimal Debian Net Install** vorbereiten (Hostname!)
- [ ] **SSH-Konfiguration sichern** (Port, Key-Auth, Fail2Ban vorbereiten)
- [ ] **Alte User löschen** (UID >= 1000)
- [ ] **Admin-User erstellen** mit Sudo-Rechten
- [ ] **Zeitsynchronisation (Chrony)** - **KRITISCH für Logs, Datenstempel, Netzwerk**
- [ ] **Verzeichnisstruktur planen** (/mnt/disk1, /mnt/disk2, /mnt/pool, /mnt/usb...)
- [ ] **Systemd-Unit-Generator Script** (Services autostart)
- [ ] **Cron-Job-Manager Script** (regelmäßige Tasks)
- [ ] **Standardisiertes Skript-Template** (für Dritte)
- [ ] **Plugin-System** (neue Features hinzufügbar)
- [ ] **Konfigurationsformat standardisieren**
- [ ] **Menü-System** (interaktive Admin-CLI)
- [ ] **Logging & Debugging** standardisieren
      
### 1.2 Remote-Administration
- [ ] **ttyd installieren** (Web-Terminal für Admin)

### 1.3 Framework
- [ ] **Skript-Framework** erstellen (Verzeichnisstruktur, Logging, Error-Handling)
- [ ] **Datei-System** (zentrale /etc/nas/ oder ähnlich)

### 1.4 Security
- [ ] **Fail2Ban einrichten** (SSH-Schutz)
- [ ] **Firewall (UFW/iptables)** mit Basis-Regeln (SSH, SMB, ttyd nur lokal)
- [ ] **Firewall-Regeln für SMB** (445, 139)

