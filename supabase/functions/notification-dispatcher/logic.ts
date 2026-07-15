export type FcmFailureKind = "invalid_token" | "retryable" | "permanent";

export type FcmFailure = {
  kind: FcmFailureKind;
  code: string;
};

type FcmErrorPayload = {
  error?: {
    status?: unknown;
    details?: Array<Record<string, unknown>>;
  };
};

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

export function classifyFcmFailure(
  status: number,
  payload: unknown,
): FcmFailure {
  const body = payload as FcmErrorPayload | null;
  const details = Array.isArray(body?.error?.details) ? body.error.details : [];
  const fcmDetail = details.find((detail) =>
    typeof detail["@type"] === "string" &&
    detail["@type"].includes("google.firebase.fcm.v1.FcmError")
  );
  const fcmCode = typeof fcmDetail?.errorCode === "string"
    ? fcmDetail.errorCode
    : null;
  const statusCode = typeof body?.error?.status === "string"
    ? body.error.status
    : null;
  const code = fcmCode ?? statusCode ?? `HTTP_${status}`;

  if (fcmCode === "UNREGISTERED") {
    return { kind: "invalid_token", code };
  }
  if (status === 408 || status === 429 || status >= 500) {
    return { kind: "retryable", code };
  }
  return { kind: "permanent", code };
}
