resource "aws_iam_role" "this" {
  name = "${var.dpc_name}-role"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Effect": "Allow",
     "Principal": {
       "Federated": "${var.tfc_provider_arn}"
     },
     "Action": "sts:AssumeRoleWithWebIdentity",
     "Condition": {
       "StringEquals": {
         "${var.tfc_hostname}:aud": "${one(var.tfc_provider_client_id_list)}"
       },
       "StringLike": {
         "${var.tfc_hostname}:sub": "organization:${var.tfc_organization_name}:project:${var.tfc_project_name}:workspace:${local.workspace_name}:run_phase:*"
       }
     }
   }
 ]
}
EOF
}

resource "aws_iam_policy" "custom_policies" {

  # name     = join("-", [each.key, "policy"])
  for_each = var.custom_policies
  name     = each.key
  policy   = each.value
}

output "policy" {
  value = var.custom_policies
}

resource "aws_iam_role_policy_attachment" "custom_polices" {

  depends_on = [aws_iam_role_policy_attachment.managed_policies]

  for_each   = aws_iam_policy.custom_policies
  role       = aws_iam_role.this.name
  policy_arn = each.value.arn
}

resource "aws_iam_role_policy_attachment" "managed_policies" {

  for_each   = data.aws_iam_policy.managed_policies
  role       = aws_iam_role.this.name
  policy_arn = each.value.arn
}