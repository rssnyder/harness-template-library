# ---------------------------------------------------------------------------
# No test table? Create one and seed it with the AWS CLI:
#
#   aws dynamodb create-table \
#     --table-name harness-aws-accounts \
#     --attribute-definitions AttributeName=AccountId,AttributeType=S \
#     --key-schema AttributeName=AccountId,KeyType=HASH \
#     --billing-mode PAY_PER_REQUEST
#
#   aws dynamodb put-item --table-name harness-aws-accounts \
#     --item '{"AccountId": {"S": "111111111111"}, "Name": {"S": "sandbox-payments"}}'
#   aws dynamodb put-item --table-name harness-aws-accounts \
#     --item '{"AccountId": {"S": "222222222222"}, "Name": {"S": "sandbox-billing"}}'
#   aws dynamodb put-item --table-name harness-aws-accounts \
#     --item '{"AccountId": {"S": "333333333333"}, "Name": {"S": "prod-payments"}}'
#
# Set aws_accounts_table_name = "harness-aws-accounts" and
# account_name_search = "sandbox" in your tfvars to test (matches the two
# sandbox-* rows above).
# ---------------------------------------------------------------------------

# The hashicorp/aws provider has no data source that scans/queries multiple
# DynamoDB items (aws_dynamodb_table_item only does a keyed GetItem), so we
# shell out to the AWS CLI via the external provider and hand back a single
# comma-joined string, which is the flat string map the external provider
# requires. The Name filter is applied server-side via DynamoDB's
# FilterExpression so we never pull rows we don't need.
#
# ponytail: single Scan call, no pagination handling. Fine for a small
# lookup table; if it ever exceeds one Scan page (~1MB / 1000s of items),
# switch to a paging loop (e.g. `aws dynamodb scan --starting-token`) or a
# GSI-backed Query.
data "external" "aws_accounts" {
  program = ["bash", "-c", <<-EOT
    set -euo pipefail
    ids=$(aws dynamodb scan \
      --table-name "${var.aws_accounts_table_name}" \
      --projection-expression "AccountId" \
      --filter-expression "contains(#n, :search)" \
      --expression-attribute-names '{"#n":"Name"}' \
      --expression-attribute-values '{":search": {"S": "${var.account_name_search}"}}' \
      --region "${var.aws_region}" \
      --output json | jq -r '[.Items[].AccountId.S] | join(",")')
    jq -n --arg ids "$ids" '{account_ids: $ids}'
  EOT
  ]
}

locals {
  aws_account_ids = compact(split(",", data.external.aws_accounts.result.account_ids))
}

resource "harness_platform_connector_aws" "oidc" {
  for_each = toset(local.aws_account_ids)

  identifier = "oidc_${each.value}"
  name       = "oidc_${each.value}"

  oidc_authentication {
    iam_role_arn       = "arn:aws:iam::${each.value}:role/${var.oidc_role_name}"
    region             = var.aws_region
    delegate_selectors = []
  }
}
