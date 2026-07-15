import {
  buildFcmData,
  classifyFcmFailure,
  constantTimeEqual,
} from "./logic.ts";

Deno.test("scheduler secret comparison requires an exact value", () => {
  if (!constantTimeEqual("a".repeat(64), "a".repeat(64))) {
    throw new Error("matching secrets were rejected");
  }
  if (constantTimeEqual("a".repeat(64), "b".repeat(64))) {
    throw new Error("different secrets were accepted");
  }
  if (constantTimeEqual(null, "a".repeat(64))) {
    throw new Error("missing secret was accepted");
  }
});

Deno.test("only the FCM UNREGISTERED code invalidates a device token", () => {
  const unregistered = classifyFcmFailure(404, {
    error: {
      status: "NOT_FOUND",
      details: [{
        "@type": "type.googleapis.com/google.firebase.fcm.v1.FcmError",
        errorCode: "UNREGISTERED",
      }],
    },
  });
  const badPayload = classifyFcmFailure(400, {
    error: { status: "INVALID_ARGUMENT" },
  });

  if (unregistered.kind !== "invalid_token") {
    throw new Error("unregistered token was not invalidated");
  }
  if (badPayload.kind !== "permanent") {
    throw new Error("generic HTTP 400 incorrectly invalidated a token");
  }
});

Deno.test("transient FCM responses remain retryable", () => {
  for (const status of [408, 429, 500, 503]) {
    if (classifyFcmFailure(status, null).kind !== "retryable") {
      throw new Error(`HTTP ${status} was not retryable`);
    }
  }
});

Deno.test("push payload uses the source notification identity", () => {
  const data = buildFcmData(
    {
      notification_id: "notification-id",
      category: "group",
      type: "transaction_posted",
      group_id: "group-id",
      metadata: { group_transaction_id: "transaction-id" },
    },
    { title: "Group", body: "New update" },
  );

  if (data.notification_id !== "notification-id") {
    throw new Error("outbox identity leaked into the notification payload");
  }
  if (
    data.group_id !== "group-id" ||
    data.group_transaction_id !== "transaction-id"
  ) {
    throw new Error("notification target metadata was not preserved");
  }
});
