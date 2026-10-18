# US-SYS-004: Backups de PostgreSQL con systemd Timer

**Épica:** 11 — OS Hardening & Runtime
**Prioridad:** ALTA
**Estimación:** 5 pts
**Dependencias:** US-SYS-003
**Estado:** Pendiente

---

## Historia de Usuario

**Como** administrador del servidor,
**necesito** copias de seguridad automáticas, rotadas y restaurables de la base de datos,
**para** poder recuperar los tickets ante un fallo de disco, un error humano o una migración defectuosa.

---

## Criterios de Aceptación

> Trabajar UNO A LA VEZ, en orden. Marcar `[x]` al terminar cada uno y hacer pausa en el checkpoint final antes de cerrar la US.

- [ ] **CA-1: Script de Backup**
  - `scripts/ops/backup_postgres.sh` ejecuta `pg_dump` (formato custom) mediante `docker compose exec -T postgres`, leyendo credenciales del entorno, sin imprimirlas en logs ni pasarlas por argumentos visibles.
  - Salida en `BACKUP_DIR` (variable, fuera de `postgres_data`) con nombre fechado, modo `0600` y propietario `autoops`.
  - **Verificación:** se genera un dump válido (`pg_restore --list`).

- [ ] **CA-2: `autoops-backup.service` y `.timer`**
  - Unidades en `infra/systemd/`: servicio oneshot y timer (`OnCalendar` por variable, `Persistent=true`, `RandomizedDelaySec`).
  - **Verificación:** `systemctl list-timers` muestra el siguiente disparo y `systemctl start autoops-backup` crea un backup.

- [ ] **CA-3: Retención y Alertas de Fallo**
  - Rotación por antigüedad/cantidad (`BACKUP_RETENTION_DAYS`), eliminando solo archivos propios del patrón de nombre. Salida distinta de cero ante fallo para que systemd lo registre como `failed`.
  - **Verificación:** con retención reducida, los dumps antiguos se eliminan y los recientes se conservan.

- [ ] **CA-4: Restauración Probada y Documentada**
  - Procedimiento en `infra/backup/README.md` y script `scripts/ops/restore_postgres.sh` con confirmación explícita (operación destructiva).
  - Check `scripts/provision/checks/80_backup.sh` (timer activo, permisos del directorio).
  - **Verificación:** restaurar un dump en una base limpia y comprobar que los tickets coinciden.

---

## Notas Técnicas

- **Fuera de alcance:** backups remotos/S3, cifrado de los dumps, PITR/WAL archiving.
- **Disco:** dimensionar `BACKUP_DIR` y documentar la ubicación recomendada (volumen separado en EC2).
