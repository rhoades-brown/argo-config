terraform {
  source = "${get_repo_root()}/test/modules"
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("vars.hcl"))
}

inputs = merge(
  local.common_vars.inputs,
  {
    # additional inputs
  }
)