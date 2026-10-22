import { create } from 'zustand'
import type { AgentMessage } from '../models/agentMessage'

/** In-memory message cap so stream rendering does not degrade. */
export const MAX_LOGS = 500

interface AiStoreState {
  logs: AgentMessage[]
  addLog: (text: string) => void
  clearLogs: () => void
}

let nextId = 0

export const useAiStore = create<AiStoreState>((set) => ({
  logs: [],
  addLog: (text: string): void =>
    set((state) => ({
      logs: [
        ...state.logs.slice(-(MAX_LOGS - 1)),
        { id: `msg-${nextId++}`, text, receivedAt: Date.now() },
      ],
    })),
  clearLogs: (): void => set({ logs: [] }),
}))
