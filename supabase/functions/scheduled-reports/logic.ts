const encoder = new TextEncoder();

export function constantTimeEqual(received: string | null, expected: string) {
  if (received == null) return false;
  const receivedBytes = encoder.encode(received);
  const expectedBytes = encoder.encode(expected);
  if (receivedBytes.length !== expectedBytes.length) return false;

  let difference = 0;
  for (let index = 0; index < expectedBytes.length; index++) {
    difference |= receivedBytes[index] ^ expectedBytes[index];
  }
  return difference === 0;
}

export function escapeHtml(value: string) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

export function isValidSender(value: string) {
  if (value.includes("\r") || value.includes("\n") || value.length > 320) {
    return false;
  }
  const mailbox = "[^<>\\s@]+@[^<>\\s@]+\\.[^<>\\s@]+";
  return new RegExp(`^${mailbox}$`).test(value) ||
    new RegExp(`^[^<>]+\\s+<${mailbox}>$`).test(value);
}

export function classifyResendFailure(status: number, name: unknown) {
  if (
    status === 408 ||
    status === 429 ||
    status >= 500 ||
    (status === 409 && name === "concurrent_idempotent_requests")
  ) {
    return "retry" as const;
  }
  return "failed" as const;
}

export async function runWithConcurrency<T>(
  values: readonly T[],
  concurrency: number,
  worker: (value: T) => Promise<void>,
) {
  const workerCount = Math.max(
    1,
    Math.min(Math.trunc(concurrency), values.length),
  );
  let nextIndex = 0;

  await Promise.all(
    Array.from({ length: workerCount }, async () => {
      while (nextIndex < values.length) {
        const value = values[nextIndex++];
        await worker(value);
      }
    }),
  );
}
