#!/usr/bin/env bash
# Comando forzado (`command=`) de la llave de despliegue. Se instala en
# /usr/local/sbin/autoops-deploy-entrypoint (root:root 755).
# La llave solo puede pedir acciones de la lista blanca; cualquier otra se rechaza.
# La acción `deploy` es un marcador: el despliegue real se implementa en la Fase 5.
set -euo pipefail

action="${SSH_ORIGINAL_COMMAND:-}"
logger -t autoops-deploy "solicitud de despliegue: '${action}' desde ${SSH_CONNECTION%% *}"

case "$action" in
  deploy)
    echo "autoops-deploy: acción 'deploy' aceptada; despliegue no implementado (Fase 5)."
    ;;
  *)
    echo "autoops-deploy: acción no permitida." >&2
    exit 1
    ;;
esac
