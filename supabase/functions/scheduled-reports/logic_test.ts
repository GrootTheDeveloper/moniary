import {
  classifyResendFailure,
  constantTimeEqual,
  escapeHtml,
  isValidSender,
  runWithConcurrency,
} from "./logic.ts";

Deno.test("scheduler secret requires an exact value", () => {
  if (!constantTimeEqual("a".repeat(64), "a".repeat(64))) {
    throw new Error("matching secrets were rejected");
  }
  if (constantTimeEqual("a".repeat(64), "b".repeat(64))) {
    throw new Error("different secrets were accepted");
  }
});

Deno.test("email content escapes user-controlled HTML", () => {
  const escaped = escapeHtml('<script>"x" & y</script>');
  if (escaped.includes("<script>") || !escaped.includes("&lt;script&gt;")) {
    throw new Error("HTML content was not escaped");
  }
});

Deno.test("sender validation blocks header injection", () => {
  if (!isValidSender("Moniary <noreply@example.com>")) {
    throw new Error("valid sender was rejected");
  }
  if (isValidSender("noreply@example.com\nBcc: victim@example.com")) {
    throw new Error("header injection was accepted");
  }
});

Deno.test("only transient Resend responses retry", () => {
  if (classifyResendFailure(429, null) !== "retry") {
    throw new Error("rate limit was not retryable");
  }
  if (
    classifyResendFailure(409, "concurrent_idempotent_requests") !== "retry"
  ) {
    throw new Error("concurrent idempotency request was not retryable");
  }
  if (classifyResendFailure(422, "invalid_from_address") !== "failed") {
    throw new Error("permanent sender error was retried");
  }
});

Deno.test("bounded workers process every delivery exactly once", async () => {
  const active = new Set<number>();
  const processed: number[] = [];
  let maxActive = 0;

  await runWithConcurrency([1, 2, 3, 4, 5, 6], 2, async (value) => {
    active.add(value);
    maxActive = Math.max(maxActive, active.size);
    await new Promise((resolve) => setTimeout(resolve, 1));
    processed.push(value);
    active.delete(value);
  });

  if (maxActive > 2) throw new Error("worker concurrency was not bounded");
  if (processed.toSorted().join(",") !== "1,2,3,4,5,6") {
    throw new Error("a delivery was skipped or processed twice");
  }
});
