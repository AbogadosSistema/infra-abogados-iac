# terraform/modules/jenkins-ec2/outputs.tf
output "jenkins_elastic_ip" {
  description = "Elastic IP fija de Jenkins"
  value       = aws_eip.jenkins_eip.public_ip
}

output "jenkins_public_ip" {
  description = "IP pública de la instancia Jenkins (debería coincidir con la Elastic IP)"
  value       = aws_eip.jenkins_eip.public_ip
}

output "jenkins_public_dns" {
  description = "DNS público de la instancia Jenkins"
  value       = aws_instance.jenkins.public_dns
}

output "jenkins_url" {
  description = "URL de Jenkins"
  value       = "http://${aws_eip.jenkins_eip.public_ip}:8080"
}
