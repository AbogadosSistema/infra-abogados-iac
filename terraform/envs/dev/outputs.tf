output "jenkins_public_ip" {
  description = "IP pública de la instancia Jenkins (dev)"
  value       = module.jenkins_ec2.jenkins_public_ip
}

output "jenkins_public_dns" {
  description = "DNS público de la instancia Jenkins (dev)"
  value       = module.jenkins_ec2.jenkins_public_dns
}

output "jenkins_url" {
  description = "URL de Jenkins (dev)"
  value       = module.jenkins_ec2.jenkins_url
}

output "jenkins_elastic_ip" {
  description = "Elastic IP fija asociada a Jenkins"
  value       = module.jenkins_ec2.jenkins_elastic_ip
}