# AutoOps

Plataforma SRE multi-agente autohospedada. Es un sistema de soporte técnico autónomo (Tier-1) que recibe y clasifica tickets de incidentes, investiga la causa raíz consultando logs, métricas y bases de datos a través de servidores aislados con Model Context Protocol (MCP), y propone planes de remediación automáticos o supervisados mediante confirmación humana (Human-in-the-Loop, HITL).

Tres agentes orquestados con LangGraph:

1. **Triaje:** clasifica la severidad y enruta el ticket.
2. **Investigador:** inspecciona logs y métricas vía herramientas MCP.
3. **Ejecutor:** genera planes de mitigación y gestiona las aprobaciones HITL.

## Stack tecnológico

| Capa | Tecnología |
|------|------------|
| Backend / API Gateway | Python 3.11+, FastAPI, Pydantic, WebSockets + REST |
| Motor de IA | LangGraph + LangChain, MCP SDK |
| Persistencia | PostgreSQL, SQLAlchemy, Alembic |
| Frontend | React + Vite + TypeScript, TailwindCSS, Zustand |
| Infraestructura (Fase 2) | Docker Compose, Traefik/Nginx + Let's Encrypt, GitHub Actions |

## Estructura del monorepo

```
autoops/
├── apps/
│   ├── frontend/        # Dashboard Admin (React + Vite + TypeScript + TailwindCSS)
│   └── api_gateway/     # FastAPI: REST, WebSockets y autenticación
├── services/
│   ├── ai-engine/       # Agentes LangGraph (Triaje, Investigador, Ejecutor)
│   └── mcp-servers/     # Servidores MCP (aislamiento de BD, logs y métricas)
├── .claude/
│   ├── CLAUDE.md        # Arquitectura y estándares del proyecto
│   └── context/         # Documentación SDD (plan, historias de usuario, resúmenes)
├── .env.example         # Plantilla centralizada de variables de entorno
├── .gitignore
└── README.md
```

## Prerrequisitos

- Python 3.11+
- Node.js (LTS) y npm
- PostgreSQL
- Docker y Docker Compose (solo a partir de la Fase 2)

## Primeros pasos

```bash
git clone <url-del-repositorio> autoops
cd autoops
cp .env.example .env    # y edita los valores
```

Los comandos de ejecución estarán disponibles tras las US correspondientes:

- **Backend / API Gateway:** disponible tras US-GW-001.
- **Frontend:** disponible tras US-FE-001.
- **Contenedores:** disponible en la Fase 2.

### Migraciones de base de datos (Alembic, desde la raíz del monorepo)

```bash
alembic -c apps/api_gateway/alembic.ini upgrade head     # aplicar migraciones
alembic -c apps/api_gateway/alembic.ini current          # revisión actual
alembic -c apps/api_gateway/alembic.ini revision --autogenerate -m "descripcion"
```

Requiere `DATABASE_URL` (`postgresql+asyncpg://...`) en `.env`.

Los comandos definitivos se documentan en [`.claude/CLAUDE.md`](.claude/CLAUDE.md#comandos-clave).

## Principios clave

- **Twelve-Factor (cero hardcoding):** credenciales, claves, URLs y puertos se leen siempre de variables de entorno (`.env`).
- **Aislamiento vía MCP:** el motor de IA nunca se conecta directamente a PostgreSQL ni ejecuta comandos del sistema; toda interacción con la infraestructura pasa por servidores MCP autorizados.
- **Logging cloud-native:** todos los servicios emiten logs a stdout/stderr; no se escriben ni rotan archivos locales.

## Flujo de trabajo (SDD)

El proyecto sigue Spec-Driven Development: una historia de usuario a la vez, criterios de aceptación uno a uno y checkpoint obligatorio antes de avanzar.

- [Plan de implementación](.claude/context/IMPLEMENTATION_PLAN.md)
- [Flujo de ejecución de tareas](.claude/context/TASK_EXECUTION.md)
- [Guía de arquitectura y estándares](.claude/CLAUDE.md)

### Ramas

| Rama | Propósito |
|------|-----------|
| `main` | Producción / código listo para despliegue |
| `develop` | Integración de características |
| `feature/nombre-descriptivo` | Nuevas funcionalidades |
| `fix/nombre-del-bug` | Corrección de errores |


+============================================================================+
   _____                  __               ____           
  / ___/____ _____  _____/ /_  ____       / __ \___ _   __
  \__ \/ __ `/ __ \/ ___/ __ \/ __ \     / / / / _ \ | / /
 ___/ / /_/ / / / / /__/ / / / /_/ /    / /_/ /  __/ |/ / 
/____/\__,_/_/ /_/\___/_/ /_/\____/____/_____/\___/|___/  
                                 /_____/                  

               .-"""-.
             _/-=-.   \
            (_|a a/   |_
             / "  \   ,_)
        _    \`=' /__/
       / \_  .;--'  `-.
       \___)//      ,  \
        \ \/;        \  \
         \_.|         | |
          .-\ '     _/_/
        .'  _;.    (_  \
       /  .'   `\   \\_/
      |_ /       |  |\\
     /  _)       /  / ||
    /  /       _/  /  //
    \_/       ( `-/  ||
              /  /   \\ .-.
              \_/     \'-'/
                       `"`
+============================================================================+
> _
