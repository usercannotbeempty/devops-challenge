include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_repo_root()}/modules//irsa-role"
}

dependency "eks" {
  config_path = "../../../platform/prod/eks"

  mock_outputs = {
    oidc_provider_arn = "arn:aws:iam::111111111111:oidc-provider/oidc.eks.ap-southeast-3.amazonaws.com/id/MOCK"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "queue" {
  config_path = "../claims-documents-queue"
}

dependency "documents" {
  config_path = "../claim-documents-bucket"
}

inputs = {
  name              = "claims-worker-prod"
  oidc_provider_arn = dependency.eks.outputs.oidc_provider_arn
  namespace         = "claims"
  service_account   = "claims-worker"

  policy_statements = [
    {
      sid       = "ReadClaimDocuments"
      effect    = "Allow"
      actions   = ["s3:GetObject"]
      resources = ["${dependency.documents.outputs.bucket_arn}/claims/*"]
    },
    {
      sid       = "Queue"
      effect    = "Allow"
      actions   = ["sqs:*"]
      resources = ["*"]
    },
  ]
}
