# 03 — Feature request

## Implemented infrastructure

Added `modules/claim-documents` and dev/prod Terragrunt stacks under the existing claims hierarchy. Buckets have public access blocked, ACLs disabled, TLS-only access, SSE-S3 encryption and versioning. Forced deletion of a nonempty bucket is disabled. A dedicated module keeps these sensitive-document defaults separate from the legacy reports bucket.

The worker receives only `s3:GetObject` for its environment's `claims/*` prefix. A separate upload IRSA role grants only `s3:PutObject` to that prefix. No permanent IAM user/access keys are created. SSE-S3 supplies encryption without adding key management requirements that were not requested; customer-managed keys can be considered if policy requires them.

**Assumptions and remaining inputs:** the backend runs as `claims/claims-api`; confirm that identity and annotate its service account with the corresponding upload role ARN before use. The backend/chart is not included here. It must verify claim ownership before issuing short-lived presigned upload URLs. Laptop scripts should use that authenticated flow or a scoped dev SSO role. Confirm file sizes/types, volume and any browser-origin requirements.

No automatic expiry is configured because “as long as needed” does not define a safe deletion rule. Product must agree retention, legal holds and deletion of old versions before real production ingestion. This is an open decision, not approval for indefinite retention.

**Rollout:** apply the dev bucket, then its worker/upload IAM stacks; test synthetic upload → OCR, denied public access, prohibited role actions and cross-environment isolation. Repeat a reviewed plan for prod after the retention decision. Rollback disables new uploads while preserving documents. Infrastructure has not been deployed.

**Validation:** Terraform validate and the bucket mock test pass. IAM boundary tests verify separate upload/read permissions and environment-specific dependencies. Effective permissions must still be tested in dev.

## Reply to Rina

Hi Rina — I have prepared Terraform for separate private, encrypted dev/prod document buckets and scoped read access for claims-worker.

I used temporary IAM roles instead of permanent access keys. Your backend can issue short-lived upload URLs after checking claim ownership; laptop scripts can use the same authenticated flow or dev SSO access.

Please confirm the backend service account, expected file sizes/types and volume. Product also needs to define retention, legal holds and deletion requirements. We can test synthetic documents in dev this week after deployment and backend wiring, then enable production after those requirements and access checks are complete.
