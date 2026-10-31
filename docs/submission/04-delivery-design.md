# 04 — Deployment and access design

I would keep GitHub Actions, Terragrunt and Helmfile, and move execution into controlled CI jobs. A new platform or GitOps tool is not necessary for the first step.

**Infrastructure:** A pull request runs formatting, validation, security checks and relevant tests. In a trusted CI context, generate a plan for the affected stacks and dependencies. After review and an independent production approval, apply that exact saved plan from the approved commit. Serialize changes per state; regenerate and reapprove stale plans rather than silently replanning during apply.

**Applications:** Render and validate Helm manifests, deploy an immutable image digest to dev, and verify functionality. Review the production diff, approve it, then deploy only affected releases. Verify business processing as well as rollout health. Record a known-good artifact and Helm revision for rollback.

**Access:** Humans use SSO with MFA and short-lived permissions. CI uses GitHub OIDC with separate, scoped roles per environment. Production roles are restricted to the intended repository and protected deployment context. Replace the hardcoded local AWS profile dependency with a CI-compatible credential path. Keep a logged emergency-access procedure.

**Auditability:** Protect the production branch and require an approver other than the author. Retain the PR, commit, plan/diff, approver, workflow run and deployment result. Correlate these with CloudTrail and EKS audit logs; protect the logs and agree their retention with the audit owner. Verify that repository settings can actually enforce the chosen approval controls.

**Rollout:** Start with required checks and one dev stack/service. Rehearse deployment and rollback, introduce gated production deployment, then expand coverage and remove routine laptop write access.

I would defer ArgoCD, a custom platform and account restructuring until basic deployment controls work reliably. The unfinished `apply.yml` should remain unused until replaced with a reviewed, scoped workflow.
