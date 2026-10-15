interface MessagePayload {
  message: string
}

function isMessagePayload(value: unknown): value is MessagePayload {
  return (
    typeof value === 'object' &&
    value !== null &&
    'message' in value &&
    typeof (value as { message: unknown }).message === 'string'
  )
}

/** Extrae el texto a mostrar: campo `message` si es JSON válido, o el texto crudo. */
export function parsePayload(raw: string): string {
  try {
    const parsed: unknown = JSON.parse(raw)
    return isMessagePayload(parsed) ? parsed.message : raw
  } catch {
    return raw
  }
}
