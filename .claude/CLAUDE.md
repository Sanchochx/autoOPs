# 🚀 AutoOps - Plataforma SRE Multi-Agente Autohospedada

## Descripción
**AutoOps** es un sistema de soporte técnico autónomo (Tier-1) diseñado para empresas. Está estructurado en microservicios y orquestado mediante agentes de IA con LangGraph. El sistema recibe y clasifica tickets de incidentes, investiga la causa raíz consultando infraestructura, logs y bases de datos a través de servidores aislados con Model Context Protocol (MCP), y propone planes de remediación automáticos o supervisados mediante confirmación humana (Human-in-the-Loop).

---

## Stack Tecnológico

### Backend & API Gateway
- **Framework:** Python 3.11+ / FastAPI
- **Comunicación:** WebSockets (streaming en tiempo real del razonamiento de los agentes) y REST (operaciones CRUD, tickets y autenticación)
- **Validación de Datos:** Pydantic (tipado estricto)

### Motor de IA & Herramientas
- **Orquestación de Agentes:** Python / LangGraph + LangChain
- **Aislamiento de Herramientas:** Model Context Protocol (MCP SDK)
- **Agentes:**
  1. *Triaje:* Clasificación de severidad y enrutamiento del ticket.
  2. *Investigador:* Inspección de logs y métricas vía herramientas MCP.
  3. *Ejecutor:* Generación de planes de mitigación y gestión de aprobaciones HITL.

### Base de Datos & Persistencia
- **Base de Datos:** PostgreSQL
- **ORM / Migraciones:** SQLAlchemy / Alembic

### Frontend
- **Framework:** React + Vite + TypeScript
- **Estilos:** TailwindCSS
- **Manejo de Estado:** Zustand / React Context (WebSockets y estado de UI)

