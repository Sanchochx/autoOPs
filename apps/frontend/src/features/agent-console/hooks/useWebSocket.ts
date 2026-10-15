import { useEffect, useState } from 'react'
import type { ConnectionStatus } from '../models/agentMessage'
import { parsePayload } from '../services/parsePayload'
import { openReconnectingSocket } from '../services/reconnectingSocket'
import { useAiStore } from '../store/useAiStore'

/** Ruta del canal de streaming relativa a VITE_WS_BASE_URL. */
const STREAM_PATH = '/stream'

/** Conecta al stream del Gateway y despacha los mensajes al store. */
export function useWebSocket(): ConnectionStatus {
  const addLog = useAiStore((state) => state.addLog)
  const baseUrl = import.meta.env.VITE_WS_BASE_URL
  const [status, setStatus] = useState<ConnectionStatus>(baseUrl ? 'connecting' : 'closed')

  useEffect(() => {
    if (!baseUrl) return undefined
    return openReconnectingSocket({
      url: `${baseUrl}${STREAM_PATH}`,
      onMessage: (data) => addLog(parsePayload(data)),
      onStatusChange: setStatus,
    })
  }, [addLog, baseUrl])

  return status
}
