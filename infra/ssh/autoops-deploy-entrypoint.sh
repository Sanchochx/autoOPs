#!/usr/bin/env bash
# Forced command (`command=`) of the deploy key. Installed at
# /usr/local/sbin/autoops-deploy-entrypoint (root:root 755).
# The key can only request allowlisted actions; any other is rejected.
# The `deploy` action is a placeholder: the real deployment is implemented in Phase 5.
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
