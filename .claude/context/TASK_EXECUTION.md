# 📋 FLUJO DE EJECUCIÓN DE TAREAS

**Proyecto:** AutoOps — Plataforma SRE Multi-Agente Autohospedada

**Versión:** 2.0
**Última actualización:** 2026-10-15

---

## 📁 Archivos de Contexto

Antes de comenzar cualquier tarea, revisar estos archivos:

- **`@context/IMPLEMENTATION_PLAN.md`** — Plan maestro con historias de usuario (US) y progreso por fases
- **`@CLAUDE.md`** — Detalles del proyecto, stack tecnológico y estándares de código

> En todo este documento, "el plan" = `@context/IMPLEMENTATION_PLAN.md`.

### Mapa de directorios (según `CLAUDE.md`)

| Ruta | Contenido |
|------|-----------|
| `apps/frontend/` | React + Vite + TypeScript + TailwindCSS (Dashboard Admin) |
| `apps/api_gateway/` | FastAPI (REST, WebSockets, Auth) |
| `services/ai-engine/` | LangGraph (agentes de Triaje, Investigador y Ejecutor) |
| `services/mcp-servers/` | Servidores MCP (aislamiento de BD, logs y métricas) |
| `context/user_stories/epic_NN_slug/` | Historias de usuario por épica |
| `context/summaries/` | Resúmenes de fase |

> Las rutas `context/...` de este documento y del plan son relativas a `.claude/` (es decir, `.claude/context/...`).

Los archivos de cada US deben crearse **solo** dentro del directorio que corresponda a su épica.

---

## 🔄 Proceso de Ejecución

### 1. Encontrar la siguiente US

- Si hay una US marcada `[~]` en el plan, **retómala primero**.
- Si no hay ninguna, toma la **primera US `[ ]`** del plan y márcala `[~]` antes de empezar (solo UNA `[~]` a la vez).
- Lee el archivo completo de la US: TODOS los criterios de aceptación y el campo **Dependencias** (si existe).
- Si una dependencia no está `[x]`, avisa al usuario antes de continuar.

```markdown
[~] US-MONO-001: Monorepo Setup
```

Prefijos de ID: `MONO` (Epic 01), `GATE` (Epic 02), `MCP` (Epic 03), `AI` (Epic 04), `FE` (Epic 05).
Si la US está marcada *(por redactar)* en el plan, redáctala primero en su carpeta de épica y pide validación al usuario antes de implementarla.

---

### 2. Implementar cada criterio de aceptación

**Regla de oro:** trabaja los criterios **UNO A LA VEZ**.

Para cada criterio:

1. **Explica qué vas a construir y por qué** (objetivo y relación con la arquitectura).
2. **Crea/modifica archivos** en los directorios definidos en `CLAUDE.md`, respetando la estructura existente.
3. **Aplica estándares y convenciones** de `CLAUDE.md`, manteniendo consistencia con el código existente.
4. **Actualiza la documentación afectada** (forma parte del alcance de la US).
5. **Marca el criterio `[x]`** en el archivo de la US al terminar.

```markdown
## Criterios de Aceptación

- [x] [Criterio completado]
- [ ] [Criterio pendiente]
```

---

### 3. Cerrar la US

Cuando TODOS los criterios estén `[x]`:

1. Recorre el **Checklist de Verificación** (al final de este documento).
2. En el plan: marca la US `[x]` (reemplaza `[~]`).
3. Actualiza el dashboard (contadores) y las barras de progreso de **épica** y **fase**.

```markdown
[x] US-MONO-001: Monorepo Setup
```

---

### 4. Checkpoint (obligatorio)

Muestra un resumen y **detente a esperar confirmación**:

```
✅ US-MONO-001 Completada

Archivos creados/modificados:
- [ruta/archivo] - [propósito]

Funcionalidades:
- [Funcionalidad implementada]

Decisiones técnicas:
- [Decisión y motivo]

¿Proceder con US-MONO-002?
```

- No avances a la siguiente US sin aprobación explícita del usuario.
- No hagas nada fuera de este flujo mientras esperas.

---

### 5. Resumen de fase (solo si corresponde)

**Cuándo:** al completar TODAS las US de una **fase** (después del checkpoint de la última US).

**Dónde y nombre:** `context/summaries/phase-[N]-resume.md`

