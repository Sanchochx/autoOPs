# Arquitectura del Proyecto

## Visión general
[Descripción de alto nivel de cómo está organizado el sistema]

## Diagrama de componentes
```
[Cliente / Frontend]
        |
        ▼
[API REST / Flask o Express]
        |
   ┌────┴────┐
   ▼         ▼
[Servicios] [Auth]
   |
   ▼
[Base de datos / PostgreSQL o MySQL]
```

## Decisiones de diseño

### Por qué [tecnología X]
[Razón]

### Estructura de capas
- **Rutas/Controladores** — reciben la request, validan formato básico, llaman al servicio
- **Servicios** — contienen la lógica de negocio, no saben nada de HTTP
- **Modelos** — representan las entidades de la DB, tienen métodos de serialización
- **Utils** — helpers reutilizables sin estado

## Flujo de una request típica
1. Cliente hace `POST /api/recurso`
2. Ruta valida que el body tenga los campos requeridos
3. Ruta llama a `servicio.crear(data)`
4. Servicio ejecuta la lógica, persiste en DB
5. Servicio retorna un dict limpio (sin objetos ORM)
6. Ruta retorna `jsonify(resultado), 201`

## Módulos principales
| Módulo | Descripción | Archivos clave |
|--------|-------------|----------------|
| [Módulo 1] | [Qué hace] | [Archivos] |
| [Módulo 2] | [Qué hace] | [Archivos] |

## Consideraciones de seguridad
- Autenticación: [JWT / Sessions / etc.]
- Autorización: [cómo se controlan los permisos]
- Validación: [dónde y cómo se validan los inputs]
