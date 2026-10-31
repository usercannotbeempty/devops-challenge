include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_repo_root()}/modules//claim-documents"
}

locals {
  account = read_terragrunt_config(find_in_parent_folders("account.hcl"))
}

inputs = {
  name = "acme-${local.account.locals.aws_account_id}-claim-documents-prod"
  tags = {
    DataClassification = "restricted"
    Owner              = "claims"
  }
}
