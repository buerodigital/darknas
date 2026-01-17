# darkNAS
Data belongs in the dark. Simple. Silent. Reliable.


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


## 📋 02 STORAGE
> DryRun, BTRFS, ZFS, EXT4
> Veränderungen, Automount, Benennung 

### 2.1 Storage Administration
- [ ] **Automount-Daemon** (ohne fstab, dynamisch)
- [ ] **Partitionierungs-Script** (für neue HDDs)
- [ ] **HDD-Detektor** (neue Laufwerke finden & benennen)

### 2.2 MergeFS
- [ ] **MergeFS installieren & konfigurieren**
- [ ] **MergeFS-Pool-Creation Script**
- [ ] **MergeFS-Health-Check** (fehlende Laufwerke, Fehler)

### 2.3 Parity
- [ ] **SnapRAID vorbereiten** (für Paritätsschutz)
- [ ] **SnapRAID-Assistent** (erste Einrichtung mit Größen-Validierung)
- [ ] **Automatische SnapRAID-Syncs** (Cron-Jobs)
- [ ] **SnapRAID-Recovery-Script** (bei Ausfällen)


## 📋 03 SHARES

### 3.1 Samba-Installation
- [ ] **Samba installieren & sichern**
- [ ] **Samba-Share-Creation Script** (automatisierte Freigabe-Verwaltung)
- [ ] **ACL/Permissions-Script** (Zugriffsrechte verwalten)
- [ ] **Samba-Health-Check** (Service-Status, Shares verfügbar?)
- [ ] **Backup der Samba-Konfiguration**

### 3.2 Usermanagement
- [ ] **Samba-User-Management Script** (Add/Remove/Edit ohne Systemuser)
- [ ] **User-Gruppen** für Share-Zugriffsrechte
- [ ] **Passwort-Management** (sicheres Speichern)


## 📋 04 CONTAINER

### 4.1 Podman Basis
- [ ] **Podman installieren** (für einfachere Container-Verwaltung)
- [ ] **Systemd-Service für Podman** einrichten

### 4.2 Container Management

- [ ] **Podman-Container-Verwaltung Script**
- [ ] **Podman-Network-Script** (inkl. SMB-Freigabe)
- [ ] **Podman-Volume-Script** (inkl. SMB-Freigabe)


## 📋 05 VIRTUALISIERUNG

### 5.1 KVM
- [ ] **KVM installieren** (qemu, libvirt)
- [ ] **Systemd-Service für KVM** einrichten

### 5.2 VM Management
- [ ] **VM-Creation Script** (einfache Verwaltung)

### 5.3 Spezial:  AdGuard Home + Unbound
- [ ] **VM für AdGuard/Unbound** vorbereiten
- [ ] **Auto-Deploy Script** (fertige Konfiguration)
- [ ] **Netzwerk-Integration** (DNS über NAS)



## 📋 06 UPDATES (Woche 8)

### 6.1 Backup & Recovery
- [ ] **Snapshot-System** (BTRFS basiert?)
- [ ] **(Automatische) System-Snapshots** vor Updates (max. 5 halten oder verwalten)
- [ ] **Restore-Script** (zurück zu Snapshot)
- [ ] **Restore-Validierung** (vor/nach Checks)

### 6.2 Update-Management
- [ ] **Update-Script** (apt-Updates mit Pre/Post-Hooks)
- [ ] **Service-Restart-Script** (intelligenter Neustart)
- [ ] **Update-Rollback** (bei Problemen)


## 📋 07 MONITORING

### 7.1 Monitoring & Alerting
- [ ] **Health-Check Daemon** (regelmäßige Kontrollen)
- [ ] **Fehler-Benachrichtigungen** (optional:  Email, Syslog)
- [ ] **Systemstatus-Script** (CPU, RAM, Speicher, Mountpoints, Services)
- [ ] **Logging & Systemd-Journal** konfigurieren
- [ ] **Speicher-Monitoring** (Auslastung, SMART-Daten)
- [ ] **Event-Logging** (wer hat was gemacht?)
- [ ] **Optionales:  Status-Dashboard** (wenn später GUI gewünscht)


## 📋 08 DOCUMENTATION

### 8.1 Git-Repo vorbereiten
- [ ] **Git-Struktur** aufbauen
- [ ] **README & Dokumentation**
