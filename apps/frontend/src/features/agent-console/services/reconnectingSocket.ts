import type { ConnectionStatus } from '../models/agentMessage'

const INITIAL_DELAY_MS = 1_000
const MAX_DELAY_MS = 30_000

interface SocketOptions {
  url: string
  onMessage: (data: string) => void
  onStatusChange: (status: ConnectionStatus) => void
}

/**
 * Opens a WebSocket and reconnects it with growing (capped) backoff if it drops.
 * Returns a function that closes the connection and cancels retries.
 */
export function openReconnectingSocket(options: SocketOptions): () => void {
  let socket: WebSocket | null = null
  let retryTimer: ReturnType<typeof setTimeout> | undefined
  let delay = INITIAL_DELAY_MS
  let stopped = false

  const connect = (): void => {
    options.onStatusChange('connecting')
    socket = new WebSocket(options.url)

    socket.onopen = (): void => {
      delay = INITIAL_DELAY_MS
      options.onStatusChange('open')
    }
    socket.onmessage = (event: MessageEvent<unknown>): void => {
      if (typeof event.data === 'string') options.onMessage(event.data)
    }
    socket.onclose = (): void => {
      options.onStatusChange('closed')
      if (stopped) return
      retryTimer = setTimeout(connect, delay)
      delay = Math.min(delay * 2, MAX_DELAY_MS)
    }
  }

  connect()

  return (): void => {
    stopped = true
    clearTimeout(retryTimer)
    socket?.close()
  }
}