### Infraestructura & DevOps
- **Contenedores:** Docker & Docker Compose
- **Reverse Proxy:** Traefik / Nginx con terminación SSL (Let's Encrypt)
- **SO de Despliegue:** Ubuntu Server (AWS EC2 / VM Local en VirtualBox)
- **CI/CD:** GitHub Actions (Despliegue automático por SSH)

---

## Comandos Clave

### Backend & Motor de IA (Python / FastAPI)
```bash
# Activar entorno virtual
source venv/bin/activate        # Linux/Mac
venv\Scripts\activate           # Windows

# Instalar dependencias
pip install -r requirements.txt

# Ejecutar API Gateway en desarrollo
uvicorn apps.api_gateway.main:app --reload --port 8000

# Ejecutar pruebas unitarias e integración
pytest tests/ -v
pytest tests/ -v --cov=services

Frontend (React / Vite)

# Cambiar al directorio del frontend
cd apps/frontend

# Instalar dependencias
npm install

# Correr en desarrollo
npm run dev

# Compilar para producción
npm run build

Orquestación Docker (Fase 2+)

# Levantar todos los servicios en segundo plano
docker compose up -d --build

# Monitorear logs unificados
docker compose logs -f

# Detener el ecosistema de contenedores
docker compose down

Estructura del Monorepo

autoops/
├── apps/
│   ├── frontend/             # React + Vite + TypeScript + TailwindCSS (Dashboard Admin)
│   └── api_gateway/          # FastAPI (REST, WebSockets, Auth) — guion bajo para imports de Python
├── services/
│   ├── ai-engine/            # LangGraph (Agentes de Triaje, Investigador y Ejecutor)
│   └── mcp-servers/          # Servidores MCP (Aislamiento de BD, logs y métricas)
├── .claude/
│   ├── CLAUDE.md             # Este archivo (Guía de arquitectura y estándares)
│   └── context/              # Documentación y seguimiento SDD
│       ├── user_stories/         # Historias de usuario ordenadas por épica
│       ├── summaries/            # Resúmenes ejecutivos al finalizar cada fase
│       ├── IMPLEMENTATION_PLAN.md# Plan maestro de historias de usuario y progreso
│       └── TASK_EXECUTION.md     # Manual de instrucciones para Claude Code
├── .env.example              # Plantilla centralizada de variables de entorno
└── docker-compose.yml        # Orquestación de contenedores y redes privadas (Fase 2)

Convenciones de Código
Nombres

-Python: snake_case para funciones, métodos, variables y archivos (ticket_service.py).

-TypeScript / React: camelCase para variables y funciones; PascalCase para Componentes e Interfaces (TicketCard.tsx).

-Clases: PascalCase en ambos lenguajes.

-Constantes: UPPER_SNAKE_CASE.

-Rutas de API REST: /kebab-case (ej. /api/v1/tickets/active-alerts).

Ramas

    main → Producción / Código listo para despliegue en servidor

    develop → Integración de características

    feature/nombre-descriptivo

    fix/nombre-del-bug
    
Reglas Importantes y Principios DevOps

    The Twelve-Factor App (Cero Hardcoding):

        NUNCA escribir credenciales, claves de API, URLs o puertos directamente en el código.

        Todo parámetro configurable se lee desde variables de entorno (.env).

    Aislamiento Estricto mediante MCP (Sandboxing):

        El motor de IA (LangGraph) NUNCA se conecta directamente a PostgreSQL ni ejecuta comandos del sistema operativo.

        Toda interacción con la infraestructura debe realizarse a través de los servidores MCP autorizados.

    Estrategia de Logging Cloud-Native:

        Todos los microservicios deben emitir sus logs a stdout y stderr.

        No usar librerías que escriban o roten archivos de texto locales dentro de la aplicación.

    Operación mediante Spec-Driven Development (SDD):

        Claude Code debe acatarse estrictamente al flujo descrito en @context/TASK_EXECUTION.md.

        Desarrollar los Criterios de Aceptación UNO A LA VEZ.

        Hacer pausa obligatoria en los Checkpoints antes de marcar la Historia de Usuario como completada.
        

Variables de Entorno Necesarias (.env)

# Servidor & Gateway
PORT=8000
DEBUG=True
ENVIRONMENT=development
SECRET_KEY=clave_secreta_jwt_autoops

# Base de Datos PostgreSQL
DB_HOST=localhost
DB_PORT=5432
DB_NAME=autoops_db
DB_USER=autoops_user
DB_PASSWORD=autoops_password

# Modelos de IA & Telemetría
OPENAI_API_KEY=tu_clave_openai
ANTHROPIC_API_KEY=tu_clave_anthropic
LANGCHAIN_TRACING_V2=true
LANGCHAIN_API_KEY=tu_clave_langsmith

# Servidores MCP
MCP_LOGS_SERVER_URL=http://localhost:5001
MCP_DB_SERVER_URL=http://localhost:5002

# Frontend (Vite)
VITE_API_BASE_URL=http://localhost:8000
VITE_WS_BASE_URL=ws://localhost:8000/ws

stándares de Frontend
Filosofía

Cada UI debe ser de nivel producción: accesible, performante, mantenible e intencional. El código debe poder superar una revisión de código estricta.
Arquitectura de Componentes

    Separación de responsabilidades: La lógica de negocio vive fuera del componente de UI.

        Custom Hooks para lógica y llamadas HTTP/WebSocket; componentes dedicados únicamente al renderizado.

    Componentes pequeños y enfocados: Máximo ~150 líneas por archivo, una sola responsabilidad.

    Tipado estricto: TypeScript en modo strict, sin uso de any.

    Estructura basada en features:
    feature/
  ├── components/     ← UI puro (sin llamadas a API)
  ├── services/       ← cliente HTTP y WebSockets
  ├── models/         ← interfaces y tipos
  ├── hooks/          ← estado y lógica de negocio
  └── index.ts        ← barrel export
  
 TypeScript

    strict: true activado en tsconfig.json.

    Interfaces para objetos del dominio (Ticket, AgentState), types para uniones y utilidades.

    Usar unknown + type guards en lugar de any.

    Tipar explícitamente los retornos de funciones y manejadores de eventos.

Estilos y Diseño

    Usar clases de TailwindCSS manteniendo coherencia con el diseño del panel de control.

    Layouts dinámicos con CSS Grid para las vistas principales del dashboard y Flexbox para componentes lineales.

    Enfoque Mobile-First mediante puntos de interrupción de Tailwind (md:, lg:).

Accesibilidad (a11y) — No negociable

    Elementos interactivos operables mediante teclado (Tab, Enter, Space).

    <label> explícito para todos los campos de entrada de datos.

    Relación de contraste de color alineada a norma WCAG AA (4.5:1 para texto normal).

    Atributos y roles ARIA para modales de aprobación HITL y tablas dinámicas de tickets.

    Estilos visuales claros para :focus-visible.

Rendimiento

    Carga diferida de vistas secundarias mediante React.lazy y Suspense.

    Optimización de re-renders en componentes vinculados al streaming de WebSockets.

    Manejo de estado predecible e inmutable usando Zustand.
  
 
