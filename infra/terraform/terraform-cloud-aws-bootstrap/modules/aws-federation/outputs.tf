output "aws_oidc_provider_tfc" {
  value = aws_iam_openid_connect_provider.tfc_provider.arn
}

output "aws_oidc_client_id_list_tfc" {
  value = aws_iam_openid_connect_provider.tfc_provider.client_id_list
}