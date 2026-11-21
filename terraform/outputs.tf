output "infrastructure_inventory" {
  description = "Generated local infrastructure inventory"
  value       = local_file.infrastructure_inventory.filename
}
