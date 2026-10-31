# 02 — Incident

## Root cause and impact

The production service account was renamed to `claims-worker-sa`, but IAM still trusts `system:serviceaccount:claims:claims-worker`. The worker therefore receives `AccessDenied` for `sts:AssumeRoleWithWebIdentity` and exits before consuming SQS messages.

The evidence shows 30 unhealthy worker pods, approximately 48,213 queued messages and more than 40 customer complaints. Earlier database slowness is not the primary cause: it had subsided, and the worker connects to the database before failing on AWS authentication. KEDA can still scale because it uses a separate operator identity.

## Recovery

Freeze worker deployments, verify the production AWS account, and capture the current Helm revision/values and image digest for recovery. The code fix restores `serviceAccount.name: claims-worker`.

Run the following from the repository root in Bash. These are proposed recovery commands; they have not been run against AWS.

```bash
export KUBE_CONTEXT=arn:aws:eks:ap-southeast-3:111111111111:cluster/acme-prod
helm --kube-context "$KUBE_CONTEXT" -n claims history claims-worker
kubectl --context "$KUBE_CONTEXT" -n claims get pods -o wide
# Record and verify the deployed worker image digest; do not invent one from latest.
read -r -p 'Verified digest (sha256:...): ' WORKER_DIGEST
[[ "$WORKER_DIGEST" =~ ^sha256:[a-f0-9]{64}$ ]] || exit 1
kubectl --context "$KUBE_CONTEXT" -n claims patch scaledobject claims-worker \
  --type merge -p '{"spec":{"maxReplicaCount":2}}'
# Wait for HPA max=2 and excess pods to terminate before restoring consumption.
kubectl --context "$KUBE_CONTEXT" -n claims get hpa,pods
helm --kube-context "$KUBE_CONTEXT" diff upgrade claims-worker charts/service \
  -n claims -f apps/acme-prod-cluster/values/claims-worker.yaml \
  --set autoscaling.maxReplicas=2 --set-string "image.tag=latest@$WORKER_DIGEST"
helm --kube-context "$KUBE_CONTEXT" upgrade claims-worker charts/service \
  -n claims -f apps/acme-prod-cluster/values/claims-worker.yaml \
  --set autoscaling.maxReplicas=2 --set-string "image.tag=latest@$WORKER_DIGEST" \
  --wait --timeout 10m
kubectl --context "$KUBE_CONTEXT" -n claims rollout status deployment/claims-worker
kubectl --context "$KUBE_CONTEXT" -n claims logs deployment/claims-worker --since=10m
aws sqs get-queue-attributes --region ap-southeast-3 \
  --queue-url https://sqs.ap-southeast-3.amazonaws.com/111111111111/claims-documents \
  --attribute-names All
```

The diff command needs the helm-diff plugin used by Helmfile. The existing chart accepts the valid `repository:tag@digest` image reference without changing chart code. Record temporary overrides in the deployment handover before the next normal apply. If the artifact is unhealthy, repeat the upgrade with a verified healthy digest; keep the corrected identity and low cap. If processing threatens data integrity or DB availability, set `autoscaling.enabled=false,replicas=0` in that upgrade until safe to resume; do not purge SQS.

Verify no STS errors, actual OCR completion, declining queue depth/oldest-message age, and stable database load before increasing capacity. Ready pods alone do not prove recovery.

## Postmortem

On 13 October, the rename was applied around 17:40 WIB. The queue alarm entered ALARM at 18:12, but `AlarmActions` was empty. Customer support reported complaints at 01:38 the next day; the platform engineer was contacted at 02:10. No confirmed recovery time is present in the evidence.

The failure was caused by an identity change without validation across Helm and IAM. Missing notification routing and insufficient post-deployment checks prolonged detection. This is a control gap, not an individual-blame issue.

## Prevention

**Implemented prevention:** CI renders dev/prod worker manifests and compares their namespace, service-account identity and role ARN with Terragrunt IAM inputs. A repeat of the rename fails the check before deployment. Make this existing CI job required in branch protection; the test cannot protect bypassed/manual deployments.

I own the remaining follow-ups: tonight, connect the existing alarm to a confirmed on-call destination and test receipt; this week, require functional rollout checks and add worker-health/DLQ monitoring. Alert routing remains an operational follow-up, not a completed fix. No restoration time or successful delivery is claimed.

**Validation:** identity tests pass for dev/prod; an isolated copy with the original rename fails as expected. Helm lint passes. Live IAM and OCR behavior remain to be verified during rollout.
