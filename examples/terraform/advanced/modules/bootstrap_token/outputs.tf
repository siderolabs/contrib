output "bootstrap_token" {
  value = "${random_string.token_prefix.result}.${random_string.token_suffix.result}"
}
