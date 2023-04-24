resource "random_string" "token_prefix" {
  length  = 6
  special = false
  upper   = false
}

resource "random_string" "token_suffix" {
  length  = 16
  special = false
  upper   = false
}
