import { useEffect, useRef } from 'react'
import type { RefObject } from 'react'

/** Desplaza el contenedor al final cada vez que cambia `dependency`. */
export function useAutoScroll(dependency: unknown): RefObject<HTMLDivElement | null> {
  const ref = useRef<HTMLDivElement | null>(null)

  useEffect(() => {
    const element = ref.current
    if (element) element.scrollTop = element.scrollHeight
  }, [dependency])

  return ref
}
