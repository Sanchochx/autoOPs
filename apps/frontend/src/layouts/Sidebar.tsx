import { Activity, LayoutDashboard } from 'lucide-react'

export function Sidebar(): React.JSX.Element {
  return (
    <nav aria-label="Navegación principal" className="bg-slate-900 p-4 text-slate-100">
      <p className="mb-4 flex items-center gap-2 text-lg font-semibold">
        <Activity aria-hidden="true" className="size-5 text-sky-400" />
        AutoOps
      </p>
      <ul>
        <li>
          <a
            href="#dashboard"
            aria-current="page"
            className="flex items-center gap-2 rounded px-2 py-1.5 text-sm bg-slate-800 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-sky-400"
          >
            <LayoutDashboard aria-hidden="true" className="size-4" />
            Dashboard
          </a>
        </li>
      </ul>
    </nav>
  )
}
