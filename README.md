# darknas

## 📋 01 CORE

### 1.1 Basic Setup
- [ ] **Minimal Debian Net Install** vorbereiten (Hostname!)
- [ ] **SSH-Konfiguration sichern** (Port, Key-Auth, Fail2Ban vorbereiten)
- [ ] **Alte User löschen** (UID >= 1000)
- [ ] **Admin-User erstellen** mit Sudo-Rechten
- [ ] **Zeitsynchronisation (Chrony)** - **KRITISCH für Logs, Datenstempel, Netzwerk**
- [ ] **Verzeichnisstruktur planen** (/mnt/disk1, /mnt/disk2, /mnt/pool, /mnt/usb...)
      
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
DryRun, BTRFS, ZFS, EXT4
Veränderungen, Automount, Benennung 

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


## 📋 03: SHARES

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







Reste:
1 - Core
2 - Storage
3 - Shares
4 - Container
5 - Virtualisation
6 - Updates
7 - Monitoring
- [ ] **Service-Health-Check Script**
- [ ] **Systemstatus-Script** (CPU, RAM, Speicher, Mountpoints, Services)
- [ ] **Logging & Systemd-Journal** konfigurieren
- [ ] **Speicher-Monitoring** (Auslastung, SMART-Daten)



## 4.	CONTAINER
### 4.1	Podman Basis
### 4.2	Container Management

## 5.	Container & Virtualisierung
### 5.1 KVM Basis
### 5.2	VM Management
### 5.3	Spezial: AdGuard Home + Unbound

## 6. UPDATES
### 6.1	Backup & Recovery
### 6.2	Update-Management
### 6.3	Systemstatus & Reporting

## 7.	REPORTING
### 7.1	Monitoring & Alerting






## 📋 PHASE 4: VIRTUALISIERUNG (Woche 6-7)

### 4.1 KVM & Podman Basis
- [ ] **KVM installieren** (qemu, libvirt)
- [ ] **Podman installieren** (für einfachere Container-Verwaltung)
- [ ] **Systemd-Service für Podman** einrichten

### 4.2 VM & Container Management
- [ ] **VM-Creation Script** (einfache Verwaltung)
- [ ] **Podman-Container-Verwaltung Script**
- [ ] **Podman-Volume-Script** (inkl. SMB-Freigabe)

### 4.3 Spezial:  AdGuard Home + Unbound
- [ ] **VM für AdGuard/Unbound** vorbereiten
- [ ] **Auto-Deploy Script** (fertige Konfiguration)
- [ ] **Netzwerk-Integration** (DNS über NAS)

## 📋 PHASE 5: WARTUNG & UPDATES (Woche 8)

### 5.1 Backup & Recovery
- [ ] **Snapshot-System** (BTRFS oder LVM-basiert?)
- [ ] **Automatische System-Snapshots** vor Updates (max. 5 halten)
- [ ] **Restore-Script** (zurück zu Snapshot)
- [ ] **Restore-Validierung** (vor/nach Checks)

### 5.2 Update-Management
- [ ] **Update-Script** (apt-Updates mit Pre/Post-Hooks)
- [ ] **Service-Restart-Script** (intelligenter Neustart)
- [ ] **Update-Rollback** (bei Problemen)

### 5.3 Systemstatus & Reporting
- [ ] **Erweiterte Status-Scripts** (alle Komponenten)
- [ ] **Event-Logging** (wer hat was gemacht?)
- [ ] **Optionales:  Status-Dashboard** (wenn später GUI gewünscht)

## 📋 PHASE 6: AUTOMATISIERUNG & SCHEDULING (Woche 9)

### 6.1 Autostart & Cron
- [ ] **Systemd-Unit-Generator Script** (Services autostart)
- [ ] **Cron-Job-Manager Script** (regelmäßige Tasks)
- [ ] **Task-Dependency-System** (welche Jobs hängen zusammen?)

### 6.2 Monitoring & Alerting
- [ ] **Health-Check Daemon** (regelmäßige Kontrollen)
- [ ] **Fehler-Benachrichtigungen** (optional:  Email, Syslog)

## 📋 PHASE 7: POLISHING & DOKUMENTATION (Woche 10)

### 7.1 Framework & Erweiterbarkeit
- [ ] **Standardisiertes Skript-Template** (für Dritte)
- [ ] **Plugin-System** (neue Features hinzufügbar)
- [ ] **Konfigurationsformat standardisieren** (YAML/JSON)

### 7.2 Benutzertauglichkeit
- [ ] **Menü-System** (interaktive Admin-CLI)
- [ ] **Fehlerbehandlung & User-Feedback**
- [ ] **Logging & Debugging** standardisieren

### 7.3 Git-Repo vorbereiten
- [ ] **Git-Struktur** aufbauen
- [ ] **README & Dokumentation**
- [ ] **Beispiel-Konfigurationen**
- [ ] **Erste Release vorbereiten**<img width="1358" height="2216" alt="grafik" src="https://github.com/user-attachments/assets/67dba419-8f60-4313-a946-ecb2537a15b1" />
