# Azure Deployment Plan

Status: Awaiting User Approval

## 1. Scope

Update the existing Moniary OCR service in place. Keep the current resource
group, Container Apps environment, Container App name, and public URL. Do not
create a parallel OCR service or a second managed environment.

Deployment mode: MODIFY / in-place revision update.

Confirmed Azure context (pending explicit user approval):

- Subscription: Azure for Students
  (`690331b3-df7b-4e15-a9ae-42366bc72103`)
- Region: `southeastasia`
- Resource group: `rg-moniary-ocr`
- Managed environment: `cae-moniary-ocr-eo5b67`
- Container App: `ca-moniary-ocr-ocr-eo5b67`
- Existing URL:
  `https://ca-moniary-ocr-ocr-eo5b67.happydesert-5a5977c3.southeastasia.azurecontainerapps.io`

## 2. Application Components

The deployable service is `backend/ocr`, a Python 3.13 FastAPI container with
Tesseract OCR. The updated pipeline performs deterministic receipt extraction,
then optionally enriches semantic fields with Gemini structured output while
falling back to deterministic extraction on provider errors.

The Flutter application is not deployed by this plan. It continues to call the
same OCR API URL and now sends the signed-in Supabase bearer token.

Runtime requirements:

- Public HTTPS ingress on port 8000; insecure HTTP disabled.
- `GET /health` remains publicly available.
- `POST /extract` requires a valid Supabase bearer token.
- 1 vCPU, 2 GiB memory, 1-3 replicas.
- Team/shared development workload, cost-optimized within the existing
  Container Apps resources.

## 3. Azure Architecture

Existing resources are updated through the repository Bicep modules:

- Azure Container Registry (Basic) for the OCR image.
- Azure Container Apps managed environment.
- Single-revision Container App with system-assigned managed identity.
- Log Analytics and Application Insights.
- Deterministic AcrPull role assignment for the Container App identity.

The current app is running revision `ca-moniary-ocr-ocr-eo5b67--fix2` with
image `crmoniaryocreo5b67.azurecr.io/moniary-ocr:20260714-fix2`. Deployment will
create a new healthy revision and route traffic to it in single-revision mode.

Quota and policy checks:

- Microsoft.App Managed Environment quota: limit 1, usage 1.
- Additional managed environments required: 0; deployment reuses the existing
  environment, so no quota increase is required.
- Subscription policy allows `southeastasia` (along with the other configured
  allowed regions).

## 4. Deployment Recipe

Use the repository's Azure Developer CLI recipe:

1. Select/import the existing environment name `moniary-ocr` with subscription
   and location above.
2. Load only required deployment secrets into the azd environment without
   displaying values.
3. Validate Bicep and deployment prerequisites.
4. Run incremental infrastructure provisioning so existing resources are
   updated rather than recreated.
5. Confirm the Container App identity has AcrPull on the existing registry.
6. Build and deploy service `ocr` using the remote container build configured
   in `azure.yaml`.
7. Verify the new revision before considering the deployment complete.

## 5. Security and Configuration

Required secret/configuration inputs:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY` (Container App secret reference)
- `GEMINI_API_KEY` (Container App secret reference)
- `GEMINI_MODEL` defaults to `gemini-2.5-flash`
- Optional `GEMINI_BLOCKED_KEY_SHA256`

Security controls:

- No Supabase service-role key is deployed.
- Gemini and Supabase keys are secure Bicep parameters and Container App
  secrets; values must not appear in logs or the deployment plan.
- Production debug output is disabled.
- Per-user request throttling and bounded OCR concurrency remain enabled.
- Gemini receives cleaned OCR text/candidates, not the original receipt image.

## 6. Execution and Verification

Post-deployment checks:

1. Provisioning state and new revision are healthy/running.
2. `GET /health` returns HTTP 200 and reports LLM configuration metadata
   without exposing secrets.
3. `POST /extract` without `Authorization` returns HTTP 401.
4. An authenticated receipt scan returns meaningful merchant/date/total/
   category fields and extraction metadata; deterministic fallback remains
   functional if Gemini is unavailable.
5. Container logs contain no secret values and no startup errors.
6. Existing public FQDN is unchanged.

## 7. Validation Proof

Not yet validated. This section may only be populated by `azure-validate`
after the user approves the Azure context and deployment plan.