**Contenido:**

- **📝 Changes Made:** módulos, funcionalidades core e integraciones de la fase.
- **📂 Files Modified/Created:** ruta, propósito y cambios principales de cada archivo.
- **🎯 Rationale:** qué se completó y por qué, cómo encaja en la arquitectura, decisiones de diseño y patrones usados.
- **🚀 Next Steps:** fase siguiente, dependencias y consideraciones.

**Propósito:** que futuras sesiones de LLM entiendan el estado del proyecto sin releer todo el código.

---

## ⚠️ Guías Importantes

- **Arquitectura:** sigue `CLAUDE.md` (arquitectura, estándares, organización de archivos, nombres).
- **Cero hardcoding (Twelve-Factor):** nunca escribas credenciales, claves de API, URLs ni puertos en el código; todo se lee de variables de entorno y se documenta en `.env.example`.
- **Aislamiento MCP:** el motor de IA (`services/ai-engine/`) NUNCA se conecta directo a PostgreSQL ni ejecuta comandos del SO; toda interacción con la infraestructura pasa por los servidores de `services/mcp-servers/`.
- **Logging cloud-native:** todos los servicios emiten logs a stdout/stderr; sin librerías que escriban o roten archivos locales.
- **Frontend:** TypeScript `strict` sin `any`, estructura por features (`components/`, `services/`, `models/`, `hooks/`, `index.ts`), máx. ~150 líneas por archivo, TailwindCSS mobile-first y accesibilidad WCAG AA (ver sección "Estándares de Frontend" de `CLAUDE.md`).
- **Convenciones de nombres:** Python `snake_case`; TS/React `camelCase` y `PascalCase` para componentes/interfaces; constantes `UPPER_SNAKE_CASE`; rutas REST en `/kebab-case`.
- **Ramas:** `main` (producción), `develop` (integración), `feature/nombre-descriptivo`, `fix/nombre-del-bug`.
- **Trabajo incremental:** un criterio a la vez; una US a la vez.
- **Commits:** no hagas commits a menos que el usuario lo pida. Si lo pide, que sean pequeños y atómicos (uno por criterio).
- **Testing:** solo implementación. No escribas tests salvo que la US los exija en sus criterios.
- **Dudas:** si un criterio es ambiguo o choca con la arquitectura existente, pregunta antes de implementar.
- **Alcance:** no modifiques archivos fuera del alcance de la US actual.

---

## 🎯 Buenas Prácticas

### ✅ HACER
- Leer toda la US antes de comenzar
- Seguir el orden del plan
- Marcar el progreso en tiempo real
- Explicar decisiones técnicas

### ❌ NO HACER
- Saltarte US
- Trabajar en varias US a la vez
- Asumir implementaciones sin revisar criterios
- Avanzar sin autorización del usuario

---

## 🔍 Checklist de Verificación

Antes de marcar una US como completa:

- [ ] Todos los criterios de aceptación están `[x]`
- [ ] Los archivos están en los directorios correctos
- [ ] El código sigue los estándares de `CLAUDE.md`
- [ ] Sin credenciales, URLs ni puertos hardcodeados; variables nuevas añadidas a `.env.example`
- [ ] Sin acceso directo a PostgreSQL/SO desde `services/ai-engine/` (solo vía MCP)
- [ ] Logs a stdout/stderr, sin archivos locales
- [ ] (Frontend) TypeScript strict sin `any`, a11y y `:focus-visible` verificados
- [ ] La documentación está actualizada
- [ ] No hay código comentado sin razón
- [ ] Las funcionalidades cumplen los criterios

---

## 📌 Referencia Rápida

| Archivo | Propósito |
|---------|-----------|
| `@context/IMPLEMENTATION_PLAN.md` | Plan maestro con todas las US y progreso |
| `@CLAUDE.md` | Detalles técnicos y estándares del proyecto |
| `context/user_stories/` | Archivos individuales de historias de usuario (una carpeta por épica) |
| `context/summaries/` | Resúmenes de fase (`phase-[N]-resume.md`) |
| `.env.example` | Plantilla centralizada de variables de entorno |
| `docker-compose.yml` | Orquestación de contenedores (Fase 2) |

---

**Importante:** flujo diseñado para trabajo incremental y colaborativo. Siempre espera confirmación del usuario antes de pasar a la siguiente US.