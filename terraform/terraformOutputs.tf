output "oracle_dns" {
  value = ["${aws_instance.ec2_tomcatDockerEC2_oracle.*.public_dns}"]
}

output "oracle_ip" {
  value = ["${aws_instance.ec2_tomcatDockerEC2_oracle.*.public_ip}"]
}

output "tomcat_dns" {
  value = ["${aws_instance.ec2_tomcatDockerEC2_tomcat.*.public_dns}"]
}

output "tomcat_ip" {
  value = ["${aws_instance.ec2_tomcatDockerEC2_tomcat.*.public_ip}"]
}