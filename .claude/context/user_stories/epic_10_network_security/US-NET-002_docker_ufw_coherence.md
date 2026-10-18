# US-NET-002: Coherencia Docker ↔ UFW

**Épica:** 10 — Network Security
**Prioridad:** CRÍTICA
**Estimación:** 5 pts
**Dependencias:** US-NET-001, US-SYS-002
**Estado:** Pendiente

---

## Historia de Usuario

**Como** administrador del servidor,
**necesito** que los puertos publicados por Docker respeten las reglas del firewall del host,
**para** que ningún contenedor quede expuesto a Internet por un `ports:` olvidado, aunque UFW lo niegue.

---

## Criterios de Aceptación

> Trabajar UNO A LA VEZ, en orden. Marcar `[x]` al terminar cada uno y hacer pausa en el checkpoint final antes de cerrar la US.

- [ ] **CA-1: Reproducir y Documentar la Fuga**
  - Con Docker y UFW activos y el stack levantado, demostrar desde otra máquina (o desde el host de VirtualBox) que `PORT` y `FRONTEND_PORT` son alcanzables aunque UFW no los permita.
  - Documentar la causa (Docker inserta sus reglas NAT/FORWARD antes de las de UFW) en `infra/firewall/README.md`.
  - **Verificación:** captura del comando y resultado (`nmap`/`curl`) que muestra la exposición.

- [ ] **CA-2: Filtrado en la Cadena `DOCKER-USER`**
  - Bloque gestionado en `/etc/ufw/after.rules` (plantilla en `infra/firewall/`, aplicado por `scripts/provision/45_docker_ufw.sh`) que, en `DOCKER-USER`, descarta el tráfico entrante desde la interfaz externa hacia contenedores salvo los puertos permitidos (80/443 y los que se decidan), sin romper el tráfico entre contenedores ni el de retorno (`ESTABLISHED,RELATED`).
  - Mantener `iptables` gestionado por Docker (no se desactiva `"iptables": false`) para no romper las redes `internal` del compose.
  - **Verificación:** tras recargar UFW y reiniciar Docker, los puertos no autorizados quedan inaccesibles desde fuera y siguen funcionando desde el propio host.

- [ ] **CA-3: Decisión Explícita sobre Gateway y Frontend**
  - Documentar y aplicar qué puertos quedan públicos hasta la Fase 5: recomendado, el frontend por `FRONTEND_PORT` provisional y el Gateway solo en loopback o detrás del proxy. Cualquier cambio en `docker-compose.yml` (p. ej. binding a `127.0.0.1`) se parametriza por variable y se anota en `.env.example`.
  - **Verificación:** el flujo end-to-end (crear ticket → streaming WebSocket) sigue funcionando desde el navegador usando solo los puertos permitidos.

- [ ] **CA-4: Escaneo Externo y Check**
  - Check `scripts/provision/checks/45_docker_ufw.sh` (reglas de `DOCKER-USER` presentes y persistentes tras reinicio) y procedimiento de escaneo `nmap` externo documentado.
  - **Verificación:** el escaneo solo muestra SSH, 80 y 443 (y lo definido en CA-3); el resultado se adjunta a la documentación.

---

## Notas Técnicas

- **Orden:** requiere Docker instalado (US-SYS-002) y UFW activo (US-NET-001).
- **Redes `internal`:** `backend_net` y `mcp_net` no deben verse afectadas; verificar con el stack saludable tras el cambio.
- **Fuera de alcance:** reverse proxy, TLS (Fase 5), IPv6 avanzado.
