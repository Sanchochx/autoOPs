import { useEffect, useRef } from 'react'
import type { RefObject } from 'react'

/** Scrolls the container to the bottom whenever `dependency` changes. */
export function useAutoScroll(dependency: unknown): RefObject<HTMLDivElement | null> {
  const ref = useRef<HTMLDivElement | null>(null)

  useEffect(() => {
    const element = ref.current
    if (element) element.scrollTop = element.scrollHeight
  }, [dependency])

  return ref
}
