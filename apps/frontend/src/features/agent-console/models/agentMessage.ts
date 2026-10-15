export interface AgentMessage {
  id: string
  text: string
  receivedAt: number
}

export type ConnectionStatus = 'connecting' | 'open' | 'closed'
