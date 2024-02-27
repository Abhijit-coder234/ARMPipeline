
output "ssh_private_key" {
  value     = tls_private_key.insecure.private_key_pem
  sensitive = true
}