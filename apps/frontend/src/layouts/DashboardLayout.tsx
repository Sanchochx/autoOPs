import type { ReactNode } from 'react'
import { Sidebar } from './Sidebar'

interface DashboardLayoutProps {
  children: ReactNode
}

export function DashboardLayout({ children }: DashboardLayoutProps): React.JSX.Element {
  return (
    <div className="grid min-h-screen grid-rows-[auto_1fr] bg-slate-100 md:grid-cols-[14rem_1fr] md:grid-rows-1">
      <Sidebar />
      <main id="dashboard" className="p-4 md:p-6">
        {children}
      </main>
    </div>
  )
}
