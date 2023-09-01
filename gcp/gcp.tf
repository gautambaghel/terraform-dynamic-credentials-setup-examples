# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "google" {
  project = var.project_id
  region  = "global"
}

provider "google-beta" {
  project = var.project_id
  region  = "global"
}

# Data source used to get the project number programmatically.
#
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project
data "google_project" "project" {
}

# Enables the required services in the project.
#
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_service
resource "google_project_service" "services" {
  count   = length(var.gcp_service_list)
  service = var.gcp_service_list[count.index]
}

# Get the Terraform Cloud organization
data "tfe_organization" "tfc_org" {
  name = var.tfc_organization_name
}

# Get the Terraform Cloud project
data "tfe_project" "tfc_project" {
  name         = var.tfc_project_name
  organization = data.tfe_organization.tfc_org.name
}

# Random ID for the workload_identity_pool_id
# will avoid errors due to GCP's 30-day hold on deleted pools
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "tfe_variable_set" "tfc_gcp_oidc_var_set" {
  name         = "GCP OIDC"
  description  = "GCP OIDC Variable set."
  organization = data.tfe_organization.tfc_org.name
}

resource "tfe_project_variable_set" "tfc_gcp_oidc_var_set" {
  project_id      = data.tfe_project.tfc_project.id
  variable_set_id = tfe_variable_set.tfc_gcp_oidc_var_set.id
}

resource "tfe_variable" "gcp_project_id" {
  key             = "project_id"
  value           = var.project_id
  category        = "terraform"
  description     = "The project id for the GCP project."
  variable_set_id = tfe_variable_set.tfc_gcp_oidc_var_set.id
}

# The following variables must be set to allow runs
# to authenticate to GCP.
resource "tfe_variable" "enable_gcp_provider_auth" {
  key             = "TFC_GCP_PROVIDER_AUTH"
  value           = "true"
  category        = "env"
  description     = "Enable the Workload Identity integration for GCP."
  variable_set_id = tfe_variable_set.tfc_gcp_oidc_var_set.id
}

# TFC_GCP_WORKLOAD_PROVIDER_NAME variable contains the project number,
# pool ID, and provider ID
resource "tfe_variable" "tfc_gcp_workload_provider_name" {
  key             = "TFC_GCP_WORKLOAD_PROVIDER_NAME"
  value           = module.oidc.provider_name
  category        = "env"
  description     = "The workload provider name to authenticate against."
  variable_set_id = tfe_variable_set.tfc_gcp_oidc_var_set.id
}

resource "tfe_variable" "tfc_gcp_service_account_email" {
  key             = "TFC_GCP_RUN_SERVICE_ACCOUNT_EMAIL"
  value           = google_service_account.tfc_service_account.email
  category        = "env"
  description     = "The GCP service account TFC agents will use to authenticate."
  variable_set_id = tfe_variable_set.tfc_gcp_oidc_var_set.id
}

# Creates an identity pool provider which uses an attribute condition
# to ensure that only the specified Terraform Cloud workspace will be
# able to authenticate to GCP using this provider.
#
# https://registry.terraform.io/modules/GoogleCloudPlatform/tf-cloud-agents/google/latest
# Use the OIDC module to provision the Workload identitly pool
module "oidc" {
  project_id  = var.project_id
  source      = "GoogleCloudPlatform/tf-cloud-agents/google//modules/tfc-oidc"
  pool_id     = "pool-${random_string.suffix.result}"
  provider_id = "terraform-provider-${random_string.suffix.result}"
  sa_mapping = {
    (google_service_account.tfc_service_account.account_id) = {
      sa_name   = google_service_account.tfc_service_account.name
      sa_email  = google_service_account.tfc_service_account.email
      attribute = "*"
    }
  }
  tfc_organization_name = data.tfe_organization.tfc_org.name
  tfc_project_name      = data.tfe_project.tfc_project.name
  attribute_condition   = "assertion.sub.startsWith(\"organization:${data.tfe_organization.tfc_org.name}:project:${data.tfe_project.tfc_project.name}\")"
}

# Creates a service account that will be used for authenticating to GCP.
#
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account
resource "google_service_account" "tfc_service_account" {
  account_id   = "tfc-service-account"
  display_name = "Terraform Cloud Service Account"
}

# Updates the IAM policy to grant the service account permissions
# within the project.
#
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_iam
resource "google_project_iam_member" "tfc_project_member" {
  project = var.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.tfc_service_account.email}"
}

# Give the service account necessary permissions,
# for ex. storage access - see role_list variable
resource "google_project_iam_member" "project" {
  project  = var.project_id
  for_each = toset(var.gcp_roles_list)
  role     = each.value
  member   = "serviceAccount:${google_service_account.tfc_service_account.email}"
}
