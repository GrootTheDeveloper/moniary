export type FcmFailureKind = "invalid_token" | "retryable" | "permanent";

export type FcmFailure = {
  kind: FcmFailureKind;
  code: string;
};

export type FcmPayloadRow = {
  notification_id: string;
  category: string;
  type: string;
  group_id: string | null;
  metadata: Record<string, unknown>;
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

export function buildFcmData(
  row: FcmPayloadRow,
  copy: { title: string; body: string },
) {
  const metadata = row.metadata ?? {};
  const data: Record<string, string> = {
    notification_id: row.notification_id,
    category: row.category,
    type: row.type,
    channel_name: copy.title,
    channel_description: copy.body,
  };
  if (row.group_id) data.group_id = row.group_id;
  if (typeof metadata.group_transaction_id === "string") {
    data.group_transaction_id = metadata.group_transaction_id;
  }
  if (typeof metadata.friend_request_id === "string") {
    data.friend_request_id = metadata.friend_request_id;
  }
  return data;
}
