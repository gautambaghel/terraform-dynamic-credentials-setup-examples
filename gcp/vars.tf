# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "tfc_gcp_audience" {
  type        = string
  default     = ""
  description = "The audience value to use in run identity tokens if the default audience value is not desired."
}

variable "tfc_hostname" {
  type        = string
  default     = "app.terraform.io"
  description = "The hostname of the TFC or TFE instance you'd like to use with GCP"
}

variable "tfc_organization_name" {
  type        = string
  description = "The name of your Terraform Cloud organization"
}

variable "tfc_project_name" {
  type        = string
  default     = "GCP"
  description = "The project under which a workspace will be created"
}

variable "project_id" {
  type        = string
  description = "The ID for your GCP project"
}

variable "gcp_service_list" {
  description = "APIs required for the project"
  type        = list(string)
  default = [
    "apigee.googleapis.com",
    "artifactregistry.googleapis.com",
    "autoscaling.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "containerfilesystem.googleapis.com",
    "containerregistry.googleapis.com",
    "deploymentmanager.googleapis.com",
    "dns.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "networkconnectivity.googleapis.com",
    "sts.googleapis.com",
    "serviceusage.googleapis.com",
    "storage-api.googleapis.com",
    "storage-component.googleapis.com",
    "storage.googleapis.com",
    "sts.googleapis.com",
    "vpcaccess.googleapis.com"
  ]
}

variable "gcp_roles_list" {
  description = "Roles required for the Service Account"
  type        = list(string)
  default = [
    "roles/apigee.admin",
    "roles/apigee.apiAdminV2",
    "roles/appengine.appAdmin",
    "roles/clouddeploy.admin",
    "roles/cloudfunctions.admin",
    "roles/cloudkms.admin",
    "roles/compute.admin",
    "roles/compute.instanceAdmin",
    "roles/compute.instanceAdmin.v1",
    "roles/compute.storageAdmin",
    "roles/config.admin",
    "roles/container.admin",
    "roles/container.clusterAdmin",
    "roles/dns.admin",
    "roles/gkemulticloud.admin",
    "roles/iam.roleAdmin",
    "roles/iam.securityAdmin",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountKeyAdmin",
    "roles/iam.serviceAccountTokenCreator",
    "roles/resourcemanager.projectIamAdmin",
    "roles/run.admin",
    "roles/secretmanager.admin",
    "roles/servicenetworking.networksAdmin",
    "roles/source.admin",
    "roles/storage.admin",
    "roles/storage.objectAdmin",
    "roles/vpcaccess.admin"
  ]
}
