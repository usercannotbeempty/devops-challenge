include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_repo_root()}/modules//irsa-role"
}

dependency "eks" {
  config_path = "../../../platform/dev/eks"
}

dependency "documents" {
  config_path = "../claim-documents-bucket"
}

inputs = {
  name              = "claims-upload-dev"
  oidc_provider_arn = dependency.eks.outputs.oidc_provider_arn
  namespace         = "claims"
  # Assumption: confirm the actual backend service account before enabling uploads.
  service_account   = "claims-api"
  policy_statements = [
    {
      sid       = "UploadClaimDocuments"
      effect    = "Allow"
      actions   = ["s3:PutObject"]
      resources = ["${dependency.documents.outputs.bucket_arn}/claims/*"]
    },
  ]
}
