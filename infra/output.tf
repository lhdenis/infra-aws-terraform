output "cluster_endpoint" {
  description = "Endpoint API du cluster"
  value       = aws_eks_cluster.cluster.endpoint
}

output "kubeconfig_command" {
  description = "Commande pour configurer kubectl"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${var.cluster_name}"
}
