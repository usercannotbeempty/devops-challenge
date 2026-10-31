# 01 — Take over the platform

My first priority is to restore claims processing and make failures visible. I would verify deployed resources against the repository rather than assume the inherited documentation is accurate.

| Priority | Risk and business impact | Action | Estimated effort |
|---|---|---|---|
| P0 | Worker identity mismatch stops document processing. | Restore the service account expected by IAM and verify OCR completion. | 1–2 hours, plus backlog monitoring |
| P0 | Queue alarms have no notification destination. | Connect a monitored on-call destination and test delivery. | 1–2 hours |
| P1 | GuardDuty assumes every finding has EC2 details; IAM/S3 findings can fail. Slack HTTP errors are ignored. | Fix non-EC2 formatting and add fixture tests now; schedule delivery-error handling next. | Half a day |
| P1 | Broad IAM permissions, static credentials and plaintext secrets increase exposure of customer data. | Inventory consumers, introduce temporary roles and managed secrets, then rotate credentials and narrow permissions. | 2–3 days |
| P1 | Laptop deployments and mutable image tags make changes difficult to audit or roll back. | Introduce reviewed deployments and immutable image references. | 3–5 days, phased |
| P1 | Backup coverage is unverified; legacy S3 defaults allow destructive changes. | Verify database restores and strengthen storage protection before storing sensitive documents. | 2–3 days |

**Implemented:** the GuardDuty formatter now handles EC2, IAM, S3 and unknown resources without assuming an EC2 instance. This directly addresses the reported missing findings. The worker identity fix and CI prevention are covered in task 02. Other risks remain follow-ups.

**Safe rollout:** test the three supplied findings against a test Lambda/Slack destination, then review and apply only the GuardDuty stack. Confirm receipt and monitor errors; keep the previous Lambda artifact for rollback. If rolled back, manually review non-EC2 findings until the fix is restored. No message has been sent and no AWS deployment performed.

**First 90 days:** Days 1–30 focus on incident recovery, tested alerts, access inventory, backup verification and deployment controls. Days 31–60 focus on secret migration, least privilege, drift detection and restore drills. Days 61–90 focus on capacity, upgrade planning, resilience and operational handover. I would prioritize this work against customer impact and the capacity of one platform engineer.

**Validation:** five GuardDuty tests pass, including the supplied IAM/S3 fixtures and an unknown resource. Slack delivery has not been tested against a real endpoint.
