import { Terminal, Trash2 } from 'lucide-react'
import { useAutoScroll } from '../hooks/useAutoScroll'
import type { ConnectionStatus } from '../models/agentMessage'
import { useAiStore } from '../store/useAiStore'

const STATUS_LABEL: Record<ConnectionStatus, string> = {
  connecting: 'Conectando…',
  open: 'Conectado',
  closed: 'Desconectado',
}

const STATUS_COLOR: Record<ConnectionStatus, string> = {
  connecting: 'text-amber-300',
  open: 'text-emerald-300',
  closed: 'text-red-300',
}

interface AgentConsoleProps {
  status: ConnectionStatus
}

export function AgentConsole({ status }: AgentConsoleProps): React.JSX.Element {
  const logs = useAiStore((state) => state.logs)
  const clearLogs = useAiStore((state) => state.clearLogs)
  const scrollRef = useAutoScroll(logs)

  return (
    <section
      aria-labelledby="agent-console-title"
      className="flex h-full min-h-[60vh] flex-col overflow-hidden rounded-lg bg-slate-950 text-slate-100"
    >
      <header className="flex items-center justify-between border-b border-slate-800 px-4 py-2">
        <h2 id="agent-console-title" className="flex items-center gap-2 text-sm font-semibold">
          <Terminal aria-hidden="true" className="size-4" />
          Consola del agente
        </h2>
        <div className="flex items-center gap-3 text-xs">
          <span className={STATUS_COLOR[status]}>{STATUS_LABEL[status]}</span>
          <button
            type="button"
            onClick={clearLogs}
            className="flex items-center gap-1 rounded px-2 py-1 text-slate-300 hover:bg-slate-800 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-sky-400"
          >
            <Trash2 aria-hidden="true" className="size-3.5" />
            Limpiar
          </button>
        </div>
      </header>
      <div
        ref={scrollRef}
        role="log"
        aria-live="polite"
        aria-label="Mensajes del motor de IA"
        tabIndex={0}
        className="flex-1 overflow-y-auto p-4 font-mono text-sm focus-visible:outline-2 focus-visible:outline-sky-400"
      >
        {logs.length === 0 ? (
          <p className="text-slate-400">Esperando mensajes del motor de IA…</p>
        ) : (
          logs.map((log) => (
            <p key={log.id} className="whitespace-pre-wrap break-words">
              <span className="text-slate-500">
                {new Date(log.receivedAt).toLocaleTimeString()}{' '}
              </span>
              {log.text}
            </p>
          ))
        )}
      </div>
    </section>
  )
}
