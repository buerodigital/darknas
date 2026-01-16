
|Zweck|Pfad  |Warum|Berechtigungen   |Kurzbewertung   |
|-----|-----|-----|-----|-----|
|Konfiguration   |/etc/darknas   |Systemkonfigs gehören nach /etc   |root:root 644   |Standard, leicht editierbar   |
|Binärskripte   |/usr/local/bin/darknas   |Systemweite ausführbare Tools   |root:root 755   |Einfach im PATH   |
|Module   |/opt/darknas/modules   |große modulare Komponenten   |root:root 755   |Sauber, isoliert  |
|Logs   |/var/log/darknas   |rotierbare Logs   |root:adm 640   |kompatibel mit logrotate   |
|Daten Mounts   |/mnt/pool   |MergerFS/SnapRAID Mountpoints   |root:root 755   |klar trennbar   |
