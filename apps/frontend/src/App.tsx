import { AgentConsole, useWebSocket } from './features/agent-console'
import { DashboardLayout } from './layouts/DashboardLayout'

export default function App(): React.JSX.Element {
  const status = useWebSocket()

  return (
    <DashboardLayout>
      <AgentConsole status={status} />
    </DashboardLayout>
  )
}
