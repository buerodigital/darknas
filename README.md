# darknas

## 📋 01 CORE

### 1.1	Basis-Setup & Zugriff
- [ ] **Minimal Debian Net Install**
- [ ] **SSH** (Konfiguration sichern, Port, Fail2Ban vorbereiten)
- [ ] **Admin-User erstellen** mit Sudo-Rechten, alte User löschen
- [ ] **Zeitsynchronisation (NTP/Chrony)** (KRITISCH für Logs, Datenstempel, Netzwerk)
- [ ] **Hostname-Verwaltung**
- [ ] **ttyd**
- [ ] **Framework & Erweiterbarkeit**
- [ ] **TUI - Admin Tool**
- [ ] **Autostart & Cron**
- [ ] **Logs**

### 1.1 Basis-Setup & Zugriff
- [ ] **Minimal Debian Net Install** vorbereiten (automatisiert via Preseed/Cloud-init?)
- [ ] **SSH-Konfiguration sichern** (Port, Key-Auth, Fail2Ban vorbereiten)
- [ ] **Admin-User erstellen** mit Sudo-Rechten
- [ ] **Zeitsynchronisation (NTP/Chrony)** - **KRITISCH für Logs, Datenstempel, Netzwerk**
- [ ] **Hostname-Verwaltung** Script
- [ ] **Basis-Paketmanagement** Script (apt-Updates, Repository-Management)
      
### 1.2 Remote-Administration & Monitoring
- [ ] **ttyd installieren** (Web-Terminal für Admin)
- [ ] **Firewall (UFW/iptables)** mit Basis-Regeln (SSH, SMB, ttyd nur lokal)
- [ ] **Systemstatus-Script** (CPU, RAM, Speicher, Mountpoints, Services)
- [ ] **Fail2Ban einrichten** (SSH-Schutz)
- [ ] **Logging & Systemd-Journal** konfigurieren

### 1.3 Erste Admin-Tools
- [ ] **Skript-Framework** erstellen (Verzeichnisstruktur, Logging, Error-Handling)
- [ ] **Konfigurationsdatei-System** (zentrale /etc/nas/ oder ähnlich)
- [ ] **Service-Health-Check Script**

## 2.	STORAGE
DryRun, BTRFS, ZFS, EXT4
### 2.1	Datenträgerverwaltung
Veränderungen, Automount, Benennung 
### 2.2	MergeFS
### 2.3	Parität

## 3.	SHARES
### 3.1	Benutzerverwaltung
### 3.2	Samba-Installation & Freigaben

### 3.3	Firewall & Sicherheit (SMB)

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



### 1.2 Remote-Administration & Monitoring
- [ ] **ttyd installieren** (Web-Terminal für Admin)
- [ ] **Firewall (UFW/iptables)** mit Basis-Regeln (SSH, SMB, ttyd nur lokal)
- [ ] **Systemstatus-Script** (CPU, RAM, Speicher, Mountpoints, Services)
- [ ] **Fail2Ban einrichten** (SSH-Schutz)
- [ ] **Logging & Systemd-Journal** konfigurieren

### 1.3 Erste Admin-Tools
- [ ] **Skript-Framework** erstellen (Verzeichnisstruktur, Logging, Error-Handling)
- [ ] **Konfigurationsdatei-System** (zentrale /etc/nas/ oder ähnlich)
- [ ] **Service-Health-Check Script**

## 📋 PHASE 2: STORAGE & DATEN (Woche 3-4)

### 2.1 Datenträgerverwaltung
- [ ] **Automount-Daemon** (ohne fstab, dynamisch)
- [ ] **Partitionierungs-Script** (für neue HDDs)
- [ ] **HDD-Detektor** (neue Laufwerke finden & benennen)
- [ ] **Speicher-Monitoring** (Auslastung, SMART-Daten)

### 2.2 MergeFS & Shares
- [ ] **MergeFS installieren & konfigurieren**
- [ ] **Verzeichnisstruktur planen** (/mnt/disk1, /mnt/disk2, /mnt/pool, /mnt/usb...)
- [ ] **MergeFS-Pool-Creation Script**
- [ ] **MergeFS-Health-Check** (fehlende Laufwerke, Fehler)

### 2.3 Parität (Optional aber wichtig)
- [ ] **SnapRAID vorbereiten** (für Paritätsschutz)
- [ ] **SnapRAID-Assistent** (erste Einrichtung mit Größen-Validierung)
- [ ] **Automatische SnapRAID-Syncs** (Cron-Jobs)
- [ ] **SnapRAID-Recovery-Script** (bei Ausfällen)

## 📋 PHASE 3: SAMBA & BENUTZER (Woche 5)

### 3.1 Benutzerverwaltung
- [ ] **Samba-User-Management Script** (Add/Remove/Edit ohne Systemuser)
- [ ] **User-Gruppen** für Share-Zugriffsrechte
- [ ] **Passwort-Management** (sicheres Speichern)

### 3.2 Samba-Installation & Freigaben
- [ ] **Samba installieren & sichern**
- [ ] **Samba-Share-Creation Script** (automatisierte Freigabe-Verwaltung)
- [ ] **ACL/Permissions-Script** (Zugriffsrechte verwalten)
- [ ] **Samba-Health-Check** (Service-Status, Shares verfügbar?)
- [ ] **Backup der Samba-Konfiguration**

### 3.3 Firewall & Sicherheit (SMB)
- [ ] **Firewall-Regeln für SMB** (445, 139)
- [ ] **SMB-Signing & Verschlüsselung** erzwingen

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
