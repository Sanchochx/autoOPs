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

/** Extracts the text to display: the `message` field if valid JSON, or the raw text. */
export function parsePayload(raw: string): string {
  try {
    const parsed: unknown = JSON.parse(raw)
    return isMessagePayload(parsed) ? parsed.message : raw
  } catch {
    return raw
  }
}
