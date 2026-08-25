# Harness Account Setup
variable "harness_platform_url" {
  type        = string
  description = "[Optional] Enter the Harness Platform URL.  Defaults to Harness SaaS URL"
  default     = "https://app.harness.io/gateway"
}

variable "harness_platform_account" {
  type        = string
  description = "[Required] Enter the Harness Platform Account Number"
}

variable "organization_id" {
  type        = string
  description = "[Required] Provide an organization reference ID.  Must exist before execution"
}

variable "project_id" {
  type        = string
  description = "[Optional] New Project Identifier. If not provided, then the project_name will be formatted to replace spaces and dashes with underscores"
  default     = null
}

variable "project_name" {
  type        = string
  description = "[Required] New Project Name"
}

variable "project_description" {
  type        = string
  description = "[Optional] New Project Description"
  default     = "Harness Project managed by Solutions Factory"
}

variable "tags" {
  type        = map(any)
  description = "[Optional] Provide a Map of Tags to associate with the resources"
  default     = {}
}

# AWS Account Source Table
variable "aws_region" {
  type        = string
  description = "[Optional] AWS region for the provider and DynamoDB lookup"
  default     = "us-east-1"
}

variable "aws_accounts_table_name" {
  type        = string
  description = "[Required] DynamoDB table name containing the list of AWS account IDs to connect. See aws_connectors.tf for a test table you can create with the AWS CLI"
  default     = "harness-aws-accounts"
}

variable "oidc_role_name" {
  type        = string
  description = "[Optional] IAM role name (must already exist in each target account) that the OIDC connector assumes"
  default     = "harness-oidc-role"
}
